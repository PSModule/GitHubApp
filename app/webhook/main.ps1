using namespace System.Net

param(
    # The HTTP request context.
    # https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell?tabs=portal#request-object
    # https://docs.github.com/en/webhooks/webhook-events-and-payloads#delivery-headers
    [Parameter()]
    [HttpRequestContext] $Request
)

$contentType = $Request.Headers.'content-type'
if ($contentType -ne 'application/json') {
    Write-Error 'Content type is not application/json.'
    Push-OutputBinding -Name Response -Value (
        [HttpResponseContext]@{
            StatusCode = [int][HttpStatusCode]::UnsupportedMediaType
        }
    )
    return
}

# if (-not (Test-GitHubWebhookSignature -Request $Request -Secret 'qazzaq')) {
#     Write-Error 'Invalid signature.'
#     Push-OutputBinding -Name Response -Value (
#         [HttpResponseContext]@{
#             StatusCode = [int][HttpStatusCode]::Unauthorized
#         }
#     )
#     return
# }

$source = $Request.Headers.'X-Forwarded-For'
$eventType = $Request.Headers.'X-GitHub-Event'
$eventAction = $Request.Body.action
$eventID = $Request.Headers.'X-GitHub-Delivery'

Write-Information "Source:       $source"
Write-Information "Event type:   $eventType"
Write-Information "Event action: $eventAction"
Write-Information "Event ID:     $eventID"

$supportedEvents = @('team')
$supportedActions = @('created')

if ($eventType -in $supportedEvents -and $eventAction -in $supportedActions) {
    Write-Information 'Event is supported and sent to the eventgrid.'
    try {
        Push-OutputBinding -Name EventGrid -Value @{
            id          = $eventID
            source      = $source
            type        = $eventType
            subject     = 'githubwebhook'
            time        = (Get-Date -Format 'o')
            data        = $Request
            specversion = '1.0'
        }
        Push-OutputBinding -Name Response -Value (
            [HttpResponseContext]@{
                StatusCode = [int][HttpStatusCode]::Accepted
                Body       = @{
                    Status      = [string][HttpStatusCode]::Accepted
                    Message     = 'Event sent to the eventgrid.'
                    Source      = $source
                    EventType   = $eventType
                    EventID     = $eventID
                    EventAction = $eventAction
                }
            }
        )
    } catch {
        Write-Error $_
        Push-OutputBinding -Name Response -Value (
            [HttpResponseContext]@{
                StatusCode = [int][HttpStatusCode]::InternalServerError
                Body       = @{
                    Status      = [string][HttpStatusCode]::InternalServerError
                    Message     = 'Failed to process the call.'
                    Source      = $source
                    EventType   = $eventType
                    EventID     = $eventID
                    EventAction = $eventAction
                }
            }
        )
    }
} else {
    Write-Information 'Ok, but event and action was filtered out.'
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [int][HttpStatusCode]::OK
            Body       = @{
                Status      = [string][HttpStatusCode]::OK
                Message     = 'Ok, but event and action was filtered out.'
                Source      = $source
                EventType   = $eventType
                EventID     = $eventID
                EventAction = $eventAction
            }
        }
    )
}
