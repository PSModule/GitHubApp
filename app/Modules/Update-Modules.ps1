Push-Location -Path $PSScriptRoot -Verbose
Get-ChildItem -Directory | Remove-Item -Recurse -Force -Verbose
Save-PSResource -Name GitHub -TrustRepository -Repository PSGallery -Verbose -Prerelease
Save-PSResource -Name Az.KeyVault -TrustRepository -Repository PSGallery -Verbose
Pop-Location
