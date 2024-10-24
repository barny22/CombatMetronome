param(
    [string]$ApiToken,
    [int]$AddonId,
    [string]$Version,
    [string]$FilePath,
    [string]$ChangelogFilePath,
    [string]$Compatible,
    [string]$ReadmeFilePath,
    [string]$TestOnly
)

    # Debugging-Ausgaben
    Write-Host "API Token: $ApiToken"
    Write-Host "AddOn Id: $AddonId"
    Write-Host "Version: $Version"
    Write-Host "ZIP File Path: $FilePath"
    Write-Host "Changelog File Path: $ChangelogFilePath"
    Write-Host "Compatible: $Compatible"
    Write-Host "Readme File Path: $ReadmeFilePath"
    Write-Host "Test: $TestOnly"

function Upload-Addon {
    param (
        [string]$ApiToken,
        [int]$AddonId,
        [string]$Version,
        [string]$FilePath,
        [string]$ChangelogFilePath,
        [string]$Compatible,
        [string]$ReadmeFilePath,
        [string]$TestOnly
    )

    $url = if ($TestOnly -eq "true") {
        "https://api.esoui.com/addons/updatetest"
    } else {
        "https://api.esoui.com/addons/update"
    }

    $headers = @{
        "x-api-token" = $ApiToken
    }

    # Prepare the multipart form data
    $formData = @{
        "archive" = "Yes"  # Set to "Yes" or "No" as required
        "updatefile" = Get-Item $FilePath
        "id" = $AddonId
        "title" = ""  # Optional
        "version" = $Version
        "changelog" = $ChangelogFilePath
        "compatible" = $Compatible
        "description" = $ReadmeFilePath
    }

    # Debugging-Ausgaben
    Write-Host "Request Data: $($formData | Out-String)"

    try {
        $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Form $formData
        Write-Host "Response code: $($response.StatusCode)"
        Write-Host "Response text: $($response.Content)"
    } catch {
        Write-Host "An error occurred: $_"
    }
}

# Changelog und Beschreibung aus den Dateien einlesen
$changelog = Get-Content $ChangelogFilePath
$description = Get-Content $ReadmeFilePath

# Call the function with parameters
Upload-Addon -api_token $ApiToken -addon_id $AddonId -version $Version -file_path $FilePath -changelog $changelog -compatible $Compatible -description $description -test_only $TestOnly
