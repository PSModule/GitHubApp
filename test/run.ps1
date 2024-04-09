using namespace System.Net

# Input bindings are passed in via param block.
param(
    # HttpRequestContext object containing the request data.
    [Parameter()]
    # [HttpRequestContext] $Request,
    $Request,

    # Trigger metadata object containing the metadata for the trigger.
    [Parameter()]
    [hashtable] $TriggerMetadata
)

Write-Host "Request is of type '$($Request.GetType().FullName)'."

Write-Host 'PowerShell HTTP trigger function processed a request.'

$body = @{
    request             = $Request
    requestType         = $Request.GetType().FullName
    triggerMetadata     = $TriggerMetadata
    triggerMetadataType = $TriggerMetadata.GetType().FullName
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value (
    [HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body       = $body
    }
)
