<#
.SYNOPSIS
  Updates Contacts on ConnectWise Manage Configurations based on matching an EDF in Automate
.DESCRIPTION
  Utilises AutomateAPI and ConnectWiseManageAPI to find matching machines, and update the contact configuration
.INPUTS
  None, but automatically pulls all Computers out of Automate, Configurations out of Manage and Contacts out of Manage
.OUTPUTS
  A single line per Automate PC as to whether it was matched or not
.NOTES
  Version:        1.0
  Author:         Gavin Stone (gavsto.com)
  Creation Date:  28th January 2021
  Purpose/Change: Initial script development
#>

# -------------------------Editable Script Variables-------------------------------
# Name of the EDF in Automate to extract from
$EDFTitle = "Email Address EDF Name"

# Will not make any changes if true, but will output what would have happened without doing anything in Manage. I recommend you start with this before flipping it to false
$WhatIfOnly = $true

# Make sure you add your connection/authentication Details
# -------------------------End of Script Variables-----------------------------

Import-Module ConnectWiseManageAPI -Force -ErrorAction Stop
Import-Module AutomateAPI -Force -ErrorAction Stop

Connect-CWM -Server $ConnectWiseManageServerURL -Company $ConnectWiseManageCompanyName -pubkey $ConnectWiseManagePublicAPIKey -privatekey $ConnectWiseManagePrivateAPIKey -clientId $ConnectWiseManageClientID
Connect-AutomateAPI -Server $ConnectWiseAutomateServerURL -ClientID $ConnectWiseAutomateClientID -Credential $AutomateCredentials

# Get all Automate Computers
try { $AllAutomateComputers = Get-AutomateComputer -ErrorAction Stop } catch { Write-Output "Failed to get all Automate Computers with error $($_.Exception.Message). This is a terminating condition."; throw }

# Get All Manage Configurations
try { $AllManageConfigurations = Get-CWMCompanyConfiguration -all -ErrorAction Stop } catch { Write-Output "Failed to get all Manage Configurations with error $($_.Exception.Message). This is a termination error."; throw }

# Get All Manage Contacts
try { $AllManageContacts = Get-CWMContact -all -ErrorAction Stop } catch { Write-Output "Failed to get all Manage Contacts with error $($_.Exception.Message). This is a terminating condition."; throw }

# Loop through each Automate Computer
foreach ($AutomateComputer in $AllAutomateComputers) {

    # Get all EDFs for this computer, this could probably be made faster by putting a condition in but conditions are flaky on the API for EDFs so I sort in PowerShell
    try { $AllEDFs = Get-AutomateApiGeneric -Endpoint "computers/$($AutomateComputer.ComputerID)/extrafields" } catch { Write-Output "Unable to get EDFs for ComputerID $($AutomateComputer.ComputerID) with Name $($AutomateComputer.ComputerName) at $($AutomateComputer.Client.Name). Skipping to Next Computer"; continue }

    # Pull out the specific EDF I want
    $EDF = $AllEDFs | Where-Object { $_.Title -eq $EDFTitle }

    # Get the e-mail address out, if it's null skip to the next computer
    if (![string]::IsNullOrEmpty($EDF.TextFieldSettings.Value)) {
        $EmailAddress = $EDF.TextFieldSettings.Value
    }
    else {
        Write-Output "No E-mail address for ComputerID $($AutomateComputer.ComputerID) with Name $($AutomateComputer.ComputerName) at $($AutomateComputer.Client.Name). Skipping to Next Computer"
        continue
    }

    # Find the Match
    $Configuration = $AllManageConfigurations | ? { $_.DeviceIdentifier -eq $AutomateComputer.ComputerID }

    # Check there are not multiple devices, if there are skip this loop
    If ($Configuration.Count -gt 1) { Write-Output "Multiple configurations utilising the same DeviceIdentifier In Manage for $($AutomateComputer.ComputerID) with Name $($AutomateComputer.ComputerName) at $($AutomateComputer.Client.Name). Skipping this computer. "; continue }

    # Check there is an actual match
    If ([string]::IsNullOrEmpty($Configuration.id)) { Write-Output "Unable to find a matching configuration for $($AutomateComputer.ComputerID) with Name $($AutomateComputer.ComputerName) at $($AutomateComputer.Client.Name). Skipping to next"; continue }

    # Lets find the matching contact
    $MatchingContact = $AllManageContacts | ? { $_.communicationitems.Value -eq $EmailAddress } | Select -First 1

    # Update the Contact on the configuration in Manage
    if (![string]::IsNullOrEmpty($MatchingContact.id)) {
        try {
            if (!$WhatIfOnly) {
                $Result = Update-CWMCompanyConfiguration -ID $Configuration.id -Operation replace -Path contact -Value @{'id' = $MatchingContact.id }
                Write-Output "Manage Contact Update Attempted: $($Result.Name) was updated with contact $($MatchingContact.firstName) $($MatchingContact.lastName) with Email Address $EmailAddress" 
            }
            else {
                Write-Host -BackgroundColor Green -ForegroundColor Black "WHAT IF ONLY: We would have attempted to update Manage Configuration $($Configuration.Name) with contact $EmailAddress"
            } 


        }
        catch {
            Write-Output "There was an error when attempting to update a contact on $($AutomateComputer.ComputerID) with Name $($AutomateComputer.ComputerName) at $($AutomateComputer.Client.Name). Error thrown was $($_.Exception.Message)"
        }
    }
    else {
        Write-Output "No matching contact found. The EDF Value was $EmailAddress and this could not be found on any Manage Contact"
    }
}



