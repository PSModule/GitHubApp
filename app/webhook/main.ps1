using namespace System.Net

param(
    [Parameter()]
    [HttpRequestContext] $Request
)

Write-Debug ($request | ConvertTo-Json)
$contentType = $Request.Headers.'content-type'
if ($contentType -ne 'application/json') {
    Write-Error 'Content type is not application/json.'
    Push-OutputBinding -Name Response -Value (
        [HttpResponseContext]@{
            StatusCode = [int][HttpStatusCode]::UnsupportedMediaType
            Body       = @{
                Status  = [string][HttpStatusCode]::UnsupportedMediaType
                Message = 'Content type is not application/json.'
                Headers = $Request.Headers
            }
        }
    )
    return
}

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
    Push-OutputBinding -Name Response -Value (
        [HttpResponseContext]@{
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

