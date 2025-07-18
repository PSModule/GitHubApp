using namespace System.Net

param(
    [Parameter()]
    [HttpRequestContext] $Request,

    [Parameter()]
    $TriggerMetadata
)

Write-Information 'Request'
Write-Information "$($Request | ConvertTo-Json -Depth 10)"

Write-Information 'TriggerMetadata'
Write-Information "$($TriggerMetadata | ConvertTo-Json -Depth 10)"

Write-Information 'PSVersionTable'
Write-Information "$($PSVersionTable | Out-String)"

Write-Information 'Environment variables'
Write-Information "$(Get-ChildItem -Path Env: | Format-Table -Property Name, Value | Out-String)"

Write-Information 'AzContext'
Write-Information "$(Get-AzContext | Format-List | Out-String)"

Write-Information 'GitHubContext'
Write-Information "$(Get-GitHubContext | Format-List | Out-String)"

Write-Information 'GitHubConfig'
Write-Information "$(Get-GitHubConfig | Format-List | Out-String)"

