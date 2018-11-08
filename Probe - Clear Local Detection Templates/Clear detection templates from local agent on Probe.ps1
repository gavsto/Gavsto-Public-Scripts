# "%windir%\system32\WindowsPowerShell\v1.0\powershell.exe" "(new-object Net.WebClient).DownloadString('https://bit.ly/2qAOG0V') | iex;

# Stop the services
Stop-Service -Name "LTSvcMon" -Force
Stop-Service -Name "LTService" -Force

# Remove registry keys
Remove-Item -Path "HKLM:\Software\LabTech\ProbeService\CollectionTemplates" -Recurse
Remove-Item -Path "HKLM:\Software\LabTech\ProbeService\DeviceLibrary" -Recurse
Remove-Item -Path "HKLM:\Software\LabTech\ProbeService\DetectionTemplates" -Recurse
Remove-Item -Path "HKLM:\Software\LabTech\Service\CollectionTemplates" -Recurse
Remove-Item -Path "HKLM:\Software\LabTech\Service\DeviceLibrary" -Recurse
Remove-Item -Path "HKLM:\Software\LabTech\Service\DetectionTemplates" -Recurse

# Remove local files
Remove-Item -Path "C:\Windows\LTSVC\Configs.gz" -Force
Remove-Item -Path "C:\Windows\LTSVC\databases\Datacollectors.db" -Force

# Start Services
Start-Service -Name "LTSvcMon"
Start-Service -Name "LTService"
