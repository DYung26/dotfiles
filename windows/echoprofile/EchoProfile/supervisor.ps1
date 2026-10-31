$ErrorActionPreference = 'Stop'
$root = Join-Path $env:LOCALAPPDATA 'EchoProfile'
$log = Join-Path $root 'serve.log'
$exe = Join-Path $env:USERPROFILE '.local\bin\echoprofile.exe'
Set-Location $env:USERPROFILE
$env:ECHOPROFILE_HOST = '100.98.45.0'
$env:ECHOPROFILE_CHANNEL = 'msedge'
$env:ECHOPROFILE_MULTICA_DIR = (Join-Path $env:USERPROFILE 'Projects/multica-web-runtime/extension/dist')
$env:ECHOPROFILE_NO_RELOAD = '1'
$env:ECHOPROFILE_AUTO_FALLBACK = 'false'
$env:ECHOPROFILE_CDP_PORT = '9222'
while ($true) {
  while (-not (Get-NetIPAddress -IPAddress '100.98.45.0' -ErrorAction SilentlyContinue)) { Start-Sleep -Seconds 5 }
  Add-Content -Path $log -Value ("[" + (Get-Date -Format o) + "] Starting EchoProfile")
  $cmdArgs = '/d /s /c ""' + $exe + '" serve >> "' + $log + '" 2>&1"'
  $p = Start-Process -FilePath $env:ComSpec -ArgumentList $cmdArgs -PassThru -Wait -WindowStyle Hidden
  Add-Content -Path $log -Value ("[" + (Get-Date -Format o) + "] EchoProfile exited with code " + $p.ExitCode + "; retrying in 10 seconds")
  Start-Sleep -Seconds 10
}
