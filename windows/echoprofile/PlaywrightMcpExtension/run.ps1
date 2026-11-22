$ErrorActionPreference = 'Stop'

$hostAddress = '100.98.45.0'
$port = 8933
$profileDirName = 'Default'
$userDataDir = Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data'
$sessionName = 'laptop-edge'
$stateDir = Join-Path $env:LOCALAPPDATA 'PlaywrightMCP'
$logDir = Join-Path $stateDir 'logs'
$envFile = Join-Path $stateDir 'edge-default.env'
$logFile = Join-Path $logDir 'extension-mcp.log'

New-Item -ItemType Directory -Force -Path $logDir | Out-Null
if (Test-Path $envFile) {
  Get-Content -LiteralPath $envFile | ForEach-Object {
    if ($_ -match '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
      [Environment]::SetEnvironmentVariable($Matches[1], $Matches[2], 'Process')
    }
  }
}

$npx = (Get-Command npx.cmd -ErrorAction Stop).Source
$mcpArgs = @(
  '--yes', '@playwright/mcp@latest',
  '--extension',
  '--port', "$port",
  '--host', $hostAddress,
  '--allowed-hosts', "$hostAddress`:$port",
  '--profile-dir-name', $profileDirName,
  '--user-data-dir', $userDataDir,
  '--background',
  '--session-name', $sessionName,
  '--shared-browser-context'
)

"[$(Get-Date -Format o)] Starting Playwright Extension MCP on $hostAddress`:$port" | Add-Content -LiteralPath $logFile
& $npx @mcpArgs 2>&1 | ForEach-Object { "[$(Get-Date -Format o)] $_" | Add-Content -LiteralPath $logFile }
exit $LASTEXITCODE
