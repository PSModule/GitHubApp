using namespace System.Net

param(
    # The HTTP request context.
    # https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell?tabs=portal#request-object
    # https://docs.github.com/en/webhooks/webhook-events-and-payloads#delivery-headers
    [Parameter()]
    [HttpRequestContext] $Request,

    # Metadata about the trigger
    # This can include information like the function name, invocation ID, etc.
    [Parameter()]
    [Hashtable] $TriggerMetadata
)

Write-Information 'Request'
Write-Information "$($Request | ConvertTo-Json -Depth 10)"

Write-Information 'TriggerMetadata'
Write-Information "$($TriggerMetadata | ConvertTo-Json -Depth 10)"

Write-Information 'PSVersionTable'
Write-Information "$($PSVersionTable | Out-String)"

Write-Information 'Environment variables'
$envHash = @{}
Get-ChildItem -Path Env: | ForEach-Object { $envHash[$_.Name] = $_.Value }
Write-Information "$([PSCustomObject]$envHash | Format-List | Out-String)"

Write-Information 'AzContext'
Write-Information "$(Get-AzContext | Format-List | Out-String)"

Write-Information 'AzConfig'
Write-Information "$(Get-AzConfig | Format-List | Out-String)"

Write-Information 'GitHubContext'
Write-Information "$(Get-GitHubContext | Select-Object * | Format-List | Out-String)"

Write-Information 'GitHubConfig'
Write-Information "$(Get-GitHubConfig | Format-List | Out-String)"

Push-OutputBinding -Name Response -Value (
    [HttpResponseContext]@{
        StatusCode  = [int][HttpStatusCode]::UnsupportedMediaType
        ContentType = 'application/json'
        Headers     = @{
            'WhatEver' = 'You want to put here'
        }
        Body        = [pscustomobject]@{
            Message        = 'Content type is not application/json.'
            AzContext      = Get-AzContext
            GitHubContext  = Get-GitHubContext
            GitHubConfig   = Get-GitHubConfig
            PSVersionTable = $PSVersionTable
            Environment    = $envHash
        }
    }
)
