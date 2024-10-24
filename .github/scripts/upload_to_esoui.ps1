param (
    [string]$ApiToken,
    [string]$AddonId,
    [string]$Version,
    [string]$FilePath,
    [string]$Changelog,
    [string]$Compatible,
    [string]$Description,
    [bool]$TestOnly = $false # Default-Wert ist false
)

# Wähle die richtige URL basierend auf dem Wert von TestOnly
if ($TestOnly -eq $true) {
    $url = "https://api.esoui.com/addons/updatetest"
} else {
    $url = "https://api.esoui.com/addons/update"
}

$headers = @{
    "x-api-token" = $ApiToken
}

$form = @{
    "id"         = $AddonId
    "version"    = $Version
    "updatefile" = Get-Item $FilePath
    "changelog"  = $Changelog
    "compatible" = $Compatible
    "description" = $Description
}

$response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Form $form
$response | ConvertTo-Json