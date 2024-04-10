using namespace System.Net

# Input bindings are passed in via param block.
param(
    # HttpRequestContext object containing the request data.
    [Parameter()]
    # [HttpRequestContext] $Request,
    [HttpRequestContext] $Request,

    # Trigger metadata object containing the metadata for the trigger.
    [Parameter()]
    [hashtable] $TriggerMetadata
)

$user = $Request.Body.sender.login
$action = $Request.Body.action
$githubEvent = $Request.Headers.'x-github-event'
$repo = $Request.Body.repository.full_name

Write-Information "User: $user"
Write-Information "Action: $action"
Write-Information "Event: $githubEvent"
Write-Information "Repo: $repo"

Invoke-RestMethod -Uri $env:DISCORD_WEBHOOK -Method Post -Body (@{
        content = "$user just $action $githubEvent on $repo"
    } | ConvertTo-Json) -ContentType 'application/json'

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value (
    [HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
    }
)
