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
            content = "$user just $action $githubEvent on $repo"
        }
    }
}
{
    'action': 'updated',
    'security_advisory': {
        'ghsa_id': 'GHSA-r57f-7xw3-q2r9',
        'cve_id': 'CVE-2017-1000354',
        'summary': 'Improper Authentication in Jenkins',
        'description': "Jenkins versions 2.56 and earlier as well as 2.46.1 LTS and earlier are vulnerable to a login command which allowed impersonating any Jenkins user. The `login` command available in the remoting-based CLI stored the encrypted user name of the successfully authenticated user in a cache file used to authenticate further commands. Users with sufficient permission to create secrets in Jenkins, and download their encrypted values (e.g. with Job/Configure permission), were able to impersonate any other Jenkins user on the same instance.",
        'severity': 'high',
        'identifiers': [
        {
            'value': 'GHSA-r57f-7xw3-q2r9',
            'type': 'GHSA'
        },
        {
            'value': 'CVE-2017-1000354',
            'type': 'CVE'
        }
        ],
        'references': [
        {
            'url': 'https://nvd.nist.gov/vuln/detail/CVE-2017-1000354'
        },
        {
            'url': 'https://github.com/jenkinsci/jenkins/commit/02d24053bdfeb219d2387a19885a60bdab510479'
        },
        {
            'url': 'https://jenkins.io/security/advisory/2017-04-26'
        },
        {
            'url': 'https://web.archive.org/web/20200227174424/http://www.securityfocus.com/bid/98065'
        },
        {
            'url': 'https://github.com/advisories/GHSA-r57f-7xw3-q2r9'
        }
        ],
        'published_at': '2022-05-14T03:44:30Z',
        'updated_at': '2024-04-19T18:59:32Z',
        'withdrawn_at': null,
        'vulnerabilities': [
        {
            'package': {
                'ecosystem': 'maven',
                'name': 'org.jenkins-ci.main:jenkins-core'
            },
            'severity': 'high',
            'vulnerable_version_range': '>= 2.50, <= 2.56',
            'first_patched_version': {
                'identifier': '2.57'
            }
        },
        {
            'package': {
                'ecosystem': 'maven',
                'name': 'org.jenkins-ci.main:jenkins-core'
            },
            'severity': 'high',
            'vulnerable_version_range': '<= 2.46.1',
            'first_patched_version': {
                'identifier': '2.46.2'
            }
        }
        ],
        'cvss': {
            'vector_string': 'CVSS:3.0/AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:H',
            'score': 8.8
        },
        'cwes': [
        {
            'cwe_id': 'CWE-287',
            'name': 'Improper Authentication'
        }
        ]
    }
}
$body = @{
    content = "$user just $action a $githubEvent on $repo"
}
}
default {
    $body = @{
        content = "$user just $action $githubEvent on $repo"
    }
}
}

$body = $body | ConvertTo-Json

Invoke-RestMethod -Uri $env:DISCORD_WEBHOOK -Method Post -Body ( | ConvertTo-Json) -ContentType 'application/json'

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value (
    [HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
    }
)
