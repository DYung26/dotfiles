[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$McpShellSource,
    [switch]$EnableCloudflared
)
$ErrorActionPreference = 'Stop'
if (-not $RepoRoot) { $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path }
if ($env:OS -ne 'Windows_NT') { throw 'Run this installer in PowerShell on Windows.' }

$UserHome = [IO.Path]::GetFullPath($env:USERPROFILE).TrimEnd('\')
$LocalRoot = Join-Path $env:LOCALAPPDATA 'McpShell'
$BinDir = Join-Path $UserHome '.local\bin'
$CloudflaredDir = Join-Path $LocalRoot 'cloudflared'
$CloudflaredConfig = Join-Path $CloudflaredDir 'config.yml'
$CloudflaredEnvFile = Join-Path $CloudflaredDir 'tunnel.conf'
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

New-Item -ItemType Directory -Force -Path $LocalRoot, $BinDir, $CloudflaredDir, $LogDir | Out-Null
$RepoRoot = (Resolve-Path $RepoRoot).Path
if (-not $McpShellSource) {
    $projectsRoot = Split-Path $RepoRoot -Parent
    foreach ($candidate in @((Join-Path $projectsRoot 'mcp-shell'), (Join-Path $projectsRoot 'mcp-shell-src'))) {
        if (Test-Path (Join-Path $candidate 'go.mod')) { $McpShellSource = $candidate; break }
    }
}
function Refresh-UserPath {
    $candidates = @($BinDir, $GoBin, 'C:\Program Files\Go\bin', 'C:\Program Files\Git\bin', 'C:\Program Files\Git\usr\bin')
    $env:Path = (($candidates + $env:Path.Split(';') | Where-Object { $_ -and ((Test-Path $_) -or ($_ -eq $BinDir)) } | Select-Object -Unique) -join ';')
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

if (-not $McpShellSource) {
    $McpShellSource = Join-Path $LocalRoot 'src'
    if (-not (Test-Path (Join-Path $McpShellSource 'go.mod'))) {
        $gitExe = Resolve-CommandPath 'git.exe'
        if (-not $gitExe) { throw 'Git is required to clone https://github.com/DYung26/mcp-shell.git.' }
        if (Test-Path $McpShellSource) { throw "Source directory exists but is not a Go module: $McpShellSource" }
        & $gitExe clone https://github.com/DYung26/mcp-shell.git $McpShellSource
        if ($LASTEXITCODE -ne 0) { throw "Could not clone mcp-shell source (exit $LASTEXITCODE)." }
    }
}
$McpShellSource = (Resolve-Path $McpShellSource).Path
if (-not (Test-Path (Join-Path $McpShellSource 'go.mod'))) { throw "McpShellSource is not a Go module: $McpShellSource" }

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

Push-Location $McpShellSource
try {
    & $GoExe build -o $McpShellExe .
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $McpShellExe)) { throw "go build mcp-shell failed (exit $LASTEXITCODE)." }
} finally {
    Pop-Location
}
if (-not (Test-Path $McpProxyExe)) {
    & $UvExe tool install --force mcp-proxy
    if ($LASTEXITCODE -ne 0) { throw "uv tool install mcp-proxy failed (exit $LASTEXITCODE)." }
    $uvBinDir = (& $UvExe tool dir --bin).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $uvBinDir) { throw 'Could not determine uv tool executable directory.' }
    $uvProxyExe = Join-Path $uvBinDir 'mcp-proxy.exe'
    if (-not (Test-Path $uvProxyExe)) { throw "uv installed mcp-proxy but executable was not found at $uvProxyExe." }
    if ($uvProxyExe -ne $McpProxyExe) { Copy-Item -LiteralPath $uvProxyExe -Destination $McpProxyExe -Force }
}
if (-not (Test-Path $CloudflaredExe)) {
    Invoke-WebRequest -Uri 'https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe' -OutFile $CloudflaredExe
}

if (-not (Test-Path $CloudflaredCert)) {
    $existingCert = Join-Path $UserHome '.cloudflared\cert.pem'
    if (Test-Path $existingCert) { Copy-Item -LiteralPath $existingCert -Destination $CloudflaredCert -Force }
}
if (-not (Test-Path $CredentialTarget)) {
    # Keep tunnel credentials and the account origin certificate in local app
    # data; never synchronize them through the dotfiles checkout.
    if (-not (Test-Path $CloudflaredCert)) {
        Write-Host 'Cloudflare origin certificate is missing; opening Cloudflare login in the browser.'
        $env:TUNNEL_ORIGIN_CERT = $CloudflaredCert
        & $CloudflaredExe tunnel --origincert $CloudflaredCert login
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $CloudflaredCert)) {
            throw "cloudflared tunnel login failed or did not create $CloudflaredCert."
        }
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
$templatePosix = $CloudflaredTemplate.Replace('\', '/')
$configPosix = $CloudflaredConfig.Replace('\', '/')
$cloudflaredEnv = @(
    "CLOUDFLARED_CREDENTIALS_FILE=$credentialPosix",
    'CLOUDFLARED_TUNNEL_NAME=mcp.laptop-ab9612ik',
    'CLOUDFLARED_HOSTNAME=laptop-ab9612ik-mcp.dyung.me',
    'CLOUDFLARED_SERVICE=http://127.0.0.1:8090',
    "CLOUDFLARED_CONFIG_TEMPLATE=$templatePosix",
    "CLOUDFLARED_CONFIG_RENDERED=$configPosix"
) -join [Environment]::NewLine
[IO.File]::WriteAllText($CloudflaredEnvFile, $cloudflaredEnv + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
$config = Get-Content -Raw -LiteralPath $CloudflaredTemplate
$config = $config.Replace('${CLOUDFLARED_TUNNEL_NAME}', 'mcp.laptop-ab9612ik')
$config = $config.Replace('${CLOUDFLARED_CREDENTIALS_FILE}', $credentialPosix)
$config = $config.Replace('${CLOUDFLARED_HOSTNAME}', 'laptop-ab9612ik-mcp.dyung.me')
$config = $config.Replace('${CLOUDFLARED_SERVICE}', 'http://127.0.0.1:8090')
[IO.File]::WriteAllText($CloudflaredConfig, $config, [Text.UTF8Encoding]::new($false))

$proxyRunner = @'
$ErrorActionPreference = 'Continue'
$userHome = [IO.Path]::GetFullPath($env:USERPROFILE)
$mutex = [Threading.Mutex]::new($false, 'Local\McpShellProxyLauncher')
if (-not $mutex.WaitOne(0)) { exit 0 }
$root = Join-Path $env:LOCALAPPDATA 'McpShell'
$proxy = Join-Path $userHome '.local\bin\mcp-proxy.exe'
$shell = Join-Path $userHome 'go\bin\mcp-shell.exe'
$policy = Join-Path $root 'security.yaml'
$log = Join-Path $root 'logs\mcp-proxy.log'
$supervisorLog = Join-Path $root 'logs\mcp-proxy-supervisor.log'
$env:HOME = $userHome
$env:MCP_SHELL_SEC_CONFIG_FILE = $policy
$env:MCP_SHELL_LOG_LEVEL = 'info'
$env:PATH = "$userHome\.local\bin;$userHome\go\bin;C:\Program Files\Git\bin;C:\Program Files\Git\usr\bin;$env:PATH"
while ($true) {
    "$(Get-Date -Format o) starting mcp-proxy on 127.0.0.1:8090" | Add-Content -LiteralPath $supervisorLog
    & $proxy --port=8090 --host=127.0.0.1 --pass-environment -- $shell *>> $log
    "$(Get-Date -Format o) mcp-proxy exited with code $LASTEXITCODE; restarting in 5 seconds" | Add-Content -LiteralPath $supervisorLog
    Start-Sleep -Seconds 5
}
'@
Set-Content -LiteralPath $StartProxyScript -Value $proxyRunner -Encoding UTF8

$cloudflaredRunner = @'
$ErrorActionPreference = 'Continue'
$userHome = [IO.Path]::GetFullPath($env:USERPROFILE)
$mutex = [Threading.Mutex]::new($false, 'Local\CloudflaredMcpLauncher')
if (-not $mutex.WaitOne(0)) { exit 0 }
$root = Join-Path $env:LOCALAPPDATA 'McpShell'
$cloudDir = Join-Path $root 'cloudflared'
$envFile = Join-Path $cloudDir 'tunnel.conf'
$exe = Join-Path $userHome '.local\bin\cloudflared.exe'
$log = Join-Path $root 'logs\cloudflared.log'
$supervisorLog = Join-Path $root 'logs\cloudflared-supervisor.log'
while ($true) {
    foreach ($line in Get-Content -LiteralPath $envFile) {
        $separator = $line.IndexOf('=')
        if ($separator -gt 0 -and -not $line.TrimStart().StartsWith('#')) {
            $key = $line.Substring(0, $separator).Trim()
            $value = $line.Substring($separator + 1).Trim()
            [Environment]::SetEnvironmentVariable($key, $value, 'Process')
        }
    }
    $template = $env:CLOUDFLARED_CONFIG_TEMPLATE
    $config = $env:CLOUDFLARED_CONFIG_RENDERED
    $content = Get-Content -Raw -LiteralPath $template
    $content = $content.Replace('${CLOUDFLARED_TUNNEL_NAME}', $env:CLOUDFLARED_TUNNEL_NAME)
    $content = $content.Replace('${CLOUDFLARED_CREDENTIALS_FILE}', $env:CLOUDFLARED_CREDENTIALS_FILE)
    $content = $content.Replace('${CLOUDFLARED_HOSTNAME}', $env:CLOUDFLARED_HOSTNAME)
    $content = $content.Replace('${CLOUDFLARED_SERVICE}', $env:CLOUDFLARED_SERVICE)
    [IO.File]::WriteAllText($config, $content, [Text.UTF8Encoding]::new($false))
    "$(Get-Date -Format o) starting cloudflared tunnel $env:CLOUDFLARED_TUNNEL_NAME" | Add-Content -LiteralPath $supervisorLog
    & $exe tunnel --config $config --loglevel info run *>> $log
    "$(Get-Date -Format o) cloudflared exited with code $LASTEXITCODE; restarting in 5 seconds" | Add-Content -LiteralPath $supervisorLog
    Start-Sleep -Seconds 5
}
'@
Set-Content -LiteralPath $StartCloudflaredScript -Value $cloudflaredRunner -Encoding UTF8

$powerShellExe = Join-Path $PSHOME 'powershell.exe'
if (-not (Test-Path $powerShellExe)) { $powerShellExe = (Get-Command pwsh.exe -ErrorAction SilentlyContinue).Source }
if (-not $powerShellExe) { throw 'Could not locate powershell.exe/pwsh.exe.' }
$userId = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $userId
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -RestartCount 5 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew
$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel Limited
$proxyArg = '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $StartProxyScript + '"'
$cloudflaredArg = '-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $StartCloudflaredScript + '"'
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
Write-Host "mcp-shell built from $McpShellSource and mcp-proxy installed; proxy task starts at user logon."
Write-Host "Cloudflare config: $CloudflaredConfig"
if ($EnableCloudflared) {
    Write-Warning 'Cloudflared is enabled. Ensure Cloudflare Access or another authentication gate protects the shell endpoint.'
} else {
    Write-Warning 'Cloudflared task is DISABLED until an authentication gate protects the public shell endpoint. Use -EnableCloudflared only after adding the gate.'
}
