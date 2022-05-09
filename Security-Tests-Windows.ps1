# Script Author: Gavin Stone (Gavsto.com)
# Script Date: 9th May 2022

# Check SMBV1 is Disabled
try {
    $SMB1Result = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol | Select -ExpandProperty State
}
catch {
    Write-Output "WARNING: Unable to run Get-WindowsOptionalFeature with Error: $($Exception.Message)"
}

If ($SMB1Result -eq "Disabled") { Write-Output "PASS: SMB1 is Disabled" } else { Write-Output "FAIL: SMB1 is $($SMB1Result)" }

# Check PowerShell 2 is Disabled
try {
    $PowerShell2Result = Get-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root | Select -ExpandProperty State
}
catch {
    Write-Output "WARNING: Unable to run Get-WindowsOptionalFeature with Error: $($Exception.Message)"
}

If ($PowerShell2Result -eq "Disabled") { Write-Output "PASS: PowerShell 2 is Disabled" } else { Write-Output "FAIL: PowerShell 2 is $($PowerShell2Result)" }

# Check WDigest Explicitly Disabled
$WDigestResult = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\Wdigest"
If ($WDigestResult.UseLogonCredential -eq 0) { Write-Output "PASS: WDigest is Explicitly Disabled" }else { Write-Output "FAIL: WDigest is not explicitly disabled" }

# Check NTLMV2 is response only and refuse LM and NTLM
$NTLMV2Result = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\LSA"
If ($NTLMV2Result.LmCompatabilityLevel -eq 5) { Write-Output "PASS: LM and NTLM are Refused" }else { Write-Output "FAIL: LM and NTLM are not refused or policy is not set to NTLMv2 response only" }

# Check Attack Surface Reduction Rules are present for Windows Defender
$ASRResult = Get-MPPreference | Select-Object -ExpandProperty AttackSurfaceReductionRules_Ids
If ([string]::IsNullOrEmpty($ASRResult)) { Write-Output "FAIL: No Attack Surface Reduction Rules Found" }else { Write-Output "PASS: Attack Surface Reduction Rules Found" }

# Check Secure Boot is Enabled
If (Confirm-SecureBootUEFI) { Write-Output "PASS: Secure boot is Enabled" }else { Write-Output "FAIL: Secure boot (UEFI) is not Enabled" }

# Check RDP is Disabled
$RDPResult = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" | Select-Object -ExpandProperty fDenyTSConnections
If ($RDPResult -eq 1) { Write-Output "PASS: RDP is Disabled" }else { Write-Output "FAIL: RDP is Enabled" }

# Check LLMNR is Disabled
try {
    $LLMNRResult = Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -ErrorAction Stop
    If ($LLMNRResult.EnableMultiCast -eq 0) { Write-Output "PASS: LLMNR is Disabled" }else { Write-Output "FAIL: LLMNR not explicitly disabled" }
}
catch {
    Write-Output "FAIL: LLMNR not explicitly disabled"
}

# Ensure NETBIOS is disabled on all adapters
$i = 'HKLM:\SYSTEM\CurrentControlSet\Services\netbt\Parameters\interfaces'
$NetbiosCountResult = 0
Get-ChildItem $i | ForEach-Object {  
    $NetBiosInterimResult = Get-ItemProperty -Path "$i\$($_.pschildname)" | Select-Object -ExpandProperty NetbiosOptions
    If ($NetBiosInterimResult -ne 2) { $NetbiosCountResult++ }
}
If ($NetbiosCountResult -gt 0) { Write-Output "FAIL: $NetbiosCountResult adapter(s) have Netbios Enabled" } else { Write-Output "PASS: All adapters have Netbios Disabled" }

# Check Firewall is Enabled and On
$content = netsh advfirewall show allprofiles
If ($domprofile = $content | Select-String 'Domain Profile' -Context 2 | Out-String) { $domainpro = ($domprofile.Substring($domprofile.Length - 9)).Trim() }
Else { $domainpro = $null }
If ($priprofile = $content | Select-String 'Private Profile' -Context 2 | Out-String) { $privatepro = ($priprofile.Substring($priprofile.Length - 9)).Trim() }
Else { $privatepro = $null }
If ($pubprofile = $content | Select-String 'Public Profile' -Context 2 | Out-String) { $publicpro = ($pubprofile.Substring($pubprofile.Length - 9)).Trim() }
Else { $publicpro = $null }
$FirewallObject = New-Object PSObject
Add-Member -inputObject $FirewallObject -memberType NoteProperty -name "FirewallDomain" -value $domainpro
Add-Member -inputObject $FirewallObject -memberType NoteProperty -name "FirewallPrivate" -value $privatepro
Add-Member -inputObject $FirewallObject -memberType NoteProperty -name "FirewallPublic" -value $publicpro
If (($FirewallObject.FirewallDomain -eq 'ON') -and ($FirewallObject.FirewallPrivate -eq 'ON') -and ($FirewallObject.FirewallPublic -eq 'ON') ) {
    Write-Output "PASS: Firewall is Enabled and Configured for All Profiles"
}
else {
    Write-Output "FAIL: One or more of the firewall profiles is off or not configured. FirewallDomain: $($FirewallObject.FirewallDomain), FirewallPrivate: $($FirewallObject.FirewallPrivate), FirewallPublic: $($FirewallObject.FirewallPublic)"
}

# Check default inbound rule on the Firewall is Blocked
Function Test-CommandExists {
    Param ($command)

    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try { if (Get-Command $command) { RETURN $true } }
    Catch { RETURN $false }
    Finally { $ErrorActionPreference = $oldPreference }
}

$cmdName = "Get-NetFirewallProfile"

if (Test-CommandExists $cmdName) {
    $ResultsFirewallDefaultBlock = Get-NetFirewallProfile
    $ReturnFirewallDefaultBlock = ($ResultsFirewallDefaultBlock | % { "{0}={1}" -f $_.name, $_.DefaultInboundAction }) -join ','
}
else {
    $ReturnFirewallDefaultBlock = "Off/Error or Windows 7 Machine"
}

If (($ReturnFirewallDefaultBlock -like '*NotConfigured*') -or ($ReturnFirewallDefaultBlock -like '*Allow*')) {
    Write-Output "FAIL: One or more of the profiles does not have a default inbound action to be block on the Firewall. $($ReturnFirewallDefaultBlock)"
}
else {
    Write-Output "PASS: All Default inbound rules are set to Block"
}

# Check C Drive is Encrypted
$BitlockerVolumes = Get-BitlockerVolume | ? { $_.MountPoint -eq 'C:' }
if (($BitlockerVolumes | Measure-Object | Select-Object -ExpandProperty Count) -eq 0) { Write-Output "FAIL: C Drive Not Encrypted" } else { Write-Output "PASS: C Drive Encryption Available" }

# Check C Drive has Active Encryption and is not decrypted
if ($BitlockerVolumes.VolumeStatus -ne 'FullyEncrypted') { Write-Output "FAIL: Mount Point C: is not Fully Encrypted, it has a state of $($BitlockerVolumes.VolumeStatus)" } else { Write-Output "PASS: C Drive is actively Encrypted" }

# Check C Drive Encryption is Appropriately Secure Cryptographically
if ($BitlockerVolumes.EncryptionMethod -ne 'XtsAES256') { Write-Output "FAIL: Encryption method is not XtsAES256 and is $($BitlockerVolumes.EncryptionMethod)" }else { Write-Output "PASS: Encryption Method on C is XtsAES256" }

# Check for Unused Local Accounts
$Results = Get-LocalUser | ? { ($_.Name -ne 'Administrator') -and ($_.Name -ne 'DefaultAccount') -and ($_.Name -ne 'defaultuser0') -and ($_.Name -ne 'Guest') -and ($_.Name -ne 'WDAGUtilityAccount') } | ? { $_.LastLogon -le (Get-Date).AddDays(-30) }
if (($Results | Measure-Object | Select-Object -ExpandProperty Count) -ge 1) {
    Write-Output "FAIL: Local Accounts are present that have not been logged in in over 30 days. $(($Results.Name) -join ',')"
}
Else {
    Write-Output 'PASS: All Local Accounts are either utilised or are system accounts'
}

# Check Autorun is Disabled
$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $env:COMPUTERNAME)
$regKey = $reg.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer')
If ($regKey) { $keyVal = $regKey.GetValue('NoDriveTypeAutoRun') }
Try { $regKey.Close() } Catch { }
$reg.Close()
If ([string]::IsNullOrEmpty($keyVal) -eq $false) { If ($keyVal -eq '255') { Write-Output 'PASS: Autorun is disabled' }Else { Write-Output 'FAIL: Autorun is enabled' } }Else { Write-Output 'FAIL: Autorun is enabled' }
