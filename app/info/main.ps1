using namespace System.Net

param(
    [Parameter()]
    [HttpRequestContext] $Request,

    [Parameter()]
    $TriggerMetadata
)

Write-Host 'Request'
Write-Host "$($Request | Get-Member)"
Write-Host "$($Request | ConvertTo-Json -Depth 10 -Compress)"

Write-Host 'TriggerMetadata'
Write-Host "$($TriggerMetadata | Get-Member)"
Write-Host "$($TriggerMetadata | ConvertTo-Json -Depth 10 -Compress)"

Write-Host 'PSVersionTable'
Write-Host "$($PSVersionTable | Out-String)"

Write-Host 'AzContext'
Write-Host "$(Get-AzContext | Format-List | Out-String)"

Write-Host 'GitHubContext'
Write-Host "$(Get-GitHubContext | Format-List | Out-String)"

Write-Host 'GitHubConfig'
Write-Host "$(Get-GitHubConfig | Format-List | Out-String)"

