@{
    RootModule            = 'TimeSpan.psm1'
    ModuleVersion         = '3.0.1'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = 'c13d0d90-962a-4964-b079-ab706a6454e3'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A PowerShell module for working with TimeSpans'
    PowerShellVersion     = '5.1'
    ProcessorArchitecture = 'None'
    TypesToProcess        = @()
    FormatsToProcess      = @()
    FunctionsToExport     = @(
        'Format-TimeSpan'
    )
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @()
    ModuleList            = @()
    FileList              = @(
        'TimeSpan.psm1'
    )
    PrivateData           = @{
        PSData = @{
            Tags       = @(
                'Linux'
                'MacOS'
                'PSEdition_Core'
                'PSEdition_Desktop'
                'Windows'
            )
            LicenseUri = 'https://github.com/PSModule/TimeSpan/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/TimeSpan'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/TimeSpan/main/icon/icon.png'
        }
    }
}
