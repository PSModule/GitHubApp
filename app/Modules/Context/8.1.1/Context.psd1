@{
    RootModule            = 'Context.psm1'
    ModuleVersion         = '8.1.1'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = 'a6865f6c-b69e-43f1-bb83-46a8e0ef5462'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A PowerShell module that manages contexts with secrets and variables.'
    PowerShellVersion     = '5.1'
    ProcessorArchitecture = 'None'
    RequiredModules       = @(
        @{
            ModuleName      = 'Sodium'
            RequiredVersion = '2.2.0'
        }
    )
    TypesToProcess        = @()
    FormatsToProcess      = @(
        'formats/ContextInfo.Format.ps1xml'
        'formats/ContextVault.Format.ps1xml'
    )
    FunctionsToExport     = @(
        'Get-Context'
        'Get-ContextInfo'
        'Get-ContextVault'
        'Remove-Context'
        'Remove-ContextVault'
        'Rename-Context'
        'Reset-ContextVault'
        'Set-Context'
        'Set-ContextVault'
    )
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @(
        'New-Context'
        'Update-Context'
    )
    ModuleList            = @()
    FileList              = @(
        'Context.psm1'
        'formats/ContextInfo.Format.ps1xml'
        'formats/ContextVault.Format.ps1xml'
    )
    PrivateData           = @{
        PSData = @{
            Tags       = @(
                'context'
                'Linux'
                'MacOS'
                'powershell'
                'powershell-module'
                'PSEdition_Core'
                'PSEdition_Desktop'
                'Windows'
            )
            LicenseUri = 'https://github.com/PSModule/Context/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/Context'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/Context/main/icon/icon.png'
        }
    }
}
