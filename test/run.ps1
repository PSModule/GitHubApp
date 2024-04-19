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

switch ($githubEvent) {
    'security_advisory' {
        switch ($action) {
            'published' {
                $body = @{
                    content = @"
🌟 A new security advisory has been published:
  - GHSA ID: $($Request.Body.security_advisory.ghsa_id)
  - CVE ID: $($Request.Body.security_advisory.cve_id)
  - Summary: $($Request.Body.security_advisory.summary)
  - Severity: $($Request.Body.security_advisory.severity)
"@
                }
            }
            'updated' {
                $body = @{
                    content = @"
⚠️ A security advisory has been updated:
  - GHSA ID: $($Request.Body.security_advisory.ghsa_id)
  - CVE ID: $($Request.Body.security_advisory.cve_id)
  - Summary: $($Request.Body.security_advisory.summary)
  - Severity: $($Request.Body.security_advisory.severity)
"@
                }
            }
            'withdrawn' {
                $body = @{
                    content = @"
❌ A security advisory has been withdrawn:
  - GHSA ID: $($Request.Body.security_advisory.ghsa_id)
  - CVE ID: $($Request.Body.security_advisory.cve_id)
  - Summary: $($Request.Body.security_advisory.summary)
  - Severity: $($Request.Body.security_advisory.severity)
"@
                }
            }
        }
    }
    default {
        $body = @{
            content = @"
### $githubEvent
[$user](<$($Request.Body.sender.html_url)>) just $action a $githubEvent on [$repo](<$($Request.Body.repository.html_url)>)
"@
        }
    }
}

$body = $body | ConvertTo-Json

Invoke-RestMethod -Uri $env:DISCORD_WEBHOOK -Method Post -Body $body -ContentType 'application/json'

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value (
    [HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
    }
)
