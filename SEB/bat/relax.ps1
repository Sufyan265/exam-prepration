$ErrorActionPreference='Continue'
$root=$PSScriptRoot
Set-Location -LiteralPath $root
[Environment]::CurrentDirectory=$root
Write-Host "DIR: $root" -ForegroundColor Cyan

foreach($n in 'SafeExamBrowser','SafeExamBrowser.Client','SafeExamBrowser.Browser'){
  Get-Process $n -EA 0 | ForEach-Object { Write-Host "kill $($_.ProcessName) $($_.Id)"; try{$_.Kill()}catch{} }
}
Start-Sleep -Milliseconds 1500

foreach($p in "$env:APPDATA\SafeExamBrowser_old","$env:LOCALAPPDATA\SafeExamBrowser_old","$env:PROGRAMDATA\SafeExamBrowser_old"){
  if(Test-Path -LiteralPath $p){ Remove-Item -LiteralPath $p -Recurse -Force -EA SilentlyContinue; Write-Host "rm $p" }
}
$moved=0
foreach($p in "$env:APPDATA\SafeExamBrowser","$env:LOCALAPPDATA\SafeExamBrowser","$env:PROGRAMDATA\SafeExamBrowser"){
  if(Test-Path -LiteralPath $p){
    try{ Move-Item -LiteralPath $p -Destination ($p+'_old') -Force; Write-Host "moved $p"; $moved++ }
    catch{ Write-Host "MOVE FAIL $p : $($_.Exception.Message)" -ForegroundColor Red }
  }
}
Write-Host "markers moved: $moved"

$src=Join-Path $root 'original.seb'
if(-not (Test-Path -LiteralPath $src)){
  $c=Get-ChildItem -LiteralPath $root -Filter *.seb -File -EA 0 | Where-Object { $_.Name -notmatch 'relaxed|stripped' } | Select-Object -First 1
  if($c){ $src=$c.FullName; Write-Host "using $($c.Name)" -ForegroundColor Yellow }
}
if(-not (Test-Path -LiteralPath $src)){ Write-Host "NO .seb IN $root" -ForegroundColor Red; exit }

$b=[IO.File]::ReadAllBytes($src)
Write-Host "file: $src"
Write-Host ("size: {0}  head: {1}" -f $b.Length, (($b[0..([Math]::Min(15,$b.Length-1))]|%{$_.ToString('X2')}) -join ' '))
if($b.Length -lt 6){ Write-Host "file too small" -ForegroundColor Red; exit }
$magic=[Text.Encoding]::ASCII.GetString($b,0,4)
Write-Host "MAGIC=$magic"
if($magic -ne 'plnd'){ Write-Host "encrypted -> open in SEBConfigTool, admin password: admin" -ForegroundColor Red; exit }

$ms=New-Object IO.MemoryStream(,$b[4..($b.Length-1)])
$gz=New-Object IO.Compression.GZipStream($ms,[IO.Compression.CompressionMode]::Decompress)
$o=New-Object IO.MemoryStream; $gz.CopyTo($o); $gz.Close()
$xml=[Text.Encoding]::UTF8.GetString($o.ToArray())
Write-Host "xml bytes: $($xml.Length)"

function SetB($x,$k,$v){
  $t="<key>$k</key>"; $val=if($v){"<true/>"}else{"<false/>"}
  if($x -match [regex]::Escape($t)){ $x -replace "(?s)$([regex]::Escape($t))\s*<(true|false)\s*/>","$t$val" }
  else { $x -replace '(?s)</dict>\s*</plist>',"$t$val</dict></plist>" }
}
foreach($k in 'hashedQuitPassword','hashedAdminPassword','hashedSettingsPassword','quitPassword','passwordSalt','hashedRestartPassword'){
  $xml=$xml -replace "(?s)<key>$k</key>\s*<string>[^<]*</string>",''
}
$xml=$xml -replace '(?s)<key>permittedProcesses</key>\s*<array>.*?</array>','<key>permittedProcesses</key><array><dict><key>active</key><true/><key>allowUserToChooseApp</key><true/><key>autostart</key><false/><key>description</key><string>Chrome</string><key>executable</key><string>chrome.exe</string><key>iconInTaskbar</key><true/><key>identifier</key><string>Chrome</string><key>os</key><integer>1</integer><key>path</key><string>C:\Program Files\Google\Chrome\Application\chrome.exe</string><key>runInBackground</key><false/><key>strongKill</key><false/><key>title</key><string>Chrome</string><key>windowHandlingProcess</key><string></string></dict></array>'
$xml=$xml -replace '(?s)<key>prohibitedProcesses</key>\s*<array>.*?</array>','<key>prohibitedProcesses</key><array></array>'
foreach($k in 'allowSwitchToApplications','enableAltTab','enableStartMenu','enableF3','enableEsc','showTaskBar','allowDeveloperConsole','enablePrintScreen','allowDownUploads','allowStickyKeys','allowQuit','ignoreQuitPassword','disableSessionChangeLockScreen','showSideMenu','enableBrowserWindowToolbar','showReloadButton','allowVirtualMachine','insideSebEnableShutDown','insideSebEnableSwitchUser','insideSebEnableStartTaskManager','insideSebEnableEaseOfAccess'){
  $xml=SetB $xml $k $true
}
foreach($k in 'createNewDesktop','killExplorerShell','enablePrivateClipboard','lockOnMessageSocketClose','URLFilterEnable','forceAppFolderInstall'){
  $xml=SetB $xml $k $false
}
$xml=$xml -replace '(?s)<key>browserViewMode</key>\s*<integer>\d+</integer>','<key>browserViewMode</key><integer>0</integer>'

$out=Join-Path $root 'relaxed.seb'
$raw=[Text.Encoding]::UTF8.GetBytes($xml)
$ms2=New-Object IO.MemoryStream
$ms2.Write([Text.Encoding]::ASCII.GetBytes('plnd'),0,4)
$gz2=New-Object IO.Compression.GZipStream($ms2,[IO.Compression.CompressionMode]::Compress)
$gz2.Write($raw,0,$raw.Length); $gz2.Close()
[IO.File]::WriteAllBytes($out,$ms2.ToArray())
Write-Host "written: $out ($((Get-Item -LiteralPath $out).Length) bytes)" -ForegroundColor Green
Start-Process -FilePath $out
Write-Host "launched relaxed.seb" -ForegroundColor Green