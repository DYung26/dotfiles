$ErrorActionPreference = 'Stop'

if (-not $env:PLAYWRIGHT_MCP_USER_DATA_DIR) {
    $env:PLAYWRIGHT_MCP_USER_DATA_DIR = Join-Path $env:USERPROFILE '.local\share\echoprofile\edge-profile'
}
if (-not $env:PLAYWRIGHT_MCP_EXECUTABLE_PATH) {
    $edge = Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'
    if (-not (Test-Path $edge)) { throw "Microsoft Edge executable not found: $edge" }
    $env:PLAYWRIGHT_MCP_EXECUTABLE_PATH = $edge
}

$env:PATH = (Join-Path $env:LOCALAPPDATA 'pnpm') + ';' + $env:PATH
$cli = Join-Path $env:LOCALAPPDATA 'pnpm\playwright-cli.cmd'
if (-not (Test-Path $cli)) { throw "Playwright CLI is not installed. Run: pnpm add -g @playwright/cli@latest" }
& $cli @args
exit $LASTEXITCODE
