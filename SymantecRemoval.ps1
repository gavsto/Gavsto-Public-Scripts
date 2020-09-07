$wshell = New-Object -ComObject wscript.shell
Start-Process -FilePath "C:\Windows\ltsvc\SymantecRemoval\SEPprep64.exe"
Sleep 15
$wshell.AppActivate('Symantec Endpoint Protection Cloud')
Sleep 5
$wshell.SendKeys('{TAB}')
Sleep 0.5
$wshell.SendKeys('{TAB}')
Sleep 0.5
$wshell.SendKeys('{ENTER}')
Sleep 360
get-process inststub | Foreach-Object { $_.CloseMainWindow() | Out-Null } | stop-process -force
