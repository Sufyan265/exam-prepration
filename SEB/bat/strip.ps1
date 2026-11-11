param($In,$Out)
$t=Get-Content $In -Raw
$t=$t -replace '<key>hashedQuitPassword</key>\s*<string>[0-9a-fA-F]{64}</string>',''
$t=$t -replace '<key>quitPassword</key>\s*<string>[0-9a-fA-F]{64}</string>',''
$t=$t -replace '<key>passwordSalt</key>\s*<string>[^<]*</string>',''
$t | Set-Content $Out
"written: $Out"