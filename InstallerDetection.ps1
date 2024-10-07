<#
.SYNOPSIS
    WPF Application to analyze an installer and determine its packaging technology and subsequently its silent switches.

.DESCRIPTION
    This script creates a WPF GUI application that lets the user select an executable or MSI file.
    It then analyzes the file to detect the installer type and displays the result along with
    the silent install switches for that installer type.

.NOTES
    Author: Gavin Stone + OpenAI's ChatGPT
    Date: 7th October 2024
#>

Add-Type -AssemblyName PresentationFramework

# XAML UI Definition
$XAML = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Installer Analyzer" Height="400" Width="600" ResizeMode="NoResize">
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>

        <TextBlock Text="Select an installer file (.exe or .msi):" Grid.Row="0" Grid.Column="0" Grid.ColumnSpan="2" FontWeight="Bold" Margin="0,0,0,5"/>
        <TextBox Name="txtFilePath" Grid.Row="1" Grid.Column="0" IsReadOnly="True" Margin="0,0,5,0"/>
        <Button Name="btnBrowse" Content="Browse..." Grid.Row="1" Grid.Column="1" Width="75"/>
        <TextBlock Text="Analysis Result:" Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="2" FontWeight="Bold" Margin="0,10,0,5"/>
        <TextBox Name="txtResult" Grid.Row="2" Grid.Column="0" Grid.ColumnSpan="2" AcceptsReturn="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" IsReadOnly="True" Height="200"/>
        <Button Name="btnAnalyze" Content="Analyze" Grid.Row="3" Grid.Column="0" Grid.ColumnSpan="2" Height="30" Margin="0,10,0,0"/>
    </Grid>
</Window>
"@

# Load the XAML
[xml]$XAMLReader = $XAML
$reader = New-Object System.Xml.XmlNodeReader $XAMLReader
$Window = [Windows.Markup.XamlReader]::Load($reader)

# Access UI Elements
$txtFilePath = $Window.FindName("txtFilePath")
$btnBrowse = $Window.FindName("btnBrowse")
$txtResult = $Window.FindName("txtResult")
$btnAnalyze = $Window.FindName("btnAnalyze")

# Browse Button Click Event
$btnBrowse.Add_Click({
    $dialog = New-Object Microsoft.Win32.OpenFileDialog
    $dialog.Filter = "Installer Files (*.exe;*.msi)|*.exe;*.msi|All Files (*.*)|*.*"
    $dialog.Title = "Select an Installer File"
    if ($dialog.ShowDialog()) {
        $txtFilePath.Text = $dialog.FileName
        $txtResult.Text = ""
    }
})

# Analyze Button Click Event
$btnAnalyze.Add_Click({
    $FilePath = $txtFilePath.Text
    if (-not (Test-Path -Path $FilePath)) {
        [System.Windows.MessageBox]::Show("Please select a valid installer file.", "File Not Found", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
        return
    }

    # Initialize findings and silent switches using lists
    $findings = [System.Collections.Generic.List[string]]::new()
    $silentSwitches = [System.Collections.Generic.List[string]]::new()

    # Get file extension
    $fileExtension = [System.IO.Path]::GetExtension($FilePath).ToLower()

    # Silent install switches for installers
    $silentSwitchesDict = @{
        "Inno Setup"                       = "Silent Install Switches: /SILENT or /VERYSILENT"
        "NSIS"                             = "Silent Install Switch: /S"
        "InstallShield"                    = "Silent Install Switch: /S or /SILENT"
        "WiX"                              = "Silent Install Switches: /quiet or /qn"
        "WiX Standard Bootstrapper"        = "Silent Install Switches: /quiet or /passive"
        "7-Zip SFX"                        = "May not support silent install switches."
        "Advanced Installer"               = "Silent Install Switch: /exenoui /qn"
        "Wise Installer"                   = "Silent Install Switch: /S"
        "SFXCAB"                           = "May not support silent install switches."
        "MSI Installer"                    = "Silent Install Switches: /quiet or /qn"
    }

    $installerDetected = $false

    if ($fileExtension -eq ".msi") {
        # MSI File Detected
        $findings.Add("MSI Installer package detected based on file extension.")
        if ($silentSwitchesDict.ContainsKey("MSI Installer")) {
            $silentSwitches.Add($silentSwitchesDict["MSI Installer"])
        }
        $installerDetected = $true
    } else {
        # Process executable files
        # Get file version info
        try {
            $versionInfo = (Get-Item -Path $FilePath).VersionInfo
        } catch {
            # Ignore errors
        }

        # Check version info for clues
        if ($versionInfo) {
            if ($versionInfo.ProductName -match "Inno Setup") {
                $findings.Add("Inno Setup installer detected via ProductName.")
                if ($silentSwitchesDict.ContainsKey("Inno Setup")) {
                    $silentSwitches.Add($silentSwitchesDict["Inno Setup"])
                }
                $installerDetected = $true
            }
            if ($versionInfo.CompanyName -match "Nullsoft") {
                $findings.Add("NSIS installer detected via CompanyName.")
                if ($silentSwitchesDict.ContainsKey("NSIS")) {
                    $silentSwitches.Add($silentSwitchesDict["NSIS"])
                }
                $installerDetected = $true
            }
            if ($versionInfo.ProductName -match "InstallShield") {
                $findings.Add("InstallShield installer detected via ProductName.")
                if ($silentSwitchesDict.ContainsKey("InstallShield")) {
                    $silentSwitches.Add($silentSwitchesDict["InstallShield"])
                }
                $installerDetected = $true
            }
            if ($versionInfo.ProductName -match "WiX Toolset") {
                $findings.Add("WiX installer detected via ProductName.")
                if ($silentSwitchesDict.ContainsKey("WiX")) {
                    $silentSwitches.Add($silentSwitchesDict["WiX"])
                }
                $installerDetected = $true
            }
            if ($versionInfo.InternalName -match "\.msi") {
                $findings.Add("MSI Installer package detected via InternalName.")
                if ($silentSwitchesDict.ContainsKey("MSI Installer")) {
                    $silentSwitches.Add($silentSwitchesDict["MSI Installer"])
                }
                $installerDetected = $true
            }
        }

        # Define patterns to search for in the binary content
        $patterns = @{
            "Inno Setup"                       = "Inno Setup"
            "NSIS"                             = "Nullsoft Install System"
            "InstallShield"                    = "InstallShield"
            "WiX"                              = "BootstrapperCore"
            "WiX Standard Bootstrapper"        = "WixToolset"
            "7-Zip SFX"                        = "7-Zip SFX"
            "Advanced Installer"               = "Advanced Installer"
            "Wise Installer"                   = "Wise Installation System"
            "SFXCAB"                           = "MakeCab"
            "MSI Installer"                    = "MSIEXEC"
        }

        # Read up to 10 MB of the file
        $maxBytesToRead = 10MB
        try {
            $fileStream = [System.IO.File]::OpenRead($FilePath)
            $bufferSize = [Math]::Min($maxBytesToRead, $fileStream.Length)
            $buffer = New-Object byte[] $bufferSize
            $bytesRead = $fileStream.Read($buffer, 0, $bufferSize)
            $fileStream.Close()
        } catch {
            [System.Windows.MessageBox]::Show("Error reading file: $_", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error)
            return
        }

        # Convert bytes to ASCII
        $contentAscii = [System.Text.Encoding]::ASCII.GetString($buffer, 0, $bytesRead)

        # Search for patterns
        foreach ($key in $patterns.Keys) {
            $pattern = [regex]::Escape($patterns[$key])
            if ($contentAscii -match $pattern) {
                $findings.Add("$key installer detected via binary pattern.")
                if ($silentSwitchesDict.ContainsKey($key)) {
                    $silentSwitches.Add($silentSwitchesDict[$key])
                }
                $installerDetected = $true
            }
        }

        # Enhanced MSI detection
        # Check for MSI file signature (OLE Compound File)
        $msiSignature = [byte[]](0xD0,0xCF,0x11,0xE0,0xA1,0xB1,0x1A,0xE1)
        if ($buffer[0..7] -eq $msiSignature) {
            $findings.Add("MSI Installer package detected via file signature.")
            if ($silentSwitchesDict.ContainsKey("MSI Installer")) {
                $silentSwitches.Add($silentSwitchesDict["MSI Installer"])
            }
            $installerDetected = $true
        } else {
            # Check if the executable contains an embedded MSI
            $msiPattern = [System.Text.Encoding]::ASCII.GetBytes("MSI")
            $msiIndex = [Array]::IndexOf($buffer, $msiPattern[0])
            while ($msiIndex -ge 0 -and $msiIndex -lt ($buffer.Length - 2)) {
                if ($buffer[$msiIndex..($msiIndex+2)] -eq $msiPattern) {
                    $findings.Add("Embedded MSI Installer package detected within the executable.")
                    if ($silentSwitchesDict.ContainsKey("MSI Installer")) {
                        $silentSwitches.Add($silentSwitchesDict["MSI Installer"])
                    }
                    $installerDetected = $true
                    break
                }
                $msiIndex = [Array]::IndexOf($buffer, $msiPattern[0], $msiIndex + 1)
            }
        }
    }

    # Prepare result text
    $resultText = "Analyzed File:`n$FilePath`n`n"
    if ($findings.Count -gt 0) {
        $resultText += "Analysis Results:`n"
        foreach ($finding in $findings | Select-Object -Unique) {
            $resultText += "- $finding`n"
        }
        if ($silentSwitches.Count -gt 0) {
            $resultText += "`nSilent Install Switches:`n"
            foreach ($switch in ($silentSwitches | Select-Object -Unique)) {
                $resultText += "- $switch`n"
            }
        }
    } else {
        $resultText += "No known installer signatures detected in the file."
    }

    # Display the result
    $txtResult.Text = $resultText
})

# Show the Window
$Window.ShowDialog() | Out-Null
