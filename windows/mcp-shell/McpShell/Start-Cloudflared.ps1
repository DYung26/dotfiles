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
