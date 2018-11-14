#Get-ThresholdPassOrFail -diskfreepercent 12 -diskfreegb 10 -testmethod 15pctfree
function Get-ThresholdPassOrFail {
    param (
        [Parameter(Mandatory=$true)]
        [string]$testmethod,

        [Parameter(Mandatory=$true)]
        [single]$diskfreepercent,

        [Parameter(Mandatory=$true)]
        [single]$diskfreegb
    )

    switch ($testmethod) {
        'NA' {$Result = "PASS"}
        '5 Percent Free' { If($diskfreepercent -le 5){$Result = "FAIL"}Else{$Result = "PASS"}}
        '10 Percent Free' { If($diskfreepercent -le 10){$Result = "FAIL"}Else{$Result = "PASS"}}
        '15 Percent Free' { If($diskfreepercent -le 15){$Result = "FAIL"}Else{$Result = "PASS"}}
        '20 Percent Free' { If($diskfreepercent -le 20){$Result = "FAIL"}Else{$Result = "PASS"}}
        '30 Percent Free' { If($diskfreepercent -le 30){$Result = "FAIL"}Else{$Result = "PASS"}}
        '40 Percent Free' { If($diskfreepercent -le 40){$Result = "FAIL"}Else{$Result = "PASS"}}
        '50 Percent Free' { If($diskfreepercent -le 50){$Result = "FAIL"}Else{$Result = "PASS"}}
        '60 Percent Free' { If($diskfreepercent -le 60){$Result = "FAIL"}Else{$Result = "PASS"}}
        '70 Percent Free' { If($diskfreepercent -le 70){$Result = "FAIL"}Else{$Result = "PASS"}}
        '80 Percent Free' { If($diskfreepercent -le 80){$Result = "FAIL"}Else{$Result = "PASS"}}
        '90 Percent Free' { If($diskfreepercent -le 90){$Result = "FAIL"}Else{$Result = "PASS"}}
        '1 GB Free' { If($diskfreegb -le 1){$Result = "FAIL"}Else{$Result = "PASS"}}
        '2 GB Free' { If($diskfreegb -le 2){$Result = "FAIL"}Else{$Result = "PASS"}}
        '3 GB Free' { If($diskfreegb -le 3){$Result = "FAIL"}Else{$Result = "PASS"}}
        '5 GB Free' { If($diskfreegb -le 4){$Result = "FAIL"}Else{$Result = "PASS"}}
        '10 GB Free' { If($diskfreegb -le 10){$Result = "FAIL"}Else{$Result = "PASS"}}
        '20 GB Free' { If($diskfreegb -le 20){$Result = "FAIL"}Else{$Result = "PASS"}}
        '30 GB Free' { If($diskfreegb -le 30){$Result = "FAIL"}Else{$Result = "PASS"}}
        '40 GB Free' { If($diskfreegb -le 40){$Result = "FAIL"}Else{$Result = "PASS"}}
        '50 GB Free' { If($diskfreegb -le 50){$Result = "FAIL"}Else{$Result = "PASS"}}
        '100 GB Free' { If($diskfreegb -le 100){$Result = "FAIL"}Else{$Result = "PASS"}}
        '200 GB Free' { If($diskfreegb -le 200){$Result = "FAIL"}Else{$Result = "PASS"}}
        '300 GB Free' { If($diskfreegb -le 300){$Result = "FAIL"}Else{$Result = "PASS"}}
        '400 GB Free' { If($diskfreegb -le 400){$Result = "FAIL"}Else{$Result = "PASS"}}
        '500 GB Free' { If($diskfreegb -le 500){$Result = "FAIL"}Else{$Result = "PASS"}}
        '800 GB Free' { If($diskfreegb -le 800){$Result = "FAIL"}Else{$Result = "PASS"}}
        '1000 GB Free' { If($diskfreegb -le 1000){$Result = "FAIL"}Else{$Result = "PASS"}}
        '1500 GB Free' { If($diskfreegb -le 1500){$Result = "FAIL"}Else{$Result = "PASS"}}
        '2000 GB Free' { If($diskfreegb -le 2000){$Result = "FAIL"}Else{$Result = "PASS"}}
        default { 'PASS' }
    }

    return $result
    
}

Function Get-DiskHistoryLog
{
    param(
        $IndividualDisk
    )
    $FileExists = ""

    $path = "C:\Windows\LTSVC\DiskHistoryLogs"
    If (!(test-path $path)) {
        New-Item -ItemType Directory -Force -Path $path
    }

    $TempLetterVar = $($disk.DeviceID).Replace(":","")
    $DiskSizeInMegabytes = $([math]::Round($Disk.size / 1024 / 1024))

    $PathToIndividualGrowthLog = "C:\Windows\LTSVC\DiskHistoryLogs\$TempLetterVar-$DiskSizeInMegabytes.txt"
    $CurrentDateTimeCorrectFormat = Get-Date -Format "MM-dd-yyyy"
    $FreeSpaceToAdd = $([math]::Round($IndividualDisk.FreeSpace / 1024 / 1024 / 1024))

    If(Test-Path $PathToIndividualGrowthLog )
    {
        $FileExists = $true
    }
    else {
        $FileExists = $false
    }

    $DiskArray = @()
    if ($FileExists) {
        Add-Content -Path $PathToIndividualGrowthLog -Value "$CurrentDateTimeCorrectFormat,$FreeSpaceToAdd"
    }

    if (!$FileExists) {
        New-Item -Path $PathToIndividualGrowthLog -ItemType File | Out-Null
    }
        
    $DiskHistoryLogContent = Get-Content $PathToIndividualGrowthLog

    $NumberOfEntries = $DiskHistoryLogContent | Measure-Object | Select-Object -ExpandProperty Count

    #We need another in here to actually make some progress
    if ($NumberOfEntries -gt 30) {
        foreach ($Line in $DiskHistoryLogContent) {
            $LineData = $Line -split(',')
            $Date = $LineData[0]
            $DateConverted =[datetime]::ParseExact($Date, "MM-dd-yyyy", $null)
            $FreeInGigabytes = $LineData[1]
    
            $myHashtable = @{
                Date    = $Date
                FreeInGigabytes = $FreeInGigabytes
                DaysSince = $(New-TimeSpan -Start $DateConverted -End $(Get-Date).Date).Days
            }
            $myObject = New-Object -TypeName PSObject -Property $myHashtable
            $DiskArray += $myObject
        }
    
        
        #Get Maximum Days Value and try calculate a date
        $MaxDayDifference = ($DiskArray  | measure-object -Property DaysSince -maximum).maximum
        $MinDayDifference = ($DiskArray  | measure-object -Property DaysSince -Minimum).Minimum
        $TotalDayDifference = ($MaxDayDifference-$MinDayDifference)
        $FreeSpaceAtOldestDate = $DiskArray | Where-Object {$_.DaysSince -eq $MaxDayDifference} | Select-Object -first 1 -ExpandProperty FreeInGigabytes
        $FreeSpaceAtNewestDate = $DiskArray | Where-Object {$_.DaysSince -eq $MinDayDifference} | Select-Object -first 1 -ExpandProperty FreeInGigabytes
        $TotalFreeDifference = ($FreeSpaceAtOldestDate-$FreeSpaceAtNewestDate)
        $DailyRateOfChangeInGB = $TotalFreeDifference / $TotalDayDifference
        $NumberOfDaysUntilPancaked = [math]::Round($FreeInGigabytes / $DailyRateOfChangeInGB)
    
        if (($NumberOfDaysUntilPancaked -lt 1) -or ($NumberOfDaysUntilPancaked -eq [System.Double]::PositiveInfinity) -or ($NumberOfDaysUntilPancaked -eq 'NaN') ) {
            Write-Output "Negative or No Growth"
        }
        else {
            $DateOfPancake = (Get-Date).AddDays($NumberOfDaysUntilPancaked)
            Write-Output "Date Full: $DateOfPancake"
        }
    }
    else {
        Write-Output "Not Enough Data Points Yet"
    }

}

Function Get-DiskAlerts
{
    param(
    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diska,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diskb,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diskc,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diskd,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diske,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diskf,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diskg,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diskh,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diski,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diskj,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diskk,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diskl,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diskm,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diskn,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$disko,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diskp,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diskq,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diskr,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$disks,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diskt,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$disku,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diskv,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diskw,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diskx,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$disky,

    [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [AllowEmptyString()]
    [string]$diskz
    )

    $DisksWMI = get-WmiObject win32_logicaldisk
    $ResultArray = @()

    foreach ($disk in $diskswmi)
    {
        $DiskPercentageFree = ""
        $DiskFreeGB = ""
        $DiskUsedActual = ""
        $TempLetterVar = ""
        $TestFinal = ""
        $ErrorToDisplay = ""

        $DiskUsedActual = $disk.size - $disk.FreeSpace
        $DiskPercentageFree = [math]::Round(($Disk.FreeSpace / $disk.size) * 100)
        $DiskFreeGB = $([math]::Round($Disk.FreeSpace / 1024 / 1024 / 1024))
        $TempLetterVar = $($disk.DeviceID).Replace(":","")
        $ToUse = Get-Variable "disk$TempLetterVar" -ValueOnly

        $TestFinal = Get-ThresholdPassOrFail -testmethod $ToUse -diskfreepercent $DiskPercentageFree -diskfreegb $DiskFreeGB

        Get-DiskHistoryLog -IndividualDisk $disk

        if ($TestFinal -eq 'PASS') {
            $ResultArray += "$($Disk.DeviceID) - $TestFinal"
        }
        else {
            if ($ToUse -match 'gb') {
                $ErrorToDisplay = "Disk Free Space $DiskFreeGB GB"
            }
            else {
                $ErrorToDisplay = "Disk Free Percentage $DiskPercentageFree"
            }

            $ResultArray += "$($Disk.DeviceID) - $TestFinal - EDF Threshold Is $ToUse - $ErrorToDisplay"
        }
    }

Return ($ResultArray) -join ","

}

# Test Command
Get-DiskAlerts -diska "a" -diskb "b" -diskc "100 GB Free" -diskd "d" -diske "e" -diskf "f" -diskg "g" -diskh "h" -diski "i" -diskj "j" -diskk "k" -diskl "l" -diskm "m" -diskn "n" -disko "o" -diskp "p" -diskq "q" -diskr "r" -disks "s" -diskt "t" -disku "u" -diskv "v" -diskw "w" -diskx "x" -disky "y" -diskz "z"