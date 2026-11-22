$ErrorActionPreference = 'Stop'

if (-not $env:PLAYWRIGHT_MCP_USER_DATA_DIR) {
    $env:PLAYWRIGHT_MCP_USER_DATA_DIR = Join-Path $env:USERPROFILE '.local\share\echoprofile\edge-profile'
}
if (-not $env:PLAYWRIGHT_MCP_EXECUTABLE_PATH) {
    $edge = Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'
    if (-not (Test-Path $edge)) { throw "Microsoft Edge executable not found: $edge" }
    $env:PLAYWRIGHT_MCP_EXECUTABLE_PATH = $edge
}

$usesExtension = $args | Where-Object { $_ -eq '--extension' -or $_ -like '--extension=*' }
if ($usesExtension -and [string]::IsNullOrWhiteSpace($env:PLAYWRIGHT_MCP_EXTENSION_TOKEN)) {
    $tokenFile = if ($env:PLAYWRIGHT_MCP_EXTENSION_TOKEN_FILE) {
        $env:PLAYWRIGHT_MCP_EXTENSION_TOKEN_FILE
    } else {
        Join-Path $env:LOCALAPPDATA 'PlaywrightMCP\echoprofile.env'
    }
    if (Test-Path -LiteralPath $tokenFile) {
        Get-Content -LiteralPath $tokenFile | ForEach-Object {
            if ($_ -match '^PLAYWRIGHT_MCP_EXTENSION_TOKEN=(.+)$') {
                $env:PLAYWRIGHT_MCP_EXTENSION_TOKEN = $Matches[1]
            }
        }
    }
    if ([string]::IsNullOrWhiteSpace($env:PLAYWRIGHT_MCP_EXTENSION_TOKEN)) {
        throw "Playwright Extension token missing. Provision it once in $tokenFile; refusing interactive browser approval."
    }
}

$env:PATH = (Join-Path $env:LOCALAPPDATA 'pnpm') + ';' + $env:PATH
$cli = Join-Path $env:LOCALAPPDATA 'pnpm\playwright-cli.cmd'
if (-not (Test-Path $cli)) { throw "Playwright CLI is not installed. Run: pnpm add -g @playwright/cli@latest" }
& $cli @args
exit $LASTEXITCODE
