# Create a new instance of the WebClient class for handling HTTP requests
$webClient = New-Object System.Net.WebClient

# Add the required headers for authentication and content type
$authToken = 'token NotGettingMeLuckyCharms'  # Replace with your actual token
$webClient.Headers.Add('Authorization', $authToken)
$webClient.Headers.Add('Accept', 'application/vnd.github.v3.raw')

# Define the URL of the PowerShell script to be downloaded and executed
$scriptUrl = 'https://raw.githubusercontent.com/yourps1.ps1'

# Download the script content from the specified URL
$scriptContent = $webClient.DownloadString($scriptUrl)

# Execute the downloaded script content
Invoke-Expression $scriptContent
