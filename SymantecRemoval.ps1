$wshell = New-Object -ComObject wscript.shell
Start-Process -FilePath "C:\Windows\ltsvc\SymantecRemoval\SEPprep64.exe"
Sleep 10
$wshell.AppActivate('Symantec Endpoint Protection Cloud')
#$wshell.AppActivate('Untitled - notepad')
Sleep 2
$wshell.SendKeys('{TAB}')
Sleep 0.5
$wshell.SendKeys('{TAB}')
Sleep 0.5
$wshell.SendKeys('{ENTER}')
Sleep 60
$wshell.AppActivate('Symantec Endpoint Protection Cloud')
Sleep 0.5
$wshell.SendKeys('{TAB}')
Sleep 0.5
$wshell.SendKeys('{ENTER}')
