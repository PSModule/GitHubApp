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
$event = $Request.Headers.'x-github-event'
$repo = $Request.Body.repository.full_name

Write-Host "User: $user"
Write-Host "Action: $action"
Write-Host "Event: $event"
Write-Host "Repo: $repo"

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value (
    [HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
    }
)
