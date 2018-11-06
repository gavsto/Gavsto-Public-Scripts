#*=============================================================================
#* Script Name: getServerUptime
#* Created: 9/15/2011
#* Author: James Keeler
#* Changed by: Gavin Stone - gavsto.com
#* Email: James.R.Keeler(at)gmail.com
#*
#* Params:	[string]$ComputerName - name of the remote computer. If no parameter
#*				is given, the default is localhost
#*
#*			[int]$NumOfDays - number of days for which to calculate the 
#*				uptime.  If no parameter is given, the default is 30 days. The
#*				maximum number of days allowed is 365.
#*
#*			[switch]$DebugInfo - turns on debugging
#*
#* Returns:	The percent downtime and uptime for the given server.
#*=============================================================================
#* Purpose: Calculates the percent uptime for the given server.
#*
#*
#*=============================================================================

#*=============================================================================
#* REVISION HISTORY
#*=============================================================================
#* Version:		1.1
#* Date: 		9/27/2011
#* Time: 		5:37 PM
#* Issue: 		Not calculating downtime properly for system crashes
#* Solution:	Iterate through all event logs to find the last event written
#*				prior to crash. Use this timestamp to determine outage duration.
#*
#*=============================================================================
#* Version:		1.2
#* Date: 		11/30/2011
#* Time: 		8:27 AM
#* Issue: 		Script performance
#* Solution:	Use Invoke-Command to remotely call Get-EventLog
#*
#* Issue: 		Script accuracy
#* Solution:	Changed the script to use the system generated error message
#*				for unexpected shutdowns to capture the correct timestamp.
#*
#*=============================================================================
#* Version:		1.3
#* Date: 		01/13/2018
#* Time: 		21:27 PM
#* Issue: 		Output in parameters suitable for collection to EDF
#* Solution:	Changed the script to use the system generated error message
#*				for unexpected shutdowns to capture the correct timestamp.
#*
#*=============================================================================

#*=============================================================================
#* SCRIPT BODY
#*=============================================================================

<#
.SYNOPSIS
	Calculates the percent uptime for the given server.

.DESCRIPTION
	The getServerUpTime script returns the uptime for a remote or local 
	computer.
	
	Without parameters, getServerUptime returns the uptime for the local 
	computer over the past 30 days.
	
.PARAMETER ComputerName
	Calculates the percent uptime for the specified computers. The default is 
	the local computer.

	Type the NetBIOS name, an IP address, or a fully qualified domain name of 
	a computer. To specify the local computer, type the computer name, a dot 
	(.), or "localhost".
	
.PARAMETER NumberOfDays
	The function will calculate the uptime of the computer for the past N days,
	where N equals the value of NumberOfDays.
	
.PARAMETER DebugInfo
	Turn on debugging.
	
.EXAMPLE
	PS C:\> .\getServerUptime.ps1
	Retrieving shutdown and startup events from MyLaptop for the past 30 days...
	WARNING: This could take several minutes!
	
	Name            : MyLaptop
	NumOfDays       : 30
	NumOfCrashes    : 1
	NumOfReboots    : 18
	MinutesDown     : 12,506.03
	MinutesUp       : 30,693.97
	PercentDowntime : 28.9492 %
	PercentUptime   : 71.0508 %
	
.EXAMPLE
	PS C:\> .\getServerUptime.ps1 -ComputerName SVR001 -NumberOfDays 365
	Retrieving shutdown and startup events from SVR001 for the past 365 days...
	WARNING: This could take several minutes!
	
	Name            : SVR001
	NumOfDays       : 365
	NumOfCrashes    : 1
	NumOfReboots    : 13
	MinutesDown     : 63.15
	MinutesUp       : 525,536.85
	PercentDowntime : 0.0120 %
	PercentUptime   : 99.9880 %

#>
   	Param(
      	[string] $ComputerName = $env:computername,
      	[int] $NumberOfDays = 30,
      	[switch] $DebugInfo
	)
	Process {
		# Ensure the server is reachable

        # Create an empty hashtable to start holding the Automate Output
        $automateFinalOutput = @{}
		if (Test-Connection -ComputerName $ComputerName -Count 1 -TimeToLive 10 -Quiet) {
		
			# Ensure that this is a Windows server that we are working with and 
			# that we have the appropriate permissions
			if (Test-Path -Path "\\$ComputerName\C$") 
			{
				# Did the user pass in an appropriate value for number of days?
				# If not, we will assume the default, 30 days.  If the value is
				# more than 365, we use 365 as the maximum.
				if ($NumberOfDays -le 0) 
				{
					$NumberOfDays = 30
					$automateFinalOutput.CapturedOutput += "Defaulting to 30 days..."
				} # end if
				elseif ($NumberOfDays -gt 365) 
				{
					$NumberOfDays = 365
					$automateFinalOutput.CapturedOutput += "Using maximum value (365 days)..."
				} # end elseif
				
				# If the -debug switch is set, we set the $DebugPreference variable
      			if($DebugInfo) { $DebugPreference = "Continue" }
      			
      			# We begin by assuming 100% uptime.  We will calculate effective 
      			# uptime by subtracting downtime from this value
				[timespan]$uptime = New-TimeSpan -Days $NumberOfDays
				[timespan]$downtime = 0
				$currentTime = Get-Date
				$startUpID = 6005
				$shutDownID = 6006
				$minutesInPeriod = $uptime.TotalMinutes
				$startingDate = (Get-Date).adddays(-$NumberOfDays)
				
				# Output some useful debugging info
				Write-Debug "Uptime:         $uptime"
				Write-Debug "Downtime:       $downtime"
				write-debug "Current time:   $currentTime"
				Write-Debug "Start time:     $startingDate"
				Write-Debug "Computer:       $ComputerName"
				
				# Warn the user that this could take a while
				$automateFinalOutput.CapturedOutput += "Retrieving shutdown and startup events from "
				$automateFinalOutput.CapturedOutput += "$ComputerName for the past $NumberOfDays days..."
				$automateFinalOutput.CapturedOutput += "This could take several minutes!"
				
				# Create a new PSSession to be used throughout the script
				
				# Remotely retrieve the events from the system event log that 
				# occurred in the past $NumberOfDays days ago
				$events = Invoke-Command -ScriptBlock {`
					param($days,$up,$down) 
					Get-EventLog `
						-After (Get-Date).AddDays(-$days) `
						-LogName System `
						-Source EventLog `
					| Where-Object { 
						$_.eventID -eq  $up `
						-OR `
						$_.eventID -eq $down }
				} -ArgumentList $NumberOfDays,$startUpID,$shutDownID -ErrorAction Stop
				
				# Create a new sorted array object
				$sortedList = New-object system.collections.sortedlist
				
				# If there are shutdown or startup events, add them to the 
				# sorted array, otherwise add zeroes to the array as placeholders
				if ($events.Count -ge 1) 
				{
					ForEach($event in $events)
					{
						$sortedList.Add( $event.timeGenerated, $event.eventID )
					} #end foreach event
				} # end if
				else 
				{ # There were no shutdown events during this time period
					$sortedList.Add( 0, 0 )
				} # end else
				
				# Count the number of system crashes
				$crashCounter = 0
				
				# Count the number of reboots
				$rebootCounter = 0
				
				# Iterate through the sorted events and add up the downtime
				For($i = 1; $i -lt $sortedList.Count; $i++ )
				{ 
					if(	`
						($sortedList.GetByIndex($i) -eq $startupID) `
						-AND `
						($sortedList.GetByIndex($i) -ne $sortedList.GetByIndex($i-1)) ) 
					{ # There was a shutdown event paired to the startup event, 
					  # thus it was a planned shutdown
					  
						# Write each event to the Debug pipeline
						Write-Debug "Shutdown `t $($sortedList.Keys[$i-1])" # Shutdown
						Write-Debug "Startup  `t $($sortedList.Keys[$i])" # Startup
						
						# Outage duration = startup timestamp - shutdown timestamp
						$duration = ($sortedList.Keys[$i] - $sortedList.Keys[$i-1])
						$downtime += $duration
						Write-Debug "           Outage duration: $duration"
						Write-Debug "           Downtime is now: $downtime"
						Write-Debug ""
						
						# Bump the reboot counter
						$rebootCounter++
					} # end if
					elseif(	`
						($sortedList.GetByIndex($i) -eq $startupID) `
						-AND `
						($sortedList.GetByIndex($i) -eq $sortedList.GetByIndex($i-1)) )
					{ 	# This was an unplanned outage (a system crash). 
						# Basically this means that we have 2 startup events 
						# with no shutdown event
												
						# Get the date from the event stating that there was an
						# unexpected shutdown
						$tempevent = Invoke-Command `
							-ScriptBlock {`
								param([datetime]$date, [string]$log)
								Get-EventLog `
									-Before $date.AddSeconds(1) `
									-Newest 1 `
									-LogName System `
									-Source EventLog `
									-EntryType Error `
									-ErrorAction "SilentlyContinue" | `
								Where-Object {$_.EventID -eq 6008}
							} -ArgumentList $sortedList.Keys[$i],$($eventlog.log)
						
						# The 6008 event has the data we're looking for in the 
						# ReplacementStrings property but the date portion of the
						# data has a special character that we need to remove,
						# [char]8206, so we replace it with a space.
						$lastEvent = [datetime](`
							($tempevent.ReplacementStrings[1]).Replace([char]8206, " ")`
							+ " " + $tempevent.ReplacementStrings[0])
						
						# Write each event to the Debug pipeline
						Write-Debug "CRASH    `t $lastEvent"
						Write-Debug "Startup  `t $($sortedList.Keys[$i])" # Startup
						
						# Calculate downtime = Startup timestamp - Last event 
						# written to any log timestamp
						$duration = ($sortedList.Keys[$i] - $lastEvent)
						$downtime += $duration
						Write-Debug "           Outage duration: $duration"
						Write-Debug "           Downtime is now: $downtime"
						Write-Debug ""
						
						# Bump the crash counter
						$crashCounter++						
					} # end elseif
				} #end for item
				
				# Subtract downtime from calculated uptime to get true uptime
				$uptime -= $downtime
				
				# Create a custom object to hold the results
				$results = "" | Select-Object `
					Name, `
					NumOfDays, `
					NumOfCrashes, `
					NumOfReboots, `
					MinutesDown, `
					MinutesUp, `
					PercentDowntime, `
					PercentUptime
				$results.Name = $ComputerName
				$results.NumOfDays = $NumberOfDays
				$results.NumOfCrashes = $crashCounter
				$results.NumOfReboots = $rebootCounter
				$results.MinutesDown = $downtime.TotalMinutes
				$results.MinutesUp = $uptime.TotalMinutes
				$results.PercentDowntime = "{0:p4}" -f (1 - $uptime.TotalMinutes/$minutesInPeriod)
				$results.PercentUptime = "{0:p4}" -f ($uptime.TotalMinutes/$minutesInPeriod)

                $automateFinalOutput.Name = $results.Name 
                $automateFinalOutput.NumOfDays = $results.NumOfDays
                $automateFinalOutput.NumOfCrashes = $results.NumOfCrashes
                $automateFinalOutput.NumOfReboot = $results.NumOfReboots
                $automateFinalOutput.MinutesDown = [math]::Round($results.MinutesDown)
                $automateFinalOutput.MinutesUp = [math]::Round($results.MinutesUp)
                $automateFinalOutput.PercentDownTime = $results.PercentDowntime
                $automateFinalOutput.PercentUpTime = $results.PercentUptime
                
                $finalOutput = [string]::Join("|",($automateFinalOutput.GetEnumerator() | %{$_.Name + "=" + $_.Value}))
                $finalOutput = $finalOutput.Replace("True","1")
                $finalOutput = $finalOutput.Replace("False","0")
                Write-Host $finalOutput
				
				#Write-Output $results				

      		} # end if
      		else 
      		{
      			# This usually means that you've encountered a server that 
      			# is not running Windows, like a Linux server
      			$automateFinalOutput.CapturedOutput += "No access to the default share - \\$ComputerName\C`$"
      		} # end else
      	} # end if
      	else 
      	{ # This server is not online
      		$automateFinalOutput.CapturedOutput += "Unable to connect - $ComputerName"
      	} #end else
    } # end Process

#*=============================================================================
#* END OF SCRIPT: getServerUptime
#*=============================================================================

