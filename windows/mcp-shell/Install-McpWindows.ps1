[CmdletBinding()]
param(
    [string]$RepoRoot = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent),
    [switch]$EnableCloudflared
)
$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') { throw 'Run this installer in PowerShell on Windows.' }

$UserHome = [IO.Path]::GetFullPath($env:USERPROFILE).TrimEnd('\')
$LocalRoot = Join-Path $env:LOCALAPPDATA 'McpShell'
$BinDir = Join-Path $UserHome '.local\bin'
$CloudflaredDir = Join-Path $LocalRoot 'cloudflared'
$CloudflaredConfig = Join-Path $CloudflaredDir 'config.yml'
$CredentialName = '5d72e218-636e-4184-85cf-4b7a25acc383.json'
$CredentialTarget = Join-Path $CloudflaredDir $CredentialName
$CloudflaredCert = Join-Path $CloudflaredDir 'cert.pem'
$PolicyTemplate = Join-Path $RepoRoot 'mcp-shell-privileged\.config\mcp-shell\security.windows.yaml'
$PolicyTarget = Join-Path $LocalRoot 'security.yaml'
$CloudflaredTemplate = Join-Path $RepoRoot 'cloudflared\.cloudflared\config.windows.yml'
$StartProxyScript = Join-Path $LocalRoot 'Start-McpShellProxy.ps1'
$StartCloudflaredScript = Join-Path $LocalRoot 'Start-Cloudflared.ps1'
$LogDir = Join-Path $LocalRoot 'logs'
$GoBin = Join-Path $UserHome 'go\bin'
$McpShellExe = Join-Path $GoBin 'mcp-shell.exe'
$McpProxyExe = Join-Path $BinDir 'mcp-proxy.exe'
$CloudflaredExe = Join-Path $BinDir 'cloudflared.exe'
$McpShellVersion = 'v0.7.2-0.20261011185850-100f9ab7d0b1'

New-Item -ItemType Directory -Force -Path $LocalRoot, $BinDir, $CloudflaredDir, $LogDir | Out-Null
$RepoRoot = (Resolve-Path $RepoRoot).Path
function Refresh-UserPath {
    $candidates = @($BinDir, $GoBin, 'C:\Program Files\Go\bin', 'C:\Program Files\Git\bin', 'C:\Program Files\Git\usr\bin')
    $env:Path = (($candidates + $env:Path.Split(';') | Where-Object { $_ -and (Test-Path $_ -or $_ -eq $BinDir) } | Select-Object -Unique) -join ';')
}
function Resolve-CommandPath([string]$Name) {
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}
Refresh-UserPath

$GoExe = Resolve-CommandPath 'go.exe'
if (-not $GoExe -and (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    & winget install --id GoLang.Go --exact --silent --accept-package-agreements --accept-source-agreements
    Refresh-UserPath
    $GoExe = Resolve-CommandPath 'go.exe'
}
if (-not $GoExe -and (Test-Path 'C:\Program Files\Go\bin\go.exe')) { $GoExe = 'C:\Program Files\Go\bin\go.exe' }
if (-not $GoExe) { throw 'Go is required. Install Go from https://go.dev/dl/ and rerun this script.' }

if (-not (Resolve-CommandPath 'bash.exe') -and (Get-Command winget.exe -ErrorAction SilentlyContinue)) {
    & winget install --id Git.Git --exact --silent --accept-package-agreements --accept-source-agreements
    Refresh-UserPath
}
if (-not (Resolve-CommandPath 'bash.exe')) {
    if (Test-Path 'C:\Program Files\Git\bin\bash.exe') { $env:Path = "C:\Program Files\Git\bin;C:\Program Files\Git\usr\bin;$env:Path" }
}
if (-not (Resolve-CommandPath 'bash.exe')) { throw 'Git for Windows (Git Bash) is required by the legacy shell-execution mode.' }

$UvExe = Resolve-CommandPath 'uv.exe'
if (-not $UvExe) {
    $uvInstall = Invoke-RestMethod 'https://astral.sh/uv/install.ps1'
    Invoke-Expression $uvInstall
    Refresh-UserPath
    $UvExe = Resolve-CommandPath 'uv.exe'
}
if (-not $UvExe) {
    foreach ($candidate in @((Join-Path $UserHome '.local\bin\uv.exe'), (Join-Path $UserHome '.cargo\bin\uv.exe'))) {
        if (Test-Path $candidate) { $UvExe = $candidate; break }
    }
}
if (-not $UvExe) { throw 'Could not locate uv.exe after installation.' }

& $GoExe install "github.com/sonirico/mcp-shell@$McpShellVersion"
if ($LASTEXITCODE -ne 0 -or -not (Test-Path $McpShellExe)) { throw "go install mcp-shell failed (exit $LASTEXITCODE)." }
if (-not (Test-Path $McpProxyExe)) {
    & $UvExe tool install --bin-dir $BinDir mcp-proxy
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $McpProxyExe)) { throw "uv tool install mcp-proxy failed (exit $LASTEXITCODE)." }
}
if (-not (Test-Path $CloudflaredExe)) {
    Invoke-WebRequest -Uri 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe' -OutFile $CloudflaredExe
}

if (-not (Test-Path $CredentialTarget)) {
    # Keep tunnel credentials and the account origin certificate in local app
    # data; never synchronize them through the dotfiles checkout.
    Write-Host 'Cloudflare tunnel credentials are missing; opening Cloudflare login in the browser.'
    $env:TUNNEL_ORIGIN_CERT = $CloudflaredCert
    & $CloudflaredExe tunnel --origincert $CloudflaredCert login
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $CloudflaredCert)) {
        throw "cloudflared tunnel login failed or did not create $CloudflaredCert."
    }
    & $CloudflaredExe tunnel --origincert $CloudflaredCert token --cred-file $CredentialTarget mcp.laptop-ab9612ik
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $CredentialTarget)) {
        throw "Could not provision credentials for tunnel mcp.laptop-ab9612ik."
    }
}
if (-not (Test-Path $CredentialTarget)) { throw "Tunnel credentials missing at $CredentialTarget." }

if (-not (Test-Path $PolicyTemplate)) { throw "Missing Windows policy template: $PolicyTemplate" }
$homeRegex = [regex]::Escape($UserHome)
$gitBashHome = '/' + $env:SystemDrive.TrimEnd(':').ToLowerInvariant() + '/Users/' + $env:USERNAME
$gitBashHomeRegex = [regex]::Escape($gitBashHome)
$systemRootRegex = [regex]::Escape($env:SystemRoot)
$homeSlash = $UserHome.Replace('\', '/')
$policy = Get-Content -Raw -LiteralPath $PolicyTemplate
$policy = $policy.Replace('__HOME_REGEX__', $homeRegex)
$policy = $policy.Replace('__GIT_BASH_HOME_REGEX__', $gitBashHomeRegex)
$policy = $policy.Replace('__SYSTEMROOT_REGEX__', $systemRootRegex)
$policy = $policy.Replace('__WINDOWS_HOME_SLASH__', $homeSlash)
[IO.File]::WriteAllText($PolicyTarget, $policy, [Text.UTF8Encoding]::new($false))

if (-not (Test-Path $CloudflaredTemplate)) { throw "Missing Cloudflare template: $CloudflaredTemplate" }
$credentialPosix = $CredentialTarget.Replace('\', '/')
$config = Get-Content -Raw -LiteralPath $CloudflaredTemplate
$config = $config.Replace('__WINDOWS_CREDENTIALS_FILE__', $credentialPosix)
[IO.File]::WriteAllText($CloudflaredConfig, $config, [Text.UTF8Encoding]::new($false))

$proxyRunner = @'
$ErrorActionPreference = 'Continue'
$home = [IO.Path]::GetFullPath($env:USERPROFILE)
$root = Join-Path $env:LOCALAPPDATA 'McpShell'
$proxy = Join-Path $home '.local\bin\mcp-proxy.exe'
$shell = Join-Path $home 'go\bin\mcp-shell.exe'
$policy = Join-Path $root 'security.yaml'
$log = Join-Path $root 'logs\mcp-proxy.log'
$env:HOME = $home
$env:MCP_SHELL_SEC_CONFIG_FILE = $policy
$env:MCP_SHELL_LOG_LEVEL = 'info'
$env:PATH = "$home\.local\bin;$home\go\bin;C:\Program Files\Git\bin;C:\Program Files\Git\usr\bin;$env:PATH"
while ($true) {
    "$(Get-Date -Format o) starting mcp-proxy on 127.0.0.1:8090" | Add-Content -LiteralPath $log
    & $proxy --port=8090 --host=127.0.0.1 --pass-environment -- $shell *>> $log
    "$(Get-Date -Format o) mcp-proxy exited with code $LASTEXITCODE; restarting in 5 seconds" | Add-Content -LiteralPath $log
    Start-Sleep -Seconds 5
}
'@
Set-Content -LiteralPath $StartProxyScript -Value $proxyRunner -Encoding UTF8

$cloudflaredRunner = @'
$ErrorActionPreference = 'Continue'
$home = [IO.Path]::GetFullPath($env:USERPROFILE)
$root = Join-Path $env:LOCALAPPDATA 'McpShell'
$exe = Join-Path $home '.local\bin\cloudflared.exe'
$config = Join-Path $root 'cloudflared\config.yml'
$log = Join-Path $root 'logs\cloudflared.log'
while ($true) {
    "$(Get-Date -Format o) starting cloudflared tunnel" | Add-Content -LiteralPath $log
    & $exe tunnel --config $config run *>> $log
    "$(Get-Date -Format o) cloudflared exited with code $LASTEXITCODE; restarting in 5 seconds" | Add-Content -LiteralPath $log
    Start-Sleep -Seconds 5
}
'@
Set-Content -LiteralPath $StartCloudflaredScript -Value $cloudflaredRunner -Encoding UTF8

$powerShellExe = Join-Path $PSHOME 'powershell.exe'
if (-not (Test-Path $powerShellExe)) { $powerShellExe = (Get-Command pwsh.exe -ErrorAction SilentlyContinue).Source }
if (-not $powerShellExe) { throw 'Could not locate powershell.exe/pwsh.exe.' }
$userId = "$env:USERDOMAIN\$env:USERNAME"
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $userId
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -RestartCount 5 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel Limited
$proxyArg = '-NoProfile -ExecutionPolicy Bypass -File "' + $StartProxyScript + '"'
$cloudflaredArg = '-NoProfile -ExecutionPolicy Bypass -File "' + $StartCloudflaredScript + '"'
$proxyAction = New-ScheduledTaskAction -Execute $powerShellExe -Argument $proxyArg
Register-ScheduledTask -TaskName 'McpShellProxy-Laptop' -Action $proxyAction -Trigger $trigger -Settings $settings -Principal $principal -Description 'Run MCP shell proxy on 127.0.0.1:8090' -Force | Out-Null
Start-ScheduledTask -TaskName 'McpShellProxy-Laptop'

$cloudflaredAction = New-ScheduledTaskAction -Execute $powerShellExe -Argument $cloudflaredArg
Register-ScheduledTask -TaskName 'Cloudflared-Mcp-Laptop' -Action $cloudflaredAction -Trigger $trigger -Settings $settings -Principal $principal -Description 'Cloudflare Tunnel for laptop-ab9612ik-mcp.dyung.me' -Force | Out-Null
if ($EnableCloudflared) {
    Enable-ScheduledTask -TaskName 'Cloudflared-Mcp-Laptop' | Out-Null
    Start-ScheduledTask -TaskName 'Cloudflared-Mcp-Laptop'
} else {
    Disable-ScheduledTask -TaskName 'Cloudflared-Mcp-Laptop' | Out-Null
}

& $CloudflaredExe tunnel --config $CloudflaredConfig ingress validate
if ($LASTEXITCODE -ne 0) { throw 'Cloudflare ingress config validation failed; tunnel task remains disabled.' }
Write-Host 'mcp-shell and mcp-proxy installed; proxy task starts at user logon.'
Write-Host "Cloudflare config: $CloudflaredConfig"
if ($EnableCloudflared) {
    Write-Warning 'Cloudflared is enabled. Ensure Cloudflare Access or another authentication gate protects the shell endpoint.'
} else {
    Write-Warning 'Cloudflared task is DISABLED until an authentication gate protects the public shell endpoint. Use -EnableCloudflared only after adding the gate.'
}
