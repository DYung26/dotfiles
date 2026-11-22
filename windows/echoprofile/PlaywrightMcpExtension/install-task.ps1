$ErrorActionPreference = 'Stop'

$taskName = 'PlaywrightMcpExtension'
$scriptPath = Join-Path $PSScriptRoot 'run.ps1'
$tokenFile = Join-Path $env:LOCALAPPDATA 'PlaywrightMCP\edge-default.env'
$tokenConfigured = if (Test-Path -LiteralPath $tokenFile) {
    Get-Content -LiteralPath $tokenFile | Where-Object { $_ -match '^PLAYWRIGHT_MCP_EXTENSION_TOKEN=[A-Za-z0-9_-]{43}$' } | Select-Object -First 1
}
if (-not $tokenConfigured) {
    throw "Provision PLAYWRIGHT_MCP_EXTENSION_TOKEN once in $tokenFile before installing the unattended task."
}

$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero)

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description 'Playwright MCP connected to the default Microsoft Edge profile through the Playwright Extension.' -Force | Out-Null
Start-ScheduledTask -TaskName $taskName
Write-Output "Installed and started scheduled task: $taskName"
