[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSAvoidAssignmentToAutomaticVariable', 'IsWindows',
    Justification = 'IsWindows doesnt exist in PS5.1'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', 'IsWindows',
    Justification = 'IsWindows doesnt exist in PS5.1'
)]
[CmdletBinding()]
param()
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
$script:PSModuleInfo = Import-PowerShellDataFile -Path "$PSScriptRoot\$baseName.psd1"
$script:PSModuleInfo | Format-List | Out-String -Stream | ForEach-Object { Write-Debug $_ }
$scriptName = $script:PSModuleInfo.Name
Write-Debug "[$scriptName] - Importing module"

if ($PSEdition -eq 'Desktop') {
    $IsWindows = $true
}

#region    [functions] - [public]
Write-Debug "[$scriptName] - [functions] - [public] - Processing folder"
#region    [functions] - [public] - [ConvertFrom-Hashtable]
Write-Debug "[$scriptName] - [functions] - [public] - [ConvertFrom-Hashtable] - Importing"
filter ConvertFrom-Hashtable {
    <#
        .SYNOPSIS
        Converts a hashtable to a PSCustomObject.

        .DESCRIPTION
        Recursively converts a hashtable to a PSCustomObject.
        This function is useful for converting structured data to objects,
        making it easier to work with and manipulate.

        .EXAMPLE
        $hashtable = @{
            Name        = 'John Doe'
            Age         = 30
            Address     = @{
                Street  = '123 Main St'
                City    = 'Somewhere'
                ZipCode = '12345'
            }
            Occupations = @(
                @{
                    Title   = 'Developer'
                    Company = 'TechCorp'
                },
                @{
                    Title   = 'Consultant'
                    Company = 'ConsultCorp'
                }
            )
        }
        ConvertFrom-Hashtable -InputObject $hashtable

        Output:
        ```powershell
        Name                           Value
        ----                           -----
        Age                            30
        Address                        @{ZipCode=12345; City=Somewhere; Street=123 Main St}
        Name                           John Doe
        Occupations                    {@{Title=Developer; Company=TechCorp}, @{Title=Consultant; Company=ConsultCorp}}
        ```

        Converts the provided hashtable into a PSCustomObject.

        .OUTPUTS
        PSCustomObject

        .NOTES
        A custom object representation of the provided hashtable.
        The returned object preserves the original structure of the input.

        .LINK
        https://psmodule.io/Hashtable/Functions/ConvertFrom-Hashtable
    #>
    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    param(
        # The hashtable to convert to a PSCustomObject.
        [Parameter(Mandatory, ValueFromPipeline)]
        [hashtable] $InputObject
    )

    # Prepare a hashtable to hold properties for the PSCustomObject.
    $props = @{}

    foreach ($key in $InputObject.Keys) {
        $value = $InputObject[$key]

        if ($value -is [hashtable]) {
            # Recursively convert nested hashtables.
            $props[$key] = $value | ConvertFrom-Hashtable
        } elseif ($value -is [array]) {
            # Check each element: if it's a hashtable, convert it; otherwise, leave it as is.
            $props[$key] = $value | ForEach-Object {
                if ($_ -is [hashtable]) {
                    $_ | ConvertFrom-Hashtable
                } else {
                    $_
                }
            }
        } else {
            # For other types, assign directly.
            $props[$key] = $value
        }
    }

    [pscustomobject]$props
}
Write-Debug "[$scriptName] - [functions] - [public] - [ConvertFrom-Hashtable] - Done"
#endregion [functions] - [public] - [ConvertFrom-Hashtable]
#region    [functions] - [public] - [ConvertTo-HashTable]
Write-Debug "[$scriptName] - [functions] - [public] - [ConvertTo-HashTable] - Importing"
filter ConvertTo-Hashtable {
    <#
        .SYNOPSIS
        Converts an object to a hashtable.

        .DESCRIPTION
        Recursively converts an object to a hashtable. This function is useful for converting complex objects
        to hashtables for serialization or other purposes.

        .EXAMPLE
        $object = [PSCustomObject]@{
            Name        = 'John Doe'
            Age         = 30
            Address     = [PSCustomObject]@{
                Street  = '123 Main St'
                City    = 'Somewhere'
                ZipCode = '12345'
            }
            Occupations = @(
                [PSCustomObject]@{
                    Title   = 'Developer'
                    Company = 'TechCorp'
                },
                [PSCustomObject]@{
                    Title   = 'Consultant'
                    Company = 'ConsultCorp'
                }
            )
        }
        ConvertTo-Hashtable -InputObject $object

        Output:
        ```powershell
        Name                           Value
        ----                           -----
        Age                            30
        Address                        {[ZipCode, 12345], [City, Somewhere], [Street, 123 Main St]}
        Name                           John Doe
        Occupations                    {@{Title=Developer; Company=TechCorp}, @{Title=Consultant; Company=ConsultCorp}}
        ```

        This returns a hashtable representation of the object.

        .OUTPUTS
        hashtable

        .NOTES
        The function returns a hashtable representation of the input object,
        converting complex nested structures recursively.

        .LINK
        https://psmodule.io/Hashtable/Functions/ConvertTo-Hashtable
    #>
    [OutputType([hashtable])]
    [CmdletBinding()]
    param (
        # The object to convert to a hashtable.
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [PSObject] $InputObject
    )

    $hashtable = @{}

    # Iterate over each property of the object
    $InputObject.PSObject.Properties | ForEach-Object {
        $propertyName = $_.Name
        $propertyValue = $_.Value

        if ($propertyValue -is [PSObject]) {
            if ($propertyValue -is [Array] -or $propertyValue -is [System.Collections.IEnumerable]) {
                # Handle arrays and enumerables
                $hashtable[$propertyName] = @()
                foreach ($item in $propertyValue) {
                    $hashtable[$propertyName] += ConvertTo-Hashtable -InputObject $item
                }
            } elseif ($propertyValue.PSObject.Properties.Count -gt 0) {
                # Handle nested objects
                $hashtable[$propertyName] = ConvertTo-Hashtable -InputObject $propertyValue
            } else {
                # Handle simple properties
                $hashtable[$propertyName] = $propertyValue
            }
        } else {
            $hashtable[$propertyName] = $propertyValue
        }
    }

    $hashtable
}
Write-Debug "[$scriptName] - [functions] - [public] - [ConvertTo-HashTable] - Done"
#endregion [functions] - [public] - [ConvertTo-HashTable]
#region    [functions] - [public] - [Export-Hashtable]
Write-Debug "[$scriptName] - [functions] - [public] - [Export-Hashtable] - Importing"
filter Export-Hashtable {
    <#
        .SYNOPSIS
        Exports a hashtable to a specified file in PSD1, PS1, or JSON format.

        .DESCRIPTION
        This function takes a hashtable and exports it to a file in one of the supported formats: PSD1, PS1, or JSON.
        The format is determined based on the file extension provided in the Path parameter. If the extension is not
        recognized, the function throws an error. This function supports pipeline input.

        .EXAMPLE
        $myHashtable = @{ Key = 'Value'; Number = 42 }
        $myHashtable | Export-Hashtable -Path 'C:\config.psd1'

        Exports the hashtable to a PSD1 file.

        .EXAMPLE
        $myHashtable = @{ Key = 'Value'; Number = 42 }
        Export-Hashtable -Hashtable $myHashtable -Path 'C:\script.ps1'

        Exports the hashtable as a PowerShell script that returns the hashtable when executed.

        .EXAMPLE
        $myHashtable = @{ Key = 'Value'; Number = 42 }
        Export-Hashtable -Hashtable $myHashtable -Path 'C:\data.json'

        Exports the hashtable as a JSON file.

        .OUTPUTS
        void

        .NOTES
        This function does not return an output. It writes the exported data to a file.

        .LINK
        https://psmodule.io/Export/Functions/Export-Hashtable/
    #>
    [OutputType([void])]
    [CmdletBinding()]
    param(
        # The hashtable to export.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [hashtable] $Hashtable,

        # The file path where the hashtable will be exported.
        [Parameter(Mandatory)]
        [string] $Path
    )

    # Determine file extension and select export format.
    $extension = [System.IO.Path]::GetExtension($Path).ToLower()

    switch ($extension) {
        '.psd1' {
            try {
                # Use Format-Hashtable to generate a PSD1-like output.
                $formattedHashtable = Format-Hashtable -Hashtable $Hashtable
                Set-Content -Path $Path -Value $formattedHashtable -Force
            } catch {
                throw "Failed to export hashtable to PSD1 file '$Path'. Error details: $_"
            }
        }
        '.ps1' {
            try {
                # Format the hashtable and wrap it in a function so that when the script is run it returns the hashtable.
                $formattedHashtable = Format-Hashtable -Hashtable $Hashtable
                Set-Content -Path $Path -Value $formattedHashtable -Force
            } catch {
                throw "Failed to export hashtable to PS1 file '$Path'. Error details: $_"
            }
        }
        '.json' {
            try {
                # Convert the hashtable to JSON. You might adjust the Depth parameter as needed.
                $jsonContent = $Hashtable | ConvertTo-Json -Depth 10
                Set-Content -Path $Path -Value $jsonContent -Force
            } catch {
                throw "Failed to export hashtable to JSON file '$Path'. Error details: $_"
            }
        }
        default {
            throw "Unsupported file extension '$extension'. Only .psd1, .ps1, and .json files are supported."
        }
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Export-Hashtable] - Done"
#endregion [functions] - [public] - [Export-Hashtable]
#region    [functions] - [public] - [Format-Hashtable]
Write-Debug "[$scriptName] - [functions] - [public] - [Format-Hashtable] - Importing"
filter Format-Hashtable {
    <#
        .SYNOPSIS
        Converts a hashtable to its PowerShell code representation.

        .DESCRIPTION
        Recursively converts a hashtable to its PowerShell code representation.
        This function is useful for exporting hashtables to `.psd1` files,
        making it easier to store and retrieve structured data.

        .EXAMPLE
        $hashtable = @{
            Key1 = 'Value1'
            Key2 = @{
                NestedKey1 = 'NestedValue1'
                NestedKey2 = 'NestedValue2'
            }
            Key3 = @(1, 2, 3)
            Key4 = $true
        }
        Format-Hashtable -Hashtable $hashtable

        Output:
        ```powershell
        @{
            Key1       = 'Value1'
            Key2       = @{
                NestedKey1 = 'NestedValue1'
                NestedKey2 = 'NestedValue2'
            }
            Key3       = @(
                1
                2
                3
            )
            Key4       = $true
        }
        ```

        .OUTPUTS
        string

        .NOTES
        A string representation of the given hashtable.
        Useful for serialization and exporting hashtables to files.

        .LINK
        https://psmodule.io/Hashtable/Functions/Format-Hashtable
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param (
        # The hashtable to convert to a PowerShell code representation.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [System.Collections.IDictionary] $Hashtable,

        # The indentation level for formatting nested structures.
        [Parameter()]
        [int] $IndentLevel = 1
    )

    # If the hashtable is empty, return '@{}' immediately.
    if ($Hashtable.Count -eq 0) {
        return '@{}'
    }

    $indent = '    '
    $lines = @()
    $lines += '@{'
    $levelIndent = $indent * $IndentLevel

    # Compute maximum key length at this level to align the '=' characters
    $maxKeyLength = ($Hashtable.Keys | ForEach-Object { $_.ToString().Length } | Measure-Object -Maximum).Maximum

    foreach ($key in $Hashtable.Keys) {
        # Pad each key to the maximum length so the '=' lines up.
        $paddedKey = $key.ToString().PadRight($maxKeyLength)
        Write-Verbose "Processing key: [$key]"
        $value = $Hashtable[$key]
        Write-Verbose "Processing value: [$value]"
        if ($null -eq $value) {
            Write-Verbose "Value type: `$null"
            $lines += "$levelIndent$paddedKey = `$null"
            continue
        }
        Write-Verbose "Value type: [$($value.GetType().Name)]"
        if ($value -is [System.Collections.IDictionary]) {
            # Nested hashtable
            $nestedString = Format-Hashtable -Hashtable $value -IndentLevel ($IndentLevel + 1)
            $lines += "$levelIndent$paddedKey = $nestedString"
        } elseif ($value -is [System.Management.Automation.PSCustomObject]) {
            # PSCustomObject => Convert to hashtable & recurse
            $nestedString = $value | ConvertTo-Hashtable | Format-Hashtable -IndentLevel ($IndentLevel + 1)
            $lines += "$levelIndent$paddedKey = $nestedString"
        } elseif ( $value -is [bool] -or $value -is [System.Management.Automation.SwitchParameter] ) {
            $boolValue = [bool]$value
            $lines += "$levelIndent$paddedKey = `$$($boolValue.ToString().ToLower())"
        } elseif ($value -is [int] -or $value -is [long] -or $value -is [double] -or $value -is [decimal]) {
            $lines += "$levelIndent$paddedKey = $value"
        } elseif ($value -is [System.Collections.IList]) {
            # This covers normal arrays, ArrayList, List<T>, etc.
            if ($value.Count -eq 0) {
                $lines += "$levelIndent$paddedKey = @()"
            } else {
                $lines += "$levelIndent$paddedKey = @("
                $arrayIndent = $levelIndent + $indent

                foreach ($nestedValue in $value) {
                    Write-Verbose "Processing array element: [$nestedValue]"
                    Write-Verbose "Element type: [$($nestedValue.GetType().Name)]"

                    if (($nestedValue -is [System.Collections.IDictionary])) {
                        # Nested hashtable
                        $nestedString = Format-Hashtable -Hashtable $nestedValue -IndentLevel ($IndentLevel + 2)
                        $lines += "$arrayIndent$nestedString"
                    } elseif ($nestedValue -is [System.Management.Automation.PSCustomObject]) {
                        # PSCustomObject => Convert to hashtable & recurse
                        $nestedString = $nestedValue | ConvertTo-Hashtable | Format-Hashtable -IndentLevel ($IndentLevel + 2)
                        $lines += "$arrayIndent$nestedString"
                    } elseif ( $nestedValue -is [bool] -or $nestedValue -is [System.Management.Automation.SwitchParameter] ) {
                        $boolValue = [bool]$nestedValue
                        $lines += "$arrayIndent`$$($boolValue.ToString().ToLower())"
                    } elseif ($nestedValue -is [int] -or $nestedValue -is [long] -or $nestedValue -is [double] -or $nestedValue -is [decimal]) {
                        $lines += "$arrayIndent$nestedValue"
                    } else {
                        # Fallback => treat as string (escape single-quotes)
                        $escapedElement = $nestedValue -replace "('+)", "''"
                        $lines += "$arrayIndent'$escapedElement'"
                    }
                }

                $lines += ($levelIndent + ')')
            }
        } else {
            # Fallback: treat as string (escaping single-quotes)
            $escapedValue = $value -replace "('+)", "''"
            $lines += "$levelIndent$paddedKey = '$escapedValue'"
        }
    }

    $levelIndent = $indent * ($IndentLevel - 1)
    $lines += "$levelIndent}"

    return $lines -join [Environment]::NewLine
}
Write-Debug "[$scriptName] - [functions] - [public] - [Format-Hashtable] - Done"
#endregion [functions] - [public] - [Format-Hashtable]
#region    [functions] - [public] - [Import-Hashtable]
Write-Debug "[$scriptName] - [functions] - [public] - [Import-Hashtable] - Importing"
filter Import-Hashtable {
    <#
        .SYNOPSIS
        Imports a hashtable from a specified file.

        .DESCRIPTION
        This function reads a file and imports its contents as a hashtable. It supports `.psd1`, `.ps1`, and `.json` files.
        - `.psd1` files are imported using `Import-PowerShellDataFile`. This process is safe and does not execute any code.
        - `.ps1` scripts are executed, and their output must be a hashtable. If the script does not return a hashtable, an error is thrown.
        - `.json` files are read and converted to a hashtable using `ConvertFrom-Json -AsHashtable`.
        This process is safe and does not execute any code.

        If the specified file does not exist or has an unsupported format, an error is thrown.

        .EXAMPLE
        Import-Hashtable -Path 'C:\config.psd1'

        Output:
        ```powershell
        Name       Value
        ----       -----
        Setting1   Enabled
        Setting2   42
        ```

        Imports a hashtable from a `.psd1` file.

        .EXAMPLE
        Import-Hashtable -Path 'C:\script.ps1'

        Output:
        ```powershell
        Name       Value
        ----       -----
        Key1       Value1
        Key2       Value2
        ```

        Executes the script and imports the hashtable returned by the `.ps1` file.

        .EXAMPLE
        Import-Hashtable -Path 'C:\data.json'

        Output:
        ```powershell
        Name       Value
        ----       -----
        username   johndoe
        roles      {Admin, User}
        ```

        Reads a JSON file and converts its content into a hashtable.

        .OUTPUTS
        hashtable

        .NOTES
        A hashtable containing the data from the imported file.
        The hashtable structure depends on the contents of the imported file.

        .LINK
        https://psmodule.io/Hashtable/Functions/Import-Hashtable
    #>
    [CmdletBinding()]
    param(
        # Path to the file containing the hashtable.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string] $Path
    )

    if (-not (Test-Path -Path $Path)) {
        throw "File '$Path' does not exist."
    }

    $extension = [System.IO.Path]::GetExtension($Path).ToLower()

    switch ($extension) {
        '.psd1' {
            try {
                $hashtable = Import-PowerShellDataFile -Path $Path
            } catch {
                throw "Failed to import hashtable from PSD1 file '$Path'. Error details: $_"
            }
        }
        '.ps1' {
            try {
                $hashtable = & $Path
                if (-not ($hashtable -is [hashtable])) {
                    throw 'The PS1 script did not return a hashtable. Verify its content.'
                }
            } catch {
                throw "Failed to import hashtable from PS1 file '$Path'. Error details: $_"
            }
        }
        '.json' {
            try {
                # Read the entire JSON file and convert it to a hashtable.
                $jsonContent = Get-Content -Path $Path -Raw
                $hashtable = $jsonContent | ConvertFrom-Json -AsHashtable
            } catch {
                throw "Failed to import hashtable from JSON file '$Path'. Error details: $_"
            }
        }
        default {
            throw "Unsupported file extension '$extension'. Only .psd1, .ps1, and .json files are supported."
        }
    }

    return $hashtable
}
Write-Debug "[$scriptName] - [functions] - [public] - [Import-Hashtable] - Done"
#endregion [functions] - [public] - [Import-Hashtable]
#region    [functions] - [public] - [Merge-Hashtable]
Write-Debug "[$scriptName] - [functions] - [public] - [Merge-Hashtable] - Importing"
filter Merge-Hashtable {
    <#
        .SYNOPSIS
        Merges multiple hashtables, applying overrides in sequence.

        .DESCRIPTION
        This function takes a primary hashtable (`$Main`) and merges it with one or more override hashtables (`$Overrides`).
        Overrides are applied in order, with later values replacing earlier ones if the same key exists.
        If the `-Force` switch is used, values will be overridden even if they are empty or `$null`.
        The resulting hashtable is returned.

        .EXAMPLE
        $Main = @{
            Key1 = 'Value1'
            Key2 = 'Value2'
        }
        $Override1 = @{
            Key2 = 'Override2'
        }
        $Override2 = @{
            Key3 = 'Value3'
        }
        $Main | Merge-Hashtable -Overrides $Override1, $Override2

        Output:
        ```powershell
        Name                           Value
        ----                           -----
        Key1                           Value1
        Key2                           Override2
        Key3                           Value3
        ```

        Merges `$Main` with two override hashtables, applying overrides in order.

        .EXAMPLE
        $Main = @{
            Key1 = 'Value1'
            Key2 = 'Value2'
        }
        $Override = @{
            Key2 = ''
            Key3 = 'Value3'
        }
        $Main | Merge-Hashtable -Overrides $Override -Force

        Output:
        ```powershell
        Name                           Value
        ----                           -----
        Key1                           Value1
        Key2
        Key3                           Value3
        ```

        Forces overriding even if the value is empty.

        .OUTPUTS
        Hashtable

        .NOTES
        A merged hashtable with applied overrides.

        .LINK
        https://psmodule.io/Hashtable/Functions/Merge-Hashtable/
    #>

    [OutputType([Hashtable])]
    [Alias('Join-Hashtable')]
    [CmdletBinding()]
    param (
        # Main hashtable
        [Parameter(Mandatory)]
        [hashtable] $Main,

        # Hashtable with overrides.
        # Providing a list of overrides will apply them in order.
        # Last write wins.
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [hashtable[]] $Overrides,

        # When specified, force override even if the value is empty or null.
        [Parameter()]
        [switch] $Force
    )

    begin {
        $Output = $Main.Clone()
    }

    process {
        foreach ($Override in $Overrides) {
            foreach ($Key in $Override.Keys) {
                if (($Output.Keys) -notcontains $Key) {
                    $Output.$Key = $Override.$Key
                }
                if ($Force -or -not [string]::IsNullOrEmpty($Override[$Key])) {
                    $Output[$Key] = $Override[$Key]
                }
            }
        }
    }

    end {
        return $Output
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Merge-Hashtable] - Done"
#endregion [functions] - [public] - [Merge-Hashtable]
#region    [functions] - [public] - [Remove-HashtableEntry]
Write-Debug "[$scriptName] - [functions] - [public] - [Remove-HashtableEntry] - Importing"
filter Remove-HashtableEntry {
    <#
        .SYNOPSIS
        Removes specific entries from a hashtable based on given criteria.

        .DESCRIPTION
        This function filters out entries from a hashtable based on different conditions. You can remove keys with
        null or empty values, keys of a specific type, or keys matching certain names. It also allows keeping entries
        based on the opposite criteria. If the `-All` parameter is used, all entries in the hashtable will be removed.

        .EXAMPLE
        $myHashtable = @{ Name = 'John'; Age = 30; Country = $null }
        $myHashtable | Remove-HashtableEntry -NullOrEmptyValues

        Output:
        ```powershell
        @{ Name = 'John'; Age = 30 }
        ```

        Removes entries with null or empty values from the hashtable.

        .EXAMPLE
        $myHashtable = @{ Name = 'John'; Age = 30; Active = $true }
        $myHashtable | Remove-HashtableEntry -Types 'Boolean'

        Output:
        ```powershell
        @{ Name = 'John'; Age = 30 }
        ```

        Removes entries where the value type is Boolean.

        .EXAMPLE
        $myHashtable = @{ Name = 'John'; Age = 30; Country = 'USA' }
        $myHashtable | Remove-HashtableEntry -Keys 'Age'

        Output:
        ```powershell
        @{ Name = 'John'; Country = 'USA' }
        ```

        Removes the key 'Age' from the hashtable.

        .OUTPUTS
        void

        .NOTES
        The function modifies the input hashtable but does not return output.

        .LINK
        https://psmodule.io/Hashtable/Functions/Remove-HashtableEntry/
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Function does not change state.'
    )]
    [OutputType([void])]
    [CmdletBinding()]
    param(
        # The hashtable to remove entries from.
        [Parameter(Mandatory, ValueFromPipeline)]
        [hashtable] $Hashtable,

        # Remove keys with null or empty values.
        [Parameter()]
        [switch] $NullOrEmptyValues,

        # Remove keys of a specified type.
        [Parameter()]
        [string[]] $Types,

        # Remove keys with a specified name.
        [Parameter()]
        [Alias('Names')]
        [string[]] $Keys,

        # Remove keys with null or empty values.
        [Parameter()]
        [Alias('IgnoreNullOrEmptyValues')]
        [switch] $KeepNullOrEmptyValues,

        # Keep only keys of a specified type.
        [Parameter()]
        [Alias('IgnoreTypes')]
        [string[]] $KeepTypes,

        # Keep only keys with a specified name.
        [Parameter()]
        [Alias('IgnoreKey', 'KeepNames')]
        [string[]] $KeepKeys,

        # Remove all entries from the hashtable.
        [Parameter()]
        [switch] $All
    )

    # Copy keys to a static array to prevent modifying the collection during iteration.
    $hashtableKeys = @($Hashtable.Keys)
    foreach ($key in $hashtableKeys) {
        $value = $Hashtable[$key]
        $vaultIsNullOrEmpty = [string]::IsNullOrEmpty($value)
        $valueIsNotNullOrEmpty = -not $vaultIsNullOrEmpty
        $typeName = if ($valueIsNotNullOrEmpty) { $value.GetType().Name } else { $null }

        if ($KeepKeys -and $key -in $KeepKeys) {
            Write-Debug "Keeping [$key] because it is in KeepKeys [$KeepKeys]."
        } elseif ($KeepTypes -and $typeName -in $KeepTypes) {
            Write-Debug "Keeping [$key] because its type [$typeName] is in KeepTypes [$KeepTypes]."
        } elseif ($vaultIsNullOrEmpty -and $KeepNullOrEmptyValues) {
            Write-Debug "Keeping [$key] because its value is null or empty."
        } elseif ($vaultIsNullOrEmpty -and $NullOrEmptyValues) {
            Write-Debug "Removing [$key] because its value is null or empty."
            $Hashtable.Remove($key)
        } elseif ($Types -and $typeName -in $Types) {
            Write-Debug "Removing [$key] because its type [$typeName] is in Types [$Types]."
            $Hashtable.Remove($key)
        } elseif ($Keys -and $key -in $Keys) {
            Write-Debug "Removing [$key] because it is in Keys [$Keys]."
            $Hashtable.Remove($key)
        } elseif ($All) {
            Write-Debug "Removing [$key] because All flag is set."
            $Hashtable.Remove($key)
        } else {
            Write-Debug "Keeping [$key] by default."
        }
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Remove-HashtableEntry] - Done"
#endregion [functions] - [public] - [Remove-HashtableEntry]
Write-Debug "[$scriptName] - [functions] - [public] - Done"
#endregion [functions] - [public]

#region    Member exporter
$exports = @{
    Alias    = '*'
    Cmdlet   = ''
    Function = @(
        'ConvertFrom-Hashtable'
        'ConvertTo-HashTable'
        'Export-Hashtable'
        'Format-Hashtable'
        'Import-Hashtable'
        'Merge-Hashtable'
        'Remove-HashtableEntry'
    )
    Variable = ''
}
Export-ModuleMember @exports
#endregion Member exporter

