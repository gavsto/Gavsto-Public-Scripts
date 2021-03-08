[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$EXEPath = "$Env:Temp\MSERT.exe"

function Get-MSERTExecutable {
    if (Test-Path $EXEPath) {
        # Delete the previous executable if it exists
        try {
            Write-Debug "Attempting to delete $EXEPath"
            Remove-Item $EXEPath -Force -ErrorAction Stop
        }
        catch {
            Write-Output "ERROR: Unable to delete $EXEPath, script terminating with error $($_.Exception.Message)"
            throw
        }

    }
    else {
        Write-Debug "EXE does not exist in $EXEPath - continuing"
    }

    # Get the download
    Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/?LinkId=212732' -OutFile $EXEPath
}

function Remove-MSERTDebugLog {
    if (Test-Path 'C:\Windows\Debug\msert.log') {
        try {
            Write-Debug "Attempting to delete C:\Windows\Debug\msert.log"
            Remove-Item 'C:\Windows\Debug\msert.log' -Force -ErrorAction Stop
        }
        catch {
            Write-Output "ERROR: Unable to delete the msert.log file, scripting terminating with error $($_.Exception.Message)"
            throw
        }
    }
}

function Remove-MSERTExecutable {
    if (Test-Path $EXEPath) {
        try {
            Write-Debug "Attempting to delete $EXEPath"
            Remove-Item $EXEPath -Force -ErrorAction Stop
        }
        catch {
            Write-Output "ERROR: Unable to delete $EXEPath, script terminating with error $($_.Exception.Message)"
            throw
        }

    }
}

function Start-MSERTScanner {
    $Arguments = "/Q /N"
    $proc = Start-Process $EXEPath $Arguments -PassThru
    try {
        $proc | Wait-Process -Timeout 1800 -ErrorAction Stop
    }
    catch [TimeoutException] {
        Write-Error -Message "WARNING: Microsoft security scanner took longer than 30 minutes so script terminated: $($_.Exception.Message)" -Exception $_.Exception
        throw
    }
    Write-Debug "MSERT Scanner has finished"
}

function Test-MSERTLog {
    $LogFile = Get-Content 'C:\Windows\debug\msert.log'

    if ($LogFile -like '*No Infection found.*') {
        $ScriptNoInfectionsFound = $true
    }
    else {
        $ScriptNoInfectionsFound = $false
    }
    
    if ($ScriptNoInfectionsFound) {
        return "SUCCESS: No infection found $($LogFile)"
    }
    else {
        return "CRITICAL: Potential Infections found. $($LogFile)"
    }
}

Get-MSERTExecutable
Remove-MSERTDebugLog
Start-MSERTScanner
Test-MSERTLog
Remove-MSERTExecutable
