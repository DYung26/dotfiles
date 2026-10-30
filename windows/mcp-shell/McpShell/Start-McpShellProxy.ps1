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
