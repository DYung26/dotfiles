#Requires -RunAsAdministrator
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

if ($env:OS -ne 'Windows_NT') {
    throw 'Run this script in elevated PowerShell on Windows.'
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]::new($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run PowerShell as the target Windows account with Administrator privileges; do not switch to a different administrator account.'
}

$publicKeyPath = Join-Path $env:USERPROFILE '.ssh\id_rsa.pub'
if (-not (Test-Path -LiteralPath $publicKeyPath)) {
    throw "The existing public key was not found at $publicKeyPath. This script will not generate or replace SSH keys."
}

$sshKeygen = Join-Path $env:WINDIR 'System32\OpenSSH\ssh-keygen.exe'
if (-not (Test-Path -LiteralPath $sshKeygen)) {
    $sshKeygenCommand = Get-Command ssh-keygen.exe -ErrorAction SilentlyContinue
    if ($sshKeygenCommand) { $sshKeygen = $sshKeygenCommand.Source }
}
if (-not (Test-Path -LiteralPath $sshKeygen)) {
    throw 'OpenSSH Client tools (including ssh-keygen.exe) are missing. Install the Windows OpenSSH Client capability first.'
}

$keyLine = (Get-Content -LiteralPath $publicKeyPath -Raw).Trim()
$keyFields = $keyLine -split '\s+'
if ($keyFields.Count -lt 2 -or $keyFields[0] -notmatch '^ssh-rsa$') {
    throw 'Expected the existing RSA public key in id_rsa.pub. No keys were changed.'
}

$fingerprintOutput = (& $sshKeygen -lf $publicKeyPath 2>&1 | Out-String).Trim()
$expectedFingerprint = 'SHA256:U97bwHZAh6idVcIe/DWFCGFqttnLcNAJCPOJHoG1H9Y'
if ($fingerprintOutput -notmatch [regex]::Escape($expectedFingerprint)) {
    throw "The Windows RSA public key does not match the key currently used by VPS and Arch. Expected $expectedFingerprint; got: $fingerprintOutput. No keys were changed."
}

# Windows OpenSSH's default config directs administrator-group users to this
# shared file, rather than to %USERPROFILE%\.ssh\authorized_keys.
# Consequently, this key will authorize SSH for administrator-group accounts
# on this Windows host, as specified by the standard OpenSSH configuration.
$authorizedKeysPath = Join-Path $env:ProgramData 'ssh\administrators_authorized_keys'
$authorizedKeysDir = Split-Path -Parent $authorizedKeysPath
New-Item -ItemType Directory -Force -Path $authorizedKeysDir | Out-Null

if (-not (Test-Path -LiteralPath $authorizedKeysPath)) {
    New-Item -ItemType File -Path $authorizedKeysPath -Force | Out-Null
}

$existingLines = @(Get-Content -LiteralPath $authorizedKeysPath -ErrorAction SilentlyContinue)
$alreadyPresent = $false
foreach ($existingLine in $existingLines) {
    $fields = $existingLine.Trim() -split '\s+'
    if ($fields.Count -ge 2 -and $fields[1] -eq $keyFields[1]) {
        $alreadyPresent = $true
        break
    }
}
if (-not $alreadyPresent) {
    Add-Content -LiteralPath $authorizedKeysPath -Value $keyLine -Encoding Ascii
}

$icacls = Join-Path $env:WINDIR 'System32\icacls.exe'
& $icacls $authorizedKeysPath /inheritance:r /grant:r 'BUILTIN\Administrators:(F)' 'NT AUTHORITY\SYSTEM:(F)' | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Could not secure administrators_authorized_keys ACLs.' }
& $icacls $authorizedKeysPath /setowner 'BUILTIN\Administrators' | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Could not set the administrators_authorized_keys owner.' }

$sshdExe = Join-Path $env:WINDIR 'System32\OpenSSH\sshd.exe'
if (-not (Test-Path -LiteralPath $sshdExe)) {
    $capability = Get-WindowsCapability -Online -Name 'OpenSSH.Server*' | Select-Object -First 1
    if (-not $capability -or $capability.State -ne 'Installed') {
        Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0' | Out-Null
    }
}
if (-not (Test-Path -LiteralPath $sshdExe)) {
    throw 'OpenSSH Server was not found after checking/installing the Windows capability.'
}

& $sshdExe -t
if ($LASTEXITCODE -ne 0) { throw 'sshd configuration validation failed; the service was not restarted.' }

$sshFirewallRule = Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue
if ($sshFirewallRule) {
    $sshFirewallRule | Set-NetFirewallRule -Enabled True
    $sshFirewallRule | Get-NetFirewallAddressFilter | Set-NetFirewallAddressFilter -RemoteAddress '100.64.0.0/10'
} else {
    New-NetFirewallRule -Name 'OpenSSH-Server-TailscaleOnly' -DisplayName 'OpenSSH Server (Tailscale only)' -Direction Inbound -Enabled True -Action Allow -Protocol TCP -LocalPort 22 -RemoteAddress '100.64.0.0/10' -Profile Any | Out-Null
}

Set-Service -Name sshd -StartupType Automatic
Start-Service -Name sshd
Restart-Service -Name sshd

Write-Host "Configured Windows OpenSSH for the existing public key: $expectedFingerprint"
Write-Host "Authorized keys file: $authorizedKeysPath"
Write-Host 'No private key or existing key was removed or replaced.'
Write-Warning 'Windows OpenSSH defaults to a shared administrators_authorized_keys file for administrator-group accounts. This matches the default sshd_config behavior.'
Write-Host 'Firewall access for the default OpenSSH rule is limited to Tailscale addresses (100.64.0.0/10).'
