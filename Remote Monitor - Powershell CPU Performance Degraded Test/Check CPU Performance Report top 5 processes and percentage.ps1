"%windir%\System32\WindowsPowerShell\v1.0\powershell.exe" -noprofile -command "& {$CPUTotalErrorThreshold=70;[int]$hour = get-date -format HH;If($hour -lt 8 -or $hour -gt 17){$InBusinessHours = $false}Else{$InBusinessHours = $true};$CpuCores = (Get-WMIObject Win32_ComputerSystem).NumberOfLogicalProcessors;$CPUValues = (Get-Counter \"\Process(*)\% Processor Time\" -ErrorAction SilentlyContinue).CounterSamples  | Select InstanceName, @{Name=\"CPU\";Expression={[Decimal]::Round(($_.CookedValue / $CpuCores), 2)}} | where-object {($_.InstanceName -ne '_total') -and ($_.InstanceName -ne 'idle')} | sort cpu -Descending | select -First 5;$Total = ($CPUValues | Measure-Object 'CPU' -Sum).Sum;$ErrorNames = ($CPUValues | Select -ExpandProperty InstanceName) -join ',';$ErrorValues = ($CPUValues | Select -ExpandProperty CPU) -join ',';if (($total -gt $CPUTotalErrorThreshold) -and ($InBusinessHours)){Write-Output \"Error Top Processes Are $ErrorNames that uses $ErrorValues % respectively\"}Else{Write-Output \"$Total % - CPU Healthy\"};  }"








