$null = Disable-AzContextAutosave -Scope Process
Connect-AzAccount -Identity -AccountId $env:AZURE_CLIENT_ID
Connect-GitHub -ClientID 'Iv23liYDnEbKlS9IVzHf' -KeyVaultKeyReference 'https://psmodule-test-vault.vault.azure.net/keys/psmodule-org-app'
