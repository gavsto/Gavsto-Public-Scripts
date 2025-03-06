# Author: Gavin Stone (NinjaOne)
# Date: 6th March 2025
# Description: Sarcasm is prevalent. This script creates a simple piano UI in PowerShell. You can play notes and submit a song to see if you played it correctly. Spoiler: you probably didn't.

# Oh joy, let's load those "essential" assemblies because PowerShell just can't live without them.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Global ArrayList to record your oh-so-masterful note presses.
$global:songNotes = New-Object System.Collections.ArrayList

# Creating the form because apparently our musical genius needs a stage.
$form = New-Object System.Windows.Forms.Form
$form.Text = "PowerShell UI Piano from Hell"

# Calculating form width: 7 white keys at 60 pixels each plus a "generous" 40 pixel margin—because why not?
$width = (7 * 60) + 40

# Pumping up the form height to squeeze in that Submit button
$form.Size = New-Object System.Drawing.Size($width, 300)
$form.StartPosition = "CenterScreen"  # Obviously, the center is where all the magic happens.

# Defining the white keys (C, D, E, F, G, A, B) with frequencies—because you can't play piano without them.
$whiteKeys = @(
    @{ Name = "C"; Frequency = 262 },
    @{ Name = "D"; Frequency = 294 },
    @{ Name = "E"; Frequency = 330 },
    @{ Name = "F"; Frequency = 349 },
    @{ Name = "G"; Frequency = 392 },
    @{ Name = "A"; Frequency = 440 },
    @{ Name = "B"; Frequency = 494 }
)

# Defining the black keys (C#, D#, F#, G#, A#) with frequencies.
# The 'Left' property gives them their oh-so-important horizontal placement on the form.
$blackKeys = @(
    @{ Name = "C#"; Frequency = 277; Left = 40 },
    @{ Name = "D#"; Frequency = 311; Left = 100 },
    # Because apparently, there’s no black key between E and F—nature's cruel joke.
    @{ Name = "F#"; Frequency = 370; Left = 220 },
    @{ Name = "G#"; Frequency = 415; Left = 280 },
    @{ Name = "A#"; Frequency = 466; Left = 340 }
)

# Function to play a note and record it—yes, it both sounds off and remembers your "talent."
function Play-Note {
    param($button)
    $noteName = $button.Text
    $frequency = $button.Tag
    Write-Host "Playing note: $noteName"
    # Recording the note because memory is everything—sorry, not sorry.
    $global:songNotes.Add($noteName) | Out-Null
    # Making sure the frequency is valid before we subject your ears to the beep.
    if ($frequency -and $frequency -ge 37 -and $frequency -le 32767) {
        [console]::Beep([int]$frequency, 500)
    }
}

# Creating and adding the white key buttons—because buttons are the new black (or white, in this case).
for ($i = 0; $i -lt $whiteKeys.Count; $i++) {
    $key = $whiteKeys[$i]
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $key.Name
    $btn.Tag = $key.Frequency
    $btn.Width = 60
    $btn.Height = 200
    $posX = $i * 60  # Pre-calculating X position because we’re too advanced for magic numbers.
    $btn.Location = New-Object System.Drawing.Point($posX, 0)
    $btn.BackColor = [System.Drawing.Color]::White
    $btn.ForeColor = [System.Drawing.Color]::Black
    $btn.FlatStyle = 'Flat'
    $btn.Add_Click({ param($sender, $args) Play-Note $sender })
    $form.Controls.Add($btn)
}

# Creating and adding the black key buttons—these divas need to be in front, obviously.
foreach ($key in $blackKeys) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $key.Name
    $btn.Tag = $key.Frequency
    $btn.Width = 40
    $btn.Height = 120
    $btn.Location = New-Object System.Drawing.Point($key.Left, 0)
    $btn.BackColor = [System.Drawing.Color]::Black
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.FlatStyle = 'Flat'
    $form.Controls.Add($btn)
    $btn.BringToFront()  # Because these keys think they're the star of the show.
    $btn.Add_Click({ param($sender, $args) Play-Note $sender })
}

# Creating and adding the "Submit Song" button—time to judge your performance!
$submitBtn = New-Object System.Windows.Forms.Button
$submitBtn.Text = "Submit Song"
$submitBtn.Width = 100
$submitBtn.Height = 30

# Placing the button centered at the bottom (beneath the keys) because symmetry is everything.
$submitBtn.Location = New-Object System.Drawing.Point(([math]::Round(($width - 100) / 2)), 210)

$submitBtn.Add_Click({
    # Defining the correct song sequence, as if there’s any room for creative interpretation.
    $correctSong = @("D", "C#", "D", "C#", "D", "D", "C#", "D", "E", "F#", "G", "A", "G#", "A", "G#", "A")
    # Comparing your recorded song with the "perfect" sequence.
    if (($global:songNotes -join ",") -eq ($correctSong -join ",")) {
        [System.Windows.Forms.MessageBox]::Show("Access Granted", "Result")
        Write-Host "Congratulations! You played the correct musical tune. Access Granted"
    } else {
        [System.Windows.Forms.MessageBox]::Show("Access Denied", "Result")
        Write-Host "ACCESS DENIED!!!!"
    }
    $form.Close()
})
$form.Controls.Add($submitBtn)

# Activating and running the form because apparently, we have nothing better to do.
$form.Add_Shown({ $form.Activate() })
[System.Windows.Forms.Application]::Run($form)
