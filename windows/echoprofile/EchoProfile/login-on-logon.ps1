$env:ECHOPROFILE_CHANNEL='msedge'
$env:ECHOPROFILE_HOST='100.98.45.0'
$env:ECHOPROFILE_MULTICA_DIR = (Join-Path $env:USERPROFILE 'Projects/multica-web-runtime/extension/dist')
$ErrorActionPreference = 'Stop'
$root = Join-Path $env:LOCALAPPDATA 'EchoProfile'
$log = Join-Path $root 'login.log'
$exe = Join-Path $env:USERPROFILE '.local\bin\echoprofile.exe'
$health = 'http://100.98.45.0:8756/health'
New-Item -ItemType Directory -Force -Path $root | Out-Null
for ($attempt = 1; $attempt -le 60; $attempt++) {
  try {
    $response = Invoke-RestMethod -Uri $health -TimeoutSec 3
    if ($response.status -eq 'ok') { break }
  } catch {}
  Start-Sleep -Seconds 5
}
if ($attempt -gt 60) { throw 'EchoProfile API did not become healthy within five minutes.' }
$status = (& $exe persistent-status 2>&1 | Out-String).Trim()
if ($status -match '^open') {
  Add-Content $log "[$(Get-Date -Format o)] Persistent browser already open; skipping login."
  exit 0
}
for ($attempt = 1; $attempt -le 3; $attempt++) {
  Add-Content $log "[$(Get-Date -Format o)] Starting persistent browser (attempt $attempt)."
  $loginOutput = & $exe login 2>&1 | Out-String
  $loginExitCode = $LASTEXITCODE
  [IO.File]::AppendAllText($log, $loginOutput + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
  if ($loginExitCode -eq 0) {
    Add-Content $log "[$(Get-Date -Format o)] Login command completed."
    exit 0
  }
  Start-Sleep -Seconds 10
}
throw 'EchoProfile login failed after three attempts.'
