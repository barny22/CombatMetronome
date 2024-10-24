param(
    [string]$api_token,
    [int]$addon_id,
    [string]$version,
    [string]$file_path,
    [string]$changelog_file_path,
    [string]$readme_file_path,
    [bool]$test_only = $true
)

function Upload-Addon {
    param (
        [string]$api_token,
        [int]$addon_id,
        [string]$version,
        [string]$file_path,
        [string]$changelog,
        [string]$compatible,
        [string]$description,
        [bool]$test_only
    )

    $url = if ($test_only) {
        "https://api.esoui.com/addons/updatetest"
    } else {
        "https://api.esoui.com/addons/update"
    }

    $headers = @{
        "x-api-token" = $api_token
    }

    # Prepare the multipart form data
    $formData = @{
        "archive" = "Yes"  # Set to "Yes" or "No" as required
        "updatefile" = Get-Item $file_path
        "id" = $addon_id
        "title" = ""  # Optional
        "version" = $version
        "changelog" = $changelog
        "compatible" = $compatible
        "description" = $description
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
$changelog = Get-Content $changelog_file_path
$description = Get-Content $readme_file_path

# Call the function with parameters
Upload-Addon -api_token $api_token -addon_id $addon_id -version $version -file_path $file_path -changelog $changelog -compatible $compatible -description $description -test_only $test_only
