@{
    RootModule            = 'Hashtable.psm1'
    ModuleVersion         = '1.1.6'
    CompatiblePSEditions  = @(
        'Core'
        'Desktop'
    )
    GUID                  = '43f373f7-93fa-4364-9d7d-59b132a4f0ba'
    Author                = 'PSModule'
    CompanyName           = 'PSModule'
    Copyright             = '(c) 2025 PSModule. All rights reserved.'
    Description           = 'A PowerShell module that simplifies some interaction with Hashtables.'
    PowerShellVersion     = '5.1'
    ProcessorArchitecture = 'None'
    TypesToProcess        = @()
    FormatsToProcess      = @()
    FunctionsToExport     = @(
        'ConvertFrom-Hashtable'
        'ConvertTo-HashTable'
        'Export-Hashtable'
        'Format-Hashtable'
        'Import-Hashtable'
        'Merge-Hashtable'
        'Remove-HashtableEntry'
    )
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @(
        'Join-Hashtable'
    )
    ModuleList            = @()
    FileList              = @(
        'Hashtable.psm1'
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
            LicenseUri = 'https://github.com/PSModule/Hashtable/blob/main/LICENSE'
            ProjectUri = 'https://github.com/PSModule/Hashtable'
            IconUri    = 'https://raw.githubusercontent.com/PSModule/Hashtable/main/icon/icon.png'
        }
    }
}
