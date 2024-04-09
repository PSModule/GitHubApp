using namespace System.Net

# Input bindings are passed in via param block.
param(
    # HttpRequestContext object containing the request data.
    [Parameter()]
    [HttpRequestContext] $Request,

    # Trigger metadata object containing the metadata for the trigger.
    [Parameter()]
    $TriggerMetadata
)

Write-Host "TriggerMetadata is of type '$($TriggerMetadata.GetType().FullName)'."

Write-Host 'PowerShell HTTP trigger function processed a request.'

$body = @{
    request         = $Request
    triggerMetadata = $TriggerMetadata
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value (
    [HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    }
)
