param($myTimer)
Write-Information 'PowerShell timer trigger function started!'

$myTimer | Out-String -Stream | ForEach-Object { Write-Information $_ }

$webhooks = Get-GitHubAppWebhookDelivery
$redeliveries = $webhooks | Where-Object { $_.delivered_at -gt (Get-Date).AddHours(-2) } | Group-Object -Property guid | ForEach-Object {
    [pscustomobject]@{
        guid = $_.name
        redeliver = $_.Group.status -notcontains 'OK'
        id = $_.Group[0].id
    }
} | Where-Object { $_.redeliver }

foreach ($redelivery in $redeliveries) {
    Write-Information "Redelivering [$($redelivery.guid)] with ID [$($redelivery.id)]"
    $null = Redeliver-GitHubAppWebhookDelivery -ID $redelivery.id
}
