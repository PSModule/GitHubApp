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

#region    [classes] - [public]
Write-Debug "[$scriptName] - [classes] - [public] - Processing folder"
#region    [classes] - [public] - [ContextInfo]
Write-Debug "[$scriptName] - [classes] - [public] - [ContextInfo] - Importing"
class ContextInfo {
    [string] $ID
    [string] $Path
    [string] $Vault
    [string] $Context

    ContextInfo() {}

    ContextInfo([PSCustomObject]$Object) {
        $this.ID = $Object.ID
        $this.Path = $Object.Path
        $this.Vault = $Object.Vault
        $this.Context = $Object.Context
    }
}
Write-Debug "[$scriptName] - [classes] - [public] - [ContextInfo] - Done"
#endregion [classes] - [public] - [ContextInfo]
#region    [classes] - [public] - [ContextVault]
Write-Debug "[$scriptName] - [classes] - [public] - [ContextVault] - Importing"
class ContextVault {
    [string] $Name
    [string] $Path

    ContextVault() {}

    ContextVault([string] $name, [string] $path) {
        $this.Name = $name
        $this.Path = $path
    }

    [string] ToString() {
        return $this.Name
    }
}
Write-Debug "[$scriptName] - [classes] - [public] - [ContextVault] - Done"
#endregion [classes] - [public] - [ContextVault]
Write-Debug "[$scriptName] - [classes] - [public] - Done"
#endregion [classes] - [public]
#region    [functions] - [private]
Write-Debug "[$scriptName] - [functions] - [private] - Processing folder"
#region    [functions] - [private] - [Get-ContextVaultKeyPair]
Write-Debug "[$scriptName] - [functions] - [private] - [Get-ContextVaultKeyPair] - Importing"
function Get-ContextVaultKeyPair {
    <#
        .SYNOPSIS
        Retrieves the public and private keys from the context vault.

        .DESCRIPTION
        Retrieves the public and private keys used for encrypting contexts in the context vault.
        The keys are stored in a secure manner and can be used to encrypt or decrypt contexts.

        .EXAMPLE
        Get-ContextVaultKeyPair

        Output:
        ```powershell
        PublicKey  : <public key>
        PrivateKey : <private key>
        ```

        Retrieves the public and private keys from the context vault.
    #>
    [OutputType([object])]
    [CmdletBinding()]
    param(
        # The name of the vault to retrieve the keys from.
        [Parameter(Mandatory)]
        [string] $Vault
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        $vaultObject = Set-ContextVault -Name $Vault -PassThru
        $shardPath = Join-Path -Path $vaultObject.Path -ChildPath $script:Config.ShardFileName
        $fileShard = Get-Content -Path $shardPath
        $machineShard = [System.Environment]::MachineName
        $userShard = [System.Environment]::UserName
        #$userInputShard = Read-Host -Prompt 'Enter a seed shard' # Eventually 4 shards. +1 for user input.
        $seed = $machineShard + $userShard + $fileShard # + $userInputShard
        $keys = New-SodiumKeyPair -Seed $seed
        $keys
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
Write-Debug "[$scriptName] - [functions] - [private] - [Get-ContextVaultKeyPair] - Done"
#endregion [functions] - [private] - [Get-ContextVaultKeyPair]
#region    [functions] - [private] - [JsonToObject]
Write-Debug "[$scriptName] - [functions] - [private] - [JsonToObject] - Processing folder"
#region    [functions] - [private] - [JsonToObject] - [Convert-ContextHashtableToObjectRecursive]
Write-Debug "[$scriptName] - [functions] - [private] - [JsonToObject] - [Convert-ContextHashtableToObjectRecursive] - Importing"
function Convert-ContextHashtableToObjectRecursive {
    <#
        .SYNOPSIS
        Converts a hashtable into a structured context object.

        .DESCRIPTION
        This function recursively converts a hashtable into a structured PowerShell object.
        String values prefixed with '[SECURESTRING]' are converted back to SecureString objects.
        Other values retain their original data types, including integers, booleans, strings, arrays,
        and nested objects.

        .EXAMPLE
        Convert-ContextHashtableToObjectRecursive -Hashtable @{
            Name   = 'Test'
            Token  = '[SECURESTRING]TestToken'
            Nested = @{
                Name  = 'Nested'
                Token = '[SECURESTRING]NestedToken'
            }
        }

        Output:
        ```powershell
        Name   : Test
        Token  : System.Security.SecureString
        Nested : @{ Name = Nested; Token = System.Security.SecureString }
        ```

        This example converts a hashtable into a structured object, where 'Token' and 'Nested.Token'
        values are SecureString objects.

        .OUTPUTS
        PSCustomObject

        .NOTES
        Returns an object where values are converted to their respective types,
        including SecureString for sensitive values, arrays for list structures, and nested objects
        for hashtables.

        .LINK
        https://psmodule.io/Context/Functions/Convert-ContextHashtableToObjectRecursive
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingConvertToSecureStringWithPlainText', '',
        Justification = 'The SecureString is extracted from the object being processed by this function.'
    )]
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param (
        # Hashtable to convert into a structured context object
        [Parameter(Mandatory)]
        [hashtable] $Hashtable
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        try {
            $result = [pscustomobject]@{}

            foreach ($key in $Hashtable.Keys) {
                $value = $Hashtable[$key]
                Write-Debug "Processing [$key]"
                Write-Debug "Value: $value"
                if ($null -eq $value) {
                    Write-Debug "- as null value"
                    $result | Add-Member -NotePropertyName $key -NotePropertyValue $null
                    continue
                }
                Write-Debug "Type:  $($value.GetType().Name)"
                if ($value -is [string] -and $value -like '`[SECURESTRING`]*') {
                    Write-Debug "Converting [$key] as [SecureString]"
                    $secureValue = $value -replace '^\[SECURESTRING\]', ''
                    $result | Add-Member -NotePropertyName $key -NotePropertyValue ($secureValue | ConvertTo-SecureString -AsPlainText -Force)
                } elseif ($value -is [hashtable]) {
                    Write-Debug "Converting [$key] as [hashtable]"
                    $result | Add-Member -NotePropertyName $key -NotePropertyValue (Convert-ContextHashtableToObjectRecursive $value)
                } elseif ($value -is [array]) {
                    Write-Debug "Converting [$key] as [array], processing elements individually"
                    $result | Add-Member -NotePropertyName $key -NotePropertyValue @(
                        $value | ForEach-Object {
                            if ($_ -is [hashtable]) {
                                Convert-ContextHashtableToObjectRecursive $_
                            } else {
                                $_
                            }
                        }
                    )
                } else {
                    Write-Debug "Adding [$key] as a standard value"
                    $result | Add-Member -NotePropertyName $key -NotePropertyValue $value
                }
            }
            return $result
        } catch {
            Write-Error $_
            throw 'Failed to convert hashtable to object'
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
Write-Debug "[$scriptName] - [functions] - [private] - [JsonToObject] - [Convert-ContextHashtableToObjectRecursive] - Done"
#endregion [functions] - [private] - [JsonToObject] - [Convert-ContextHashtableToObjectRecursive]
#region    [functions] - [private] - [JsonToObject] - [ConvertFrom-ContextJson]
Write-Debug "[$scriptName] - [functions] - [private] - [JsonToObject] - [ConvertFrom-ContextJson] - Importing"
function ConvertFrom-ContextJson {
    <#
        .SYNOPSIS
        Converts a JSON string to a context object.

        .DESCRIPTION
        Converts a JSON string to a context object. Text prefixed with `[SECURESTRING]` is converted to SecureString objects.
        Other values are converted to their original types, such as integers, booleans, strings, arrays, and nested objects.

        .EXAMPLE
        $content = @'
        {
            "Name": "Test",
            "Token": "[SECURESTRING]TestToken",
            "Nested": {
                "Name": "Nested",
                "Token": "[SECURESTRING]NestedToken"
            }
        }
        '@
        ConvertFrom-ContextJson -JsonString $content

        Output:
        ```powershell
        Name   : Test
        Token  : System.Security.SecureString
        Nested : @{Name=Nested; Token=System.Security.SecureString}
        ```

        Converts a JSON string to a context object, ensuring 'Token' and 'Nested.Token' values are SecureString objects.

        .OUTPUTS
        PSCustomObject

        .NOTES
        Returns a PowerShell custom object with SecureString conversion applied where necessary.

        .LINK
        https://psmodule.io/Context/Functions/ConvertFrom-ContextJson/
    #>
    [OutputType([pscustomobject])]
    [CmdletBinding()]
    param (
        # JSON string to convert to context object
        [Parameter()]
        [string] $JsonString = '{}'
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        try {
            $hashtableObject = $JsonString | ConvertFrom-Json -Depth 100 -AsHashtable
            return Convert-ContextHashtableToObjectRecursive $hashtableObject
        } catch {
            Write-Error $_
            throw 'Failed to convert JSON to object'
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
Write-Debug "[$scriptName] - [functions] - [private] - [JsonToObject] - [ConvertFrom-ContextJson] - Done"
#endregion [functions] - [private] - [JsonToObject] - [ConvertFrom-ContextJson]
Write-Debug "[$scriptName] - [functions] - [private] - [JsonToObject] - Done"
#endregion [functions] - [private] - [JsonToObject]
#region    [functions] - [private] - [ObjectToJson]
Write-Debug "[$scriptName] - [functions] - [private] - [ObjectToJson] - Processing folder"
#region    [functions] - [private] - [ObjectToJson] - [Convert-ContextObjectToHashtableRecursive]
Write-Debug "[$scriptName] - [functions] - [private] - [ObjectToJson] - [Convert-ContextObjectToHashtableRecursive] - Importing"
function Convert-ContextObjectToHashtableRecursive {
    <#
        .SYNOPSIS
        Converts a context object to a hashtable.

        .DESCRIPTION
        This function converts a context object to a hashtable.
        Secure strings are converted to a string representation, prefixed with '[SECURESTRING]'.
        Datetime objects are converted to a string representation using the 'o' format specifier.
        Nested context objects are recursively converted to hashtables.

        .EXAMPLE
        Convert-ContextObjectToHashtableRecursive -Object ([PSCustomObject]@{
            Name = 'MySecret'
            AccessToken = '123123123' | ConvertTo-SecureString -AsPlainText -Force
            Nested = @{
                Name = 'MyNestedSecret'
                NestedAccessToken = '123123123' | ConvertTo-SecureString -AsPlainText -Force
            }
        })

        Output:
        ```powershell
        Name         : MySecret
        AccessToken  : [SECURESTRING]123123123
        Nested       : @{Name=MyNestedSecret; NestedAccessToken=[SECURESTRING]123123123}
        ```

        Converts the context object to a hashtable. Secure strings are converted to a string representation.

        .OUTPUTS
        hashtable

        .NOTES
        Returns a hashtable representation of the input object.
        Secure strings are converted to prefixed string values.

        .LINK
        https://psmodule.io/Context/Functions/Convert-ContextObjectToHashtableRecursive
    #>
    [OutputType([hashtable])]
    [CmdletBinding()]
    param (
        # The object to convert.
        [Parameter()]
        [object] $Object = @{}
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        try {
            $result = @{}

            if ($Object -is [hashtable]) {
                Write-Debug 'Converting [hashtable] to [PSCustomObject]'
                $Object = [PSCustomObject]$Object
            } elseif ($Object -is [string] -or $Object -is [int] -or $Object -is [bool]) {
                Write-Debug 'returning as string'
                return $Object
            }

            foreach ($property in $Object.PSObject.Properties) {
                $name = $property.Name
                $value = $property.Value
                Write-Debug "Processing [$name]"
                Write-Debug "Value: $value"
                if ($null -eq $value) {
                    Write-Debug '- as null value'
                    $result[$property.Name] = $null
                    continue
                }
                Write-Debug "Type:  $($value.GetType().Name)"
                if ($value -is [datetime]) {
                    Write-Debug '- as DateTime'
                    $result[$property.Name] = $value.ToString('o')
                } elseif ($value -is [string] -or $Object -is [int] -or $Object -is [bool]) {
                    Write-Debug '- as string, int, bool'
                    $result[$property.Name] = $value
                } elseif ($value -is [System.Security.SecureString]) {
                    Write-Debug '- as SecureString'
                    $value = $value | ConvertFrom-SecureString -AsPlainText
                    $result[$property.Name] = "[SECURESTRING]$value"
                } elseif ($value -is [psobject] -or $value -is [PSCustomObject] -or $value -is [hashtable]) {
                    Write-Debug '- as PSObject, PSCustomObject or hashtable'
                    $result[$property.Name] = Convert-ContextObjectToHashtableRecursive $value
                } elseif ($value -is [System.Collections.IEnumerable]) {
                    Write-Debug '- as IEnumerable, including arrays and hashtables'
                    $result[$property.Name] = @(
                        $value | ForEach-Object {
                            Convert-ContextObjectToHashtableRecursive $_
                        }
                    )
                } else {
                    Write-Debug '- as regular value'
                    $result[$property.Name] = $value
                }
            }
            return $result
        } catch {
            Write-Error $_
            throw 'Failed to convert context object to hashtable'
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
Write-Debug "[$scriptName] - [functions] - [private] - [ObjectToJson] - [Convert-ContextObjectToHashtableRecursive] - Done"
#endregion [functions] - [private] - [ObjectToJson] - [Convert-ContextObjectToHashtableRecursive]
#region    [functions] - [private] - [ObjectToJson] - [ConvertTo-ContextJson]
Write-Debug "[$scriptName] - [functions] - [private] - [ObjectToJson] - [ConvertTo-ContextJson] - Importing"
function ConvertTo-ContextJson {
    <#
        .SYNOPSIS
        Converts an object into a JSON string.

        .DESCRIPTION
        Converts objects or hashtables into a JSON string. SecureStrings are converted to plain text strings and
        prefixed with `[SECURESTRING]`. The conversion is recursive for any nested objects. The function allows
        converting back using `ConvertFrom-ContextJson`.

        .EXAMPLE
        ConvertTo-ContextJson -Context ([pscustomobject]@{
            Name = 'MySecret'
            AccessToken = '123123123' | ConvertTo-SecureString -AsPlainText -Force
        }) -ID 'CTX-001'

        Output:
        ```json
        {
            "Name": "MySecret",
            "AccessToken": "[SECURESTRING]123123123",
            "ID": "CTX-001"
        }
        ```

        Converts the given object into a JSON string, ensuring SecureStrings are handled properly.

        .OUTPUTS
        System.String

        .NOTES
        A JSON string representation of the provided object, including secure string transformations.

        .LINK
        https://psmodule.io/Context/Functions/ConvertTo-ContextJson
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param (
        # The object to convert to a Context JSON string.
        [Parameter()]
        [object] $Context = @{},

        # The ID of the context.
        [Parameter(Mandatory)]
        [string] $ID
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Start"
    }

    process {
        try {
            $processedObject = Convert-ContextObjectToHashtableRecursive $Context
            $processedObject['ID'] = $ID
            return ($processedObject | ConvertTo-Json -Depth 100 -Compress)
        } catch {
            Write-Error $_
            throw 'Failed to convert object to JSON'
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
Write-Debug "[$scriptName] - [functions] - [private] - [ObjectToJson] - [ConvertTo-ContextJson] - Done"
#endregion [functions] - [private] - [ObjectToJson] - [ConvertTo-ContextJson]
Write-Debug "[$scriptName] - [functions] - [private] - [ObjectToJson] - Done"
#endregion [functions] - [private] - [ObjectToJson]
#region    [functions] - [private] - [Utilities]
Write-Debug "[$scriptName] - [functions] - [private] - [Utilities] - Processing folder"
#region    [functions] - [private] - [Utilities] - [PowerShell]
Write-Debug "[$scriptName] - [functions] - [private] - [Utilities] - [PowerShell] - Processing folder"
#region    [functions] - [private] - [Utilities] - [PowerShell] - [Get-PSCallStackPath]
Write-Debug "[$scriptName] - [functions] - [private] - [Utilities] - [PowerShell] - [Get-PSCallStackPath] - Importing"
function Get-PSCallStackPath {
    <#
        .SYNOPSIS
        Creates a string representation of the current call stack.

        .DESCRIPTION
        This function generates a string representation of the current call stack.
        It allows skipping the first and last elements of the call stack using the `SkipFirst`
        and `SkipLatest` parameters. By default, it skips the first function (typically `<ScriptBlock>`)
        and the last function (`Get-PSCallStackPath`) to present a cleaner view of the actual call stack.

        .EXAMPLE
        Get-PSCallStackPath

        Output:
        ```powershell
        First-Function\Second-Function\Third-Function
        ```

        Returns the call stack with the first (`<ScriptBlock>`) and last (`Get-PSCallStackPath`)
        functions removed.

        .EXAMPLE
        Get-PSCallStackPath -SkipFirst 0

        Output:
        ```powershell
        <ScriptBlock>\First-Function\Second-Function\Third-Function
        ```

        Includes the first function (typically `<ScriptBlock>`) in the call stack output.

        .EXAMPLE
        Get-PSCallStackPath -SkipLatest 0

        Output:
        ```powershell
        First-Function\Second-Function\Third-Function\Get-PSCallStackPath
        ```

        Includes the last function (`Get-PSCallStackPath`) in the call stack output.

        .OUTPUTS
        System.String

        .NOTES
        A string representing the call stack path, with function names separated by backslashes.

        .LINK
        https://psmodule.io/PSCallStack/Functions/Get-PSCallStackPath/
    #>
    [CmdletBinding()]
    param(
        # The number of functions to skip from the last function called.
        # The last function in the stack is this function (`Get-PSCallStackPath`).
        [Parameter()]
        [int] $SkipLatest = 1,

        # The number of functions to skip from the first function called.
        # The first function is typically `<ScriptBlock>`.
        [Parameter()]
        [int] $SkipFirst = 1
    )

    $skipFirst++
    $cmds = (Get-PSCallStack).Command
    $functionPath = $cmds[($cmds.Count - $skipFirst)..$SkipLatest] -join '\'
    $functionPath = $functionPath -replace '^.*<ScriptBlock>\\'
    $functionPath = $functionPath -replace '^.*.ps1\\'
    return $functionPath
}
Write-Debug "[$scriptName] - [functions] - [private] - [Utilities] - [PowerShell] - [Get-PSCallStackPath] - Done"
#endregion [functions] - [private] - [Utilities] - [PowerShell] - [Get-PSCallStackPath]
Write-Debug "[$scriptName] - [functions] - [private] - [Utilities] - [PowerShell] - Done"
#endregion [functions] - [private] - [Utilities] - [PowerShell]
Write-Debug "[$scriptName] - [functions] - [private] - [Utilities] - Done"
#endregion [functions] - [private] - [Utilities]
Write-Debug "[$scriptName] - [functions] - [private] - Done"
#endregion [functions] - [private]
#region    [functions] - [public]
Write-Debug "[$scriptName] - [functions] - [public] - Processing folder"
#region    [functions] - [public] - [completers]
Write-Debug "[$scriptName] - [functions] - [public] - [completers] - Importing"
$contextIDCompleter = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $null = $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter
    $vault = $fakeBoundParameter['Vault']
    $contextInfos = if ($vault) {
        Get-ContextInfo -Vault $vault -ErrorAction SilentlyContinue -Verbose:$false -Debug:$false
    } else {
        Get-ContextInfo -ErrorAction SilentlyContinue -Verbose:$false -Debug:$false
    }
    $contextInfos | Where-Object { $_.ID -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.ID, $_.ID, 'ParameterValue', $_.ID)
    }
}

Register-ArgumentCompleter -CommandName $script:PSModuleInfo.FunctionsToExport -ParameterName 'ID' -ScriptBlock $contextIDCompleter
Write-Debug "[$scriptName] - [functions] - [public] - [completers] - Done"
#endregion [functions] - [public] - [completers]
#region    [functions] - [public] - [Get-Context]
Write-Debug "[$scriptName] - [functions] - [public] - [Get-Context] - Importing"
#Requires -Modules @{ ModuleName = 'Sodium'; RequiredVersion = '2.2.0' }

function Get-Context {
    <#
        .SYNOPSIS
        Retrieves a context from the context vault.

        .DESCRIPTION
        Retrieves a context by reading and decrypting context files directly from the vault directory.
        If no ID is specified, all available contexts will be returned.
        Wildcards are supported to match multiple contexts.

        .EXAMPLE
        Get-Context

        Output:
        ```powershell
        Repositories      : {@{Languages=System.Object[]; IsPrivate=False; Stars=130;
                            CreatedDate=2/9/2024 10:45:11 AM; Name=Repo2}}
        AccessScopes      : {repo, user, gist, admin:org}
        AuthToken         : MyFirstSuperSecretToken
        TwoFactorMethods  : {TOTP, SMS}
        IsTwoFactorAuth   : True
        ApiRateLimits     : @{ResetTime=2/9/2025 11:15:11 AM; Remaining=4985; Limit=5000}
        UserPreferences   : @{CodeReview=System.Object[]; Notifications=; Theme=dark; DefaultBranch=main}
        SessionMetaData   : @{Device=Windows-PC; Location=; BrowserInfo=; SessionID=sess_abc123}
        LastLoginAttempts : {@{Success=True; Timestamp=2/9/2025 9:45:11 AM; IP=192.168.1.101}, @{Success=False}}
        ID                : GitHub/User-3
        Username          : john_doe
        LoginTime         : 2/9/2025 10:45:11 AM

        Repositories      : {@{Languages=System.Object[]; IsPrivate=False; Stars=130;
                            CreatedDate=2/9/2024 10:45:11 AM; Name=Repo2}}
        AccessScopes      : {repo, user, gist, admin:org}
        AuthToken         : MySuperSecretToken
        TwoFactorMethods  : {TOTP, SMS}
        IsTwoFactorAuth   : True
        ApiRateLimits     : @{ResetTime=2/9/2025 11:15:11 AM; Remaining=4985; Limit=5000}
        UserPreferences   : @{CodeReview=System.Object[]; Notifications=; Theme=dark; DefaultBranch=main}
        SessionMetaData   : @{Device=Windows-PC; Location=; BrowserInfo=; SessionID=sess_abc123}
        LastLoginAttempts : {@{Success=True; Timestamp=2/9/2025 9:45:11 AM; IP=192.168.1.101}, @{Success=False}}
        ID                : GitHub/User-8
        Username          : jane_doe
        LoginTime         : 2/9/2025 10:45:11 AM
        ```

        Retrieves all contexts from the context vault (directly from disk).

        .EXAMPLE
        Get-Context -Vault 'MyModule'

        Retrieves all contexts from the 'MyModule' vault.

        .EXAMPLE
        Get-Context -ID 'MySecret' -Vault 'MyModule'

        Retrieves the context called 'MySecret' from the 'MyModule' vault.

        .EXAMPLE
        'My*' | Get-Context -Vault 'MyModule'

        Output:
        ```powershell
        ID        : MyConfig
        Config    : {ConfigKey=ConfigValue}

        ID        : MySecret
        Key       : EncryptedValue
        AuthToken : EncryptedToken
        Favorite  : {Color=Blue; Number=7}

        ID        : MySettings
        Setting   : {SettingKey=SettingValue}
        Config    : {ConfigKey=ConfigValue}
        YourData  : {DataKey=DataValue}
        ```

        Retrieves all contexts that start with 'My' from the context vault (directly from disk).

        .OUTPUTS
        [System.Object]

        .NOTES
        Returns a list of contexts matching the specified ID or all contexts if no ID is specified.
        Each context object contains its ID and corresponding stored properties.

        .LINK
        https://psmodule.io/Context/Functions/Get-Context/
    #>
    [OutputType([object])]
    [CmdletBinding()]
    param(
        # The name of the context to retrieve from the vault. Supports wildcards.
        [Parameter(
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [SupportsWildcards()]
        [string[]] $ID = '*',

        # The name of the vault to store the context in.
        [Parameter()]
        [SupportsWildcards()]
        [string[]] $Vault = '*'
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
    }

    process {
        $contextInfos = Get-ContextInfo -ID $ID -Vault $Vault -ErrorAction Stop
        foreach ($contextInfo in $contextInfos) {
            Write-Verbose "Retrieving context - ID: [$($contextInfo.ID)], Vault: [$($contextInfo.Vault)]"
            try {
                if (-not (Test-Path -Path $contextInfo.Path)) {
                    Write-Warning "Context file does not exist: $($contextInfo.Path)"
                    continue
                }
                $keys = Get-ContextVaultKeyPair -Vault $contextInfo.Vault
                $params = @{
                    SealedBox  = $contextInfo.Context
                    PublicKey  = $keys.PublicKey
                    PrivateKey = $keys.PrivateKey
                }
                $contextObj = ConvertFrom-SodiumSealedBox @params
                ConvertFrom-ContextJson -JsonString $contextObj
            } catch {
                Write-Warning "Failed to read or decrypt context file: $($contextInfo.Path). Error: $_"
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Get-Context] - Done"
#endregion [functions] - [public] - [Get-Context]
#region    [functions] - [public] - [Get-ContextInfo]
Write-Debug "[$scriptName] - [functions] - [public] - [Get-ContextInfo] - Importing"
function Get-ContextInfo {
    <#
        .SYNOPSIS
        Retrieves info about a context from a context vault.

        .DESCRIPTION
        Retrieves info about contexts directly from a ContextVault.
        If no ID is specified, info on all contexts will be returned.
        Wildcards are supported to match multiple contexts.
        Only metadata (ID and Path) is returned without decrypting the context contents.

        .EXAMPLE
        Get-ContextInfo

        Output:
        ```powershell
        ID                 Vault
        --                 -----
        MySettings         MyVault
        MyConfig           MyVault
        MySecret           MyVault
        Data               MyVault
        PSModule.GitHub    MyVault
        ```

        Retrieves all contexts from the context vault (directly from disk).

        .EXAMPLE
        Get-ContextInfo -ID 'MySecret'

        Output:
        ```powershell
        ID   : MySecret
        Path : ...\3e223259-f242-4e97-91c8-f0fd054cfea7.json
        ```

        Retrieves the context called 'MySecret' from the context vault (directly from disk).

        .EXAMPLE
        'My*' | Get-ContextInfo

        Output:
        ```powershell
        ID                 Vault
        --                 -----
        MyConfig           MyVault
        MySecret           MyVault
        MySettings         MyVault
        ```

        Retrieves all contexts that start with 'My' from the context vault (directly from disk).

        .OUTPUTS
        [ContextInfo]

        .NOTES
        Returns a list of context information matching the specified ID or all contexts if no ID is specified.
        Each context object contains its ID and corresponding path to where the context is stored on disk.

        .LINK
        https://psmodule.io/Context/Functions/Get-ContextInfo/
    #>
    [OutputType([ContextInfo])]
    [CmdletBinding()]
    param(
        # The name of the context to retrieve from the vault. Supports wildcards.
        [Parameter()]
        [SupportsWildcards()]
        [string[]] $ID = '*',

        # The name of the vault to retrieve context info from. Supports wildcards.
        [Parameter()]
        [string[]] $Vault = '*'
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
    }

    process {
        $vaults = foreach ($vaultName in $Vault) {
            Get-ContextVault -Name $vaultName -ErrorAction Stop
        }
        Write-Verbose "[$stackPath] - Found $($vaults.Count) vault(s) matching '$($Vault -join ', ')'."

        $files = foreach ($vaultObject in $vaults) {
            Get-ChildItem -Path $vaultObject.Path -Filter *.json -File
        }
        Write-Verbose "[$stackPath] - Found $($files.Count) context file(s) in vault(s)."

        foreach ($file in $files) {
            $contextInfo = Get-Content -Path $file.FullName | ConvertFrom-Json
            Write-Verbose "[$stackPath] - Processing file: $($file.FullName)"
            $contextInfo | Format-List | Out-String -Stream | ForEach-Object { Write-Verbose "[$stackPath]   $_" }
            foreach ($IDItem in $ID) {
                if ($contextInfo.ID -like $IDItem) {
                    [ContextInfo]::new($contextInfo)
                }
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Get-ContextInfo] - Done"
#endregion [functions] - [public] - [Get-ContextInfo]
#region    [functions] - [public] - [Remove-Context]
Write-Debug "[$scriptName] - [functions] - [public] - [Remove-Context] - Importing"
function Remove-Context {
    <#
        .SYNOPSIS
        Removes a context from the context vault.

        .DESCRIPTION
        This function removes a context (or multiple contexts) from the vault. It supports:
        - Supply one or more IDs as strings (e.g. -ID 'Ctx1','Ctx2')
        - Supply objects that contain an ID property

        The function accepts pipeline input for easier batch removal.

        .EXAMPLE
        Remove-Context -ID 'MySecret' -Vault "MyModule"

        Output:
        ```powershell
        Removing context [MySecret]
        Removed item: MySecret
        ```

        Removes a context called 'MySecret' from the "MyModule" vault by specifying its ID.

        .EXAMPLE
        Remove-Context -ID 'Ctx1','Ctx2'

        Output:
        ```powershell
        Removing context [Ctx1]
        Removed item: Ctx1
        Removing context [Ctx2]
        Removed item: Ctx2
        ```

        Removes two contexts, 'Ctx1' and 'Ctx2'.

        .EXAMPLE
        'Ctx1','Ctx2' | Remove-Context

        Output:
        ```powershell
        Removing context [Ctx1]
        Removed item: Ctx1
        Removing context [Ctx2]
        Removed item: Ctx2
        ```

        Removes two contexts, 'Ctx1' and 'Ctx2' via pipeline input.

        .EXAMPLE
        $ctxList = @(
            [PSCustomObject]@{ ID = 'Ctx1' },
            [PSCustomObject]@{ ID = 'Ctx2' }
        )
        $ctxList | Remove-Context

        Output:
        ```powershell
        Removing context [Ctx1]
        Removed item: Ctx1
        Removing context [Ctx2]
        Removed item: Ctx2
        ```

        Accepts pipeline input: multiple objects each having an ID property.

        .OUTPUTS
        [System.String]

        .NOTES
        Returns the name of each removed context if successful.

        .LINK
        https://psmodule.io/Context/Functions/Remove-Context/
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        # One or more IDs as strings of the contexts to remove.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [SupportsWildcards()]
        [string[]] $ID,

        # The name of the vault to remove contexts from.
        [Parameter()]
        [string] $Vault
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
    }

    process {
        $contextInfo = Get-ContextInfo -ID $ID -Vault $Vault
        foreach ($contextInfo in $contextInfo) {
            $contextId = $contextInfo.ID

            if ($PSCmdlet.ShouldProcess("Context '$contextId'", 'Remove')) {
                Write-Verbose "[$stackPath] - Removing context [$contextId]"
                $contextInfo.Path | Remove-Item -Force -ErrorAction Stop
                Write-Verbose "[$stackPath] - Removed item: $contextId"
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Remove-Context] - Done"
#endregion [functions] - [public] - [Remove-Context]
#region    [functions] - [public] - [Rename-Context]
Write-Debug "[$scriptName] - [functions] - [public] - [Rename-Context] - Importing"
function Rename-Context {
    <#
        .SYNOPSIS
        Renames a context.

        .DESCRIPTION
        This function renames a context by retrieving the existing context with the old ID,
        setting the new context with the provided new ID, and removing the old context.
        If a context with the new ID already exists, the operation will fail unless
        the `-Force` switch is specified.

        .EXAMPLE
        Rename-Context -ID 'PSModule.GitHub' -NewID 'PSModule.GitHub2'

        Output:
        ```powershell
        Context 'PSModule.GitHub' renamed to 'PSModule.GitHub2'
        ```

        Renames the context 'PSModule.GitHub' to 'PSModule.GitHub2'.

        .EXAMPLE
        'PSModule.GitHub' | Rename-Context -NewID 'PSModule.GitHub2'

        Output:
        ```powershell
        Context 'PSModule.GitHub' renamed to 'PSModule.GitHub2'
        ```

        Renames the context 'PSModule.GitHub' to 'PSModule.GitHub2' using pipeline input.

        .OUTPUTS
        object

        .NOTES
        The confirmation message indicating the successful renaming of the context.

        .LINK
        https://psmodule.io/Context/Functions/Rename-Context/
    #>
    [OutputType([object])]
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # The ID of the context to rename.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string] $ID,

        # The new ID of the context.
        [Parameter(Mandatory)]
        [string] $NewID,

        # Force the rename even if the new ID already exists.
        [Parameter()]
        [switch] $Force,

        # The name of the vault containing the context.
        [Parameter()]
        [string] $Vault,

        # Pass the context through the pipeline.
        [Parameter()]
        [switch] $PassThru
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
    }

    process {
        $context = Get-Context -ID $ID -Vault $Vault
        if (-not $context) {
            throw "Context with ID '$ID' not found in vault '$Vault'"
        }

        $existingContext = Get-Context -ID $NewID -Vault $Vault
        if ($existingContext -and -not $Force) {
            throw "Context with ID '$NewID' already exists in vault '$Vault'"
        }

        if ($PSCmdlet.ShouldProcess("Renaming context '$ID' to '$NewID' in vault '$Vault'")) {
            $context | Set-Context -ID $NewID -Vault $Vault -PassThru:$PassThru
            Remove-Context -ID $ID -Vault $Vault
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Rename-Context] - Done"
#endregion [functions] - [public] - [Rename-Context]
#region    [functions] - [public] - [Set-Context]
Write-Debug "[$scriptName] - [functions] - [public] - [Set-Context] - Importing"
#Requires -Modules @{ ModuleName = 'Sodium'; RequiredVersion = '2.2.0' }

function Set-Context {
    <#
        .SYNOPSIS
        Set a context in a context vault.

        .DESCRIPTION
        If the context does not exist, it will be created. If it already exists, it will be updated.
        The context is encrypted and stored on disk. If the context vault does not exist, it will be created.

        .EXAMPLE
        Set-Context -ID 'MyUser' -Context @{ Name = 'MyUser' } -Vault 'MyModule'

        Output:
        ```powershell
        ID      : MyUser
        Path    : C:\Vault\Guid.json
        Context : @{ Name = 'MyUser' }
        ```

        Creates a context called 'MyUser' in the 'MyModule' vault.

        .EXAMPLE
        $context = @{
            ID          = 'MySecret'
            Name        = 'SomeSecretIHave'
            AccessToken = '123123123' | ConvertTo-SecureString -AsPlainText -Force
        }
        $context | Set-Context

        Output:
        ```powershell
        ID      : MyUser
        Path    : C:\Vault\Guid.json
        Context : {
            ID          = MySecret
            Name        = MyUser
            AccessToken = System.Security.SecureString
        }
        ```

        Sets a context using a hashtable object.

        .OUTPUTS
        [PSCustomObject]

        .NOTES
        Returns an object representing the stored or updated context.
        The object includes the ID, path, and securely stored context information.

        .LINK
        https://psmodule.io/Context/Functions/Set-Context/
    #>
    [Alias('New-Context', 'Update-Context')]
    [OutputType([PSCustomObject])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The ID of the context.
        [Parameter()]
        [string] $ID,

        # The data of the context.
        [Parameter(ValueFromPipeline)]
        [object] $Context = @{},

        # The name of the vault to store the context in.
        [Parameter(Mandatory)]
        [string] $Vault,

        # Pass the context through the pipeline.
        [Parameter()]
        [switch] $PassThru
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
    }

    process {
        $vaultObject = Set-ContextVault -Name $Vault -PassThru
        $vaultObject | Format-List | Out-String -Stream | ForEach-Object { Write-Verbose "[$stackPath]   $_" }

        if ($context -is [System.Collections.IDictionary]) {
            $Context = [PSCustomObject]$Context
        }

        if (-not $ID) {
            $ID = $Context.ID
        }
        if (-not $ID) {
            throw 'An ID is required, either as a parameter or as a property of the context object.'
        }

        $contextInfo = Get-ContextInfo -ID $ID -Vault $Vault
        Write-Verbose 'Context info:'
        $contextInfo | Format-List | Out-String -Stream | ForEach-Object { Write-Verbose "[$stackPath]   $_" }
        if (-not $contextInfo) {
            Write-Verbose "[$stackPath] - Creating context [$ID] in [$Vault]"
            $guid = [Guid]::NewGuid().Guid
            $contextPath = Join-Path -Path $vaultObject.Path -ChildPath "$guid.json"
        } else {
            Write-Verbose "[$stackPath] - Context [$ID] found in [$Vault]"
            $contextPath = $contextInfo.Path
        }
        Write-Verbose "[$stackPath] - Context path: [$contextPath]"

        $contextJson = ConvertTo-ContextJson -Context $Context -ID $ID
        $keys = Get-ContextVaultKeyPair -Vault $Vault
        $content = [pscustomobject]@{
            ID      = $ID
            Path    = $contextPath
            Vault   = $Vault
            Context = ConvertTo-SodiumSealedBox -Message $contextJson -PublicKey $keys.PublicKey
        } | ConvertTo-Json -Depth 5
        Write-Verbose 'Content:'
        $content | ConvertTo-Json -Depth 5 | Out-String -Stream | ForEach-Object { Write-Verbose "[$stackPath]   $_" }

        if ($PSCmdlet.ShouldProcess("file: [$contextPath]", 'Set content')) {
            Write-Verbose "[$stackPath] - Setting context [$ID] in vault [$Vault]"
            Set-Content -Path $contextPath -Value $content
        }

        if ($PassThru) {
            Get-Context -ID $ID -Vault $Vault
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Set-Context] - Done"
#endregion [functions] - [public] - [Set-Context]
#region    [functions] - [public] - [Vault]
Write-Debug "[$scriptName] - [functions] - [public] - [Vault] - Processing folder"
#region    [functions] - [public] - [Vault] - [completers]
Write-Debug "[$scriptName] - [functions] - [public] - [Vault] - [completers] - Importing"
$contextVaultNameCompleter = {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $null = $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter
    $vaults = Get-ContextVault -ErrorAction SilentlyContinue -Verbose:$false -Debug:$false
    $vaults | Where-Object { $_.Name -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_.Name, $_.Name, 'ParameterValue', $_.Name)
    }
}

$contextVaultFunctions = ($script:PSModuleInfo.FunctionsToExport | Where-Object { $_ -like '*ContextVault*' })

Register-ArgumentCompleter -CommandName $script:PSModuleInfo.FunctionsToExport -ParameterName 'Vault' -ScriptBlock $contextVaultNameCompleter
Register-ArgumentCompleter -CommandName $contextVaultFunctions -ParameterName 'Name' -ScriptBlock $contextVaultNameCompleter
Write-Debug "[$scriptName] - [functions] - [public] - [Vault] - [completers] - Done"
#endregion [functions] - [public] - [Vault] - [completers]
#region    [functions] - [public] - [Vault] - [Get-ContextVault]
Write-Debug "[$scriptName] - [functions] - [public] - [Vault] - [Get-ContextVault] - Importing"
function Get-ContextVault {
    <#
        .SYNOPSIS
        Retrieves context vaults.

        .DESCRIPTION
        Retrieves context vaults. If no name is specified, all available vaults will be returned. Supports wildcard matching.

        .EXAMPLE
        Get-ContextVault

        Lists all available context vaults.

        .EXAMPLE
        Get-ContextVault -Name 'MyModule'

        Gets information about the 'MyModule' vault.

        .EXAMPLE
        Get-ContextVault -Name 'My*'

        Gets information about all vaults starting with 'My'.

        .OUTPUTS
        [ContextVault]

        .LINK
        https://psmodule.io/Context/Functions/Vault/Get-ContextVault/
    #>
    [OutputType([ContextVault])]
    [CmdletBinding()]
    param(
        # The name of the vault to retrieve. Supports wildcards.
        [Parameter()]
        [SupportsWildcards()]
        [string[]] $Name = '*'
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
        if (-not (Test-Path -Path $script:Config.RootPath)) {
            return
        }
        $vaults = Get-ChildItem $script:Config.RootPath -Directory
    }

    process {
        foreach ($nameItem in $Name) {
            foreach ($vault in ($vaults | Where-Object { $_.Name -like $nameItem })) {
                [ContextVault]::new($vault.Name, $vault.FullName)
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Vault] - [Get-ContextVault] - Done"
#endregion [functions] - [public] - [Vault] - [Get-ContextVault]
#region    [functions] - [public] - [Vault] - [Remove-ContextVault]
Write-Debug "[$scriptName] - [functions] - [public] - [Vault] - [Remove-ContextVault] - Importing"
function Remove-ContextVault {
    <#
        .SYNOPSIS
        Removes a context vault.

        .DESCRIPTION
        Removes an existing context vault and all its context data. This operation
        is irreversible and will delete all contexts stored in the vault.

        .EXAMPLE
        Remove-ContextVault -Name 'OldModule'

        Removes the 'OldModule' vault and all its contexts.

        .LINK
        https://psmodule.io/Context/Functions/Vault/Remove-ContextVault/
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        # The name of the vault to remove.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'By Name')]
        [SupportsWildcards()]
        [string[]] $Name,

        # The vault object to remove.
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'As ContextVault')]
        [ContextVault[]] $InputObject
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
        $vaults = Get-ContextVault
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'By Name' {
                foreach ($vaultName in $Name) {
                    foreach ($vault in ($vaults | Where-Object { $_.Name -like $vaultName })) {
                        Write-Verbose "Removing ContextVault [$($vault.Name)] at path [$($vault.Path)]"
                        if ($PSCmdlet.ShouldProcess("ContextVault: [$($vault.Name)]", 'Remove')) {
                            Remove-Item -Path $vault.Path -Recurse -Force
                            Write-Verbose "ContextVault [$($vault.Name)] removed successfully."
                        }
                    }
                }
            }
            'As ContextVault' {
                $InputObject.Name | Remove-ContextVault
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Vault] - [Remove-ContextVault] - Done"
#endregion [functions] - [public] - [Vault] - [Remove-ContextVault]
#region    [functions] - [public] - [Vault] - [Reset-ContextVault]
Write-Debug "[$scriptName] - [functions] - [public] - [Vault] - [Reset-ContextVault] - Importing"
function Reset-ContextVault {
    <#
        .SYNOPSIS
        Resets a context vault.

        .DESCRIPTION
        Resets an existing context vault by deleting all contexts and regenerating
        the encryption keys. The vault configuration and name are preserved.

        .EXAMPLE
        Reset-ContextVault -Name 'MyModule'

        Resets the 'MyModule' vault, deleting all contexts and regenerating encryption keys.

        .OUTPUTS
        [ContextVault]

        .LINK
        https://psmodule.io/Context/Functions/Vault/Reset-ContextVault/
    #>
    [OutputType([ContextVault])]
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param(
        # The name of the vault to reset.
        [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = 'By Name')]
        [SupportsWildcards()]
        [string[]] $Name = '*',

        # The vault object to reset.
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'As ContextVault')]
        [ContextVault[]] $InputObject,

        # Pass the context through the pipeline.
        [Parameter()]
        [switch] $PassThru
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
        $vaults = Get-ContextVault
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'By Name' {
                foreach ($vaultName in $Name) {
                    foreach ($vault in ($vaults | Where-Object { $_.Name -like $vaultName })) {
                        Write-Verbose "Resetting ContextVault [$($vault.Name)] at path [$($vault.Path)]"
                        if ($PSCmdlet.ShouldProcess("ContextVault: [$($vault.Name)]", 'Reset')) {
                            Remove-ContextVault -Name $($vault.Name) -Confirm:$false
                            Set-ContextVault -Name $($vault.Name) -PassThru:$PassThru
                            Write-Verbose "ContextVault [$($vault.Name)] reset successfully."
                        }
                    }
                }
            }
            'As ContextVault' {
                $InputObject.Name | Reset-ContextVault
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Vault] - [Reset-ContextVault] - Done"
#endregion [functions] - [public] - [Vault] - [Reset-ContextVault]
#region    [functions] - [public] - [Vault] - [Set-ContextVault]
Write-Debug "[$scriptName] - [functions] - [public] - [Vault] - [Set-ContextVault] - Importing"
function Set-ContextVault {
    <#
        .SYNOPSIS
        Creates or updates a context vault configuration.

        .DESCRIPTION
        Declaratively creates or updates a context vault configuration. If the vault exists,
        its configuration is updated with the provided parameters. If the vault does not exist,
        it is created with the specified configuration.

        .EXAMPLE
        Set-ContextVault -Name 'MyModule'

        Creates a new vault named 'MyModule' or updates its description if it already exists.

        .OUTPUTS
        [ContextVault]

        .LINK
        https://psmodule.io/Context/Functions/Vault/Set-ContextVault/
    #>
    [OutputType([ContextVault])]
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The name of the vault to create or update.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string[]] $Name,

        # Pass the context through the pipeline.
        [Parameter()]
        [switch] $PassThru
    )

    begin {
        $stackPath = Get-PSCallStackPath
        Write-Debug "[$stackPath] - Begin"
    }

    process {
        foreach ($vaultName in $Name) {
            Write-Verbose "Processing vault: $vaultName"

            $vaultPath = Join-Path -Path $script:Config.RootPath -ChildPath $vaultName
            if (-not (Test-Path $vaultPath)) {
                Write-Verbose "Creating new vault [$($vault.Name)]"
                if ($PSCmdlet.ShouldProcess("context vault folder $vaultName", 'Set')) {
                    $null = New-Item -Path $vaultPath -ItemType Directory -Force
                }
            }
            $fileShardPath = Join-Path -Path $vaultPath -ChildPath $script:Config.ShardFileName
            if (-not (Test-Path $fileShardPath)) {
                Write-Verbose "Generating encryption keys for vault [$($vault.Name)]"
                if ($PSCmdlet.ShouldProcess("shard file $fileShardPath", 'Set')) {
                    Set-Content -Path $fileShardPath -Value ([System.Guid]::NewGuid().ToString())
                }
            }

            if ($PassThru) {
                [ContextVault]::new($vaultName, $vaultPath)
            }
        }
    }

    end {
        Write-Debug "[$stackPath] - End"
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Vault] - [Set-ContextVault] - Done"
#endregion [functions] - [public] - [Vault] - [Set-ContextVault]
Write-Debug "[$scriptName] - [functions] - [public] - [Vault] - Done"
#endregion [functions] - [public] - [Vault]
Write-Debug "[$scriptName] - [functions] - [public] - Done"
#endregion [functions] - [public]
#region    [variables] - [private]
Write-Debug "[$scriptName] - [variables] - [private] - Processing folder"
#region    [variables] - [private] - [Config]
Write-Debug "[$scriptName] - [variables] - [private] - [Config] - Importing"
$script:Config = [pscustomobject]@{
    RootPath      = Join-Path -Path $HOME -ChildPath '.contextvaults'        # Base directory for context vaults
    ShardFileName = 'shard'                                                  # Shard path (relative to each vault)
}
Write-Debug "[$scriptName] - [variables] - [private] - [Config] - Done"
#endregion [variables] - [private] - [Config]
Write-Debug "[$scriptName] - [variables] - [private] - Done"
#endregion [variables] - [private]
#region    Class exporter
# Get the internal TypeAccelerators class to use its static methods.
$TypeAcceleratorsClass = [psobject].Assembly.GetType(
    'System.Management.Automation.TypeAccelerators'
)
# Ensure none of the types would clobber an existing type accelerator.
# If a type accelerator with the same name exists, throw an exception.
$ExistingTypeAccelerators = $TypeAcceleratorsClass::Get
# Define the types to export with type accelerators.
$ExportableEnums = @(
)
$ExportableEnums | Foreach-Object { Write-Verbose "Exporting enum '$($_.FullName)'." }
foreach ($Type in $ExportableEnums) {
    if ($Type.FullName -in $ExistingTypeAccelerators.Keys) {
        Write-Verbose "Enum already exists [$($Type.FullName)]. Skipping."
    } else {
        Write-Verbose "Importing enum '$Type'."
        $TypeAcceleratorsClass::Add($Type.FullName, $Type)
    }
}
$ExportableClasses = @(
    [ContextInfo]
    [ContextVault]
)
$ExportableClasses | Foreach-Object { Write-Verbose "Exporting class '$($_.FullName)'." }
foreach ($Type in $ExportableClasses) {
    if ($Type.FullName -in $ExistingTypeAccelerators.Keys) {
        Write-Verbose "Class already exists [$($Type.FullName)]. Skipping."
    } else {
        Write-Verbose "Importing class '$Type'."
        $TypeAcceleratorsClass::Add($Type.FullName, $Type)
    }
}

# Remove type accelerators when the module is removed.
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    foreach ($Type in ($ExportableEnums + $ExportableClasses)) {
        $null = $TypeAcceleratorsClass::Remove($Type.FullName)
    }
}.GetNewClosure()
#endregion Class exporter
#region    Member exporter
$exports = @{
    Alias    = '*'
    Cmdlet   = ''
    Function = @(
        'Get-ContextVault'
        'Remove-ContextVault'
        'Reset-ContextVault'
        'Set-ContextVault'
        'Get-Context'
        'Get-ContextInfo'
        'Remove-Context'
        'Rename-Context'
        'Set-Context'
    )
    Variable = ''
}
Export-ModuleMember @exports
#endregion Member exporter

