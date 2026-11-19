$ErrorActionPreference = 'Continue'
$root = Join-Path $env:LOCALAPPDATA 'EchoProfile'
$log = Join-Path $root 'login.log'
$exe = Join-Path $env:USERPROFILE '.local\bin\echoprofile.exe'
$health = 'http://100.98.45.0:8756/health'
New-Item -ItemType Directory -Force -Path $root | Out-Null
Set-Location $env:USERPROFILE
$env:ECHOPROFILE_CHANNEL = 'msedge'
$env:ECHOPROFILE_HOST = '100.98.45.0'
$env:ECHOPROFILE_MULTICA_DIR = (Join-Path $env:USERPROFILE 'Projects/multica-web-runtime/extension/dist')
$env:ECHOPROFILE_BROWSER_EXTENSION_DIR = (Join-Path $env:USERPROFILE 'Projects/echoprofile/echoprofile/browser_extension')
$env:ECHOPROFILE_EXTRA_EXTENSION_DIRS = (Join-Path $env:LOCALAPPDATA 'EchoProfile/playwright-extension')
while ($true) {
  try {
    $response = Invoke-RestMethod -Uri $health -TimeoutSec 3
    if ($response.status -ne 'ok') { Start-Sleep -Seconds 5; continue }
  } catch { Start-Sleep -Seconds 5; continue }
  $status = (& $exe persistent-status 2>&1 | Out-String).Trim()
  if ($LASTEXITCODE -eq 0 -and $status -match '^open') { Start-Sleep -Seconds 15; continue }
  Add-Content $log "[$(Get-Date -Format o)] Persistent browser is closed; requesting login."
  & $exe login *>> $log
  if ($LASTEXITCODE -ne 0) { Add-Content $log "[$(Get-Date -Format o)] Login failed; retrying in 10 seconds."; Start-Sleep -Seconds 10 }
}
