@{
    RootModule            = 'Uri.psm1'
    ModuleVersion         = '1.1.2'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = 'd01c9795-3eba-48c1-afee-0d1432fab38e'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A powershell module that works with URIs (RFC3986)'
    PowerShellVersion     = '5.1'
    ProcessorArchitecture = 'None'
    TypesToProcess        = @()
    FormatsToProcess      = @()
    FunctionsToExport     = @(
        'ConvertFrom-UriQueryString'
        'ConvertTo-UriQueryString'
        'Get-Uri'
        'New-Uri'
        'Test-Uri'
    )
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @()
    ModuleList            = @()
    FileList              = 'Uri.psm1'
    PrivateData           = @{
        PSData = @{
            Tags       = @(
                'Windows'
                'Linux'
                'MacOS'
                'PSEdition_Desktop'
                'PSEdition_Core'
            )
            LicenseUri = 'https://github.com/PSModule/Uri/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/Uri'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/Uri/main/icon/icon.png'
        }
    }
}

