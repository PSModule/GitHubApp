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

#region    [functions] - [private]
Write-Debug "[$scriptName] - [functions] - [private] - Processing folder"
#region    [functions] - [private] - [Assert-VisualCRedistributableInstalled]
Write-Debug "[$scriptName] - [functions] - [private] - [Assert-VisualCRedistributableInstalled] - Importing"
function Assert-VisualCRedistributableInstalled {
    <#
        .SYNOPSIS
        Determines if a version of the Visual C++ Redistributable is installed and meets the specified minimum version.

        .DESCRIPTION
        This function checks whether the Visual C++ Redistributable for Visual Studio 2015 or later is installed on
        the system and ensures that the installed version is greater than or equal to the specified minimum version.
        If the required version is not found, a warning is displayed, suggesting where to download the latest
        redistributable package.

        .EXAMPLE
        Assert-VisualCRedistributableInstalled -Version '14.29.30037'

        Output:
        ```powershell
        True
        ```

        Checks if the installed Visual C++ Redistributable version is at least 14.29.30037 and returns `$true`
        if the requirement is met.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        # The minimum required version of the Visual C++ Redistributable.
        [Parameter(Mandatory)]
        [Version] $Version
    )

    process {
        $result = $false
        if ($IsWindows) {
            $key = 'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\X64'
            if (Test-Path -Path $key) {
                $installedVersion = (Get-ItemProperty -Path $key).Version
                $result = [Version]($installedVersion.SubString(1, $installedVersion.Length - 1)) -ge $Version
            }
        }
        if (-not $result) {
            Write-Warning 'The Visual C++ Redistributable for Visual Studio 2015 or later is required.'
            Write-Warning 'Download and install the appropriate version from:'
            Write-Warning ' - https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads'
        }
        $result
    }
}
Write-Debug "[$scriptName] - [functions] - [private] - [Assert-VisualCRedistributableInstalled] - Done"
#endregion [functions] - [private] - [Assert-VisualCRedistributableInstalled]
Write-Debug "[$scriptName] - [functions] - [private] - Done"
#endregion [functions] - [private]
#region    [functions] - [public]
Write-Debug "[$scriptName] - [functions] - [public] - Processing folder"
#region    [functions] - [public] - [ConvertFrom-SodiumSealedBox]
Write-Debug "[$scriptName] - [functions] - [public] - [ConvertFrom-SodiumSealedBox] - Importing"
function ConvertFrom-SodiumSealedBox {
    <#
        .SYNOPSIS
        Decrypts a base64-encoded, Sodium SealedBox-encrypted string.

        .DESCRIPTION
        Converts a base64-encoded, Sodium SealedBox-encrypted string into its original plaintext form.
        Uses the provided public and private keys to decrypt the sealed message.

        .EXAMPLE
        $params = @{
            SealedBox       = $encryptedMessage
            PublicKey       = $publicKey
            PrivateKey      = $privateKey
        }
        ConvertFrom-SodiumSealedBox @params

        Output:
        ```powershell
        Secret message revealed!
        ```

        Decrypts the given encrypted message using the specified public and private keys and returns the original string.

        .EXAMPLE
        $encryptedMessage | ConvertFrom-SodiumSealedBox -PublicKey $publicKey -PrivateKey $privateKey

        Output:
        ```powershell
        Confidential Data
        ```

        Uses pipeline input to decrypt the given encrypted message with the specified keys.

        .OUTPUTS
        System.String

        .NOTES
        Returns the original plaintext string after decryption.
        If decryption fails, an exception is thrown.

        .LINK
        https://psmodule.io/Sodium/Functions/ConvertFrom-SodiumSealedBox/

        .LINK
        https://doc.libsodium.org/public-key_cryptography/sealed_boxes
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The base64-encoded encrypted secret string to decrypt.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [Alias('CipherText')]
        [string] $SealedBox,

        # The base64-encoded public key used for decryption.
        [Parameter()]
        [string] $PublicKey,

        # The base64-encoded private key used for decryption.
        [Parameter(Mandatory)]
        [string] $PrivateKey
    )

    begin {
        if (-not $script:Supported) { throw 'Sodium is not supported on this platform.' }
        $null = [PSModule.Sodium]::sodium_init()
    }

    process {
        $ciphertext = [System.Convert]::FromBase64String($SealedBox)

        $privateKeyByteArray = [System.Convert]::FromBase64String($PrivateKey)
        if ($privateKeyByteArray.Length -ne 32) { throw 'Invalid private key.' }

        if ([string]::IsNullOrWhiteSpace($PublicKey)) {
            $publicKeyByteArray = Get-SodiumPublicKey -PrivateKey $PrivateKey -AsByteArray
        } else {
            $publicKeyByteArray = [System.Convert]::FromBase64String($PublicKey)
            if ($publicKeyByteArray.Length -ne 32) { throw 'Invalid public key.' }
        }

        $overhead = [PSModule.Sodium]::crypto_box_sealbytes().ToUInt32()
        $decryptedBytes = New-Object byte[] ($ciphertext.Length - $overhead)

        $result = [PSModule.Sodium]::crypto_box_seal_open(
            $decryptedBytes, $ciphertext, [UInt64]$ciphertext.Length, $publicKeyByteArray, $privateKeyByteArray
        )

        if ($result -ne 0) {
            throw 'Decryption failed.'
        }

        return [System.Text.Encoding]::UTF8.GetString($decryptedBytes)
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [ConvertFrom-SodiumSealedBox] - Done"
#endregion [functions] - [public] - [ConvertFrom-SodiumSealedBox]
#region    [functions] - [public] - [ConvertTo-SodiumSealedBox]
Write-Debug "[$scriptName] - [functions] - [public] - [ConvertTo-SodiumSealedBox] - Importing"
function ConvertTo-SodiumSealedBox {
    <#
        .SYNOPSIS
        Encrypts a message using a sealed public key box.

        .DESCRIPTION
        This function encrypts a given message using a public key with the SealedPublicKeyBox method from the Sodium library.
        The result is a base64-encoded sealed box that can only be decrypted by the corresponding private key.

        .EXAMPLE
        ConvertTo-SodiumSealedBox -Message "Hello world!" -PublicKey $publicKey

        Output:
        ```powershell
        hhCon4PO1X0TIPeh1i4GM6Wg9HSF5ge/x4L7p1vNd3lIdiJqNmBfswkcHipyM4HUr9wDLebjARVp5tsB
        ```

        Encrypts the message "Hello world!" using the provided base64-encoded public key and returns a base64-encoded sealed box.

        .EXAMPLE
        "Sensitive Data" | ConvertTo-SodiumSealedBox -PublicKey $publicKey

        Output:
        ```powershell
        p3PGL162uLCvrsCRLUDrc/Kfc5biGVzxRDg25ZdJoR9Y6ABZUKo8pvDoOGdchv0iBYQO2LP0Q6BkVbIDBUw=
        ```

        Uses pipeline input to encrypt the provided message using the specified public key.

        .OUTPUTS
        System.String

        .NOTES
        The function returns a base64-encoded sealed box string that can only be decrypted by the corresponding private key.

        .LINK
        https://psmodule.io/Sodium/Functions/ConvertTo-SodiumSealedBox/

        .LINK
        https://doc.libsodium.org/public-key_cryptography/sealed_boxes
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The message string to be encrypted.
        [Parameter(
            Mandatory,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [string] $Message,

        # The base64-encoded public key used for encryption.
        [Parameter(Mandatory)]
        [string] $PublicKey
    )
    begin {
        if (-not $script:Supported) { throw 'Sodium is not supported on this platform.' }
        $null = [PSModule.Sodium]::sodium_init()
    }

    process {
        # Convert public key from Base64 or space-separated string
        try {
            $publicKeyByteArray = [Convert]::FromBase64String($PublicKey)
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
        if ($publicKeyByteArray.Length -ne 32) {
            throw "Invalid public key. Expected 32 bytes but got $($publicKeyByteArray.Length)."
        }

        $messageBytes = [System.Text.Encoding]::UTF8.GetBytes($Message)
        $overhead = [PSModule.Sodium]::crypto_box_sealbytes().ToUInt32()
        $cipherLength = $messageBytes.Length + $overhead
        $ciphertext = New-Object byte[] $cipherLength

        # Encrypt message
        $result = [PSModule.Sodium]::crypto_box_seal($ciphertext, $messageBytes, [uint64]$messageBytes.Length, $publicKeyByteArray)

        if ($result -ne 0) {
            throw 'Encryption failed.'
        }

        return [Convert]::ToBase64String($ciphertext)
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [ConvertTo-SodiumSealedBox] - Done"
#endregion [functions] - [public] - [ConvertTo-SodiumSealedBox]
#region    [functions] - [public] - [Get-SodiumPublicKey]
Write-Debug "[$scriptName] - [functions] - [public] - [Get-SodiumPublicKey] - Importing"
function Get-SodiumPublicKey {
    <#
        .SYNOPSIS
        Derives a Curve25519 public key from a provided private key using the Sodium cryptographic library.

        .DESCRIPTION
        Takes a base64-encoded Curve25519 private key and returns the corresponding base64-encoded public key. This is accomplished using the
        Libsodium `crypto_scalarmult_base` function provided by the PSModule.Sodium .NET wrapper. The function ensures compatibility with
        cryptographic operations requiring key exchange mechanisms.

        .EXAMPLE
        Get-SodiumPublicKey -PrivateKey 'ci5/7eZ0IbGXtqQMaNvxhJ2d9qwFxA8Kjx+vivSTXqU='

        Output:
        ```powershell
        WQakMx2mIAQMwLqiZteHUTwmMP6mUdK2FL0WEybWgB8=
        ```

        Derives and returns the public key corresponding to the given base64-encoded private key.

        .EXAMPLE
        Get-SodiumPublicKey -PrivateKey 'ci5/7eZ0IbGXtqQMaNvxhJ2d9qwFxA8Kjx+vivSTXqU=' -AsByteArray

        Output:
        ```powershell
        89
        6
        164
        51
        29
        166
        32
        4
        12
        192
        186
        162
        102
        215
        135
        81
        60
        38
        48
        254
        166
        81
        210
        182
        20
        189
        22
        19
        38
        214
        128
        31
        ```

        .OUTPUTS
        string

        .OUTPUTS
        byte[]

        .LINK
        https://psmodule.io/Sodium/Functions/Get-SodiumPublicKey/
    #>

    [OutputType([string], ParameterSetName = 'Base64')]
    [OutputType([byte[]], ParameterSetName = 'AsByteArray')]
    [CmdletBinding(DefaultParameterSetName = 'Base64')]
    [CmdletBinding()]
    param(
        # The private key to derive the public key from.
        [Parameter(Mandatory)]
        [string] $PrivateKey,

        # Returns the byte array
        [Parameter(Mandatory, ParameterSetName = 'AsByteArray')]
        [switch] $AsByteArray
    )

    begin {
        if (-not $script:Supported) { throw 'Sodium is not supported on this platform.' }
        $null = [PSModule.Sodium]::sodium_init()
    }

    process {
        $publicKeyByteArray = New-Object byte[] 32
        $privateKeyByteArray = [System.Convert]::FromBase64String($PrivateKey)
        $rc = [PSModule.Sodium]::crypto_scalarmult_base($publicKeyByteArray, $privateKeyByteArray)
        if ($rc -ne 0) { throw 'Unable to derive public key from private key.' }
    }

    end {
        if ($AsByteArray) {
            return $publicKeyByteArray
        } else {
            return [System.Convert]::ToBase64String($publicKeyByteArray)
        }
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Get-SodiumPublicKey] - Done"
#endregion [functions] - [public] - [Get-SodiumPublicKey]
#region    [functions] - [public] - [New-SodiumKeyPair]
Write-Debug "[$scriptName] - [functions] - [public] - [New-SodiumKeyPair] - Importing"
function New-SodiumKeyPair {
    <#
        .SYNOPSIS
        Generates a new Sodium key pair.

        .DESCRIPTION
        This function creates a new cryptographic key pair using Sodium's PublicKeyBox.
        The keys are returned as a PowerShell custom object, with both the public and private keys
        encoded in base64 format.

        If a seed is provided, the key pair is deterministically generated using a SHA-256 derived seed.
        This ensures that the same input seed will always produce the same key pair.

        .EXAMPLE
        New-SodiumKeyPair

        Output:
        ```powershell
        PublicKey                                    PrivateKey
        ---------                                    ----------
        Ac0wdsq6lqLGktckJrasPcTbVRuUCU+OKzVpMno+v0g= PVXI64v00+aT2b2O6Q4l+SfMBUY2R/Nogsl2mp/hXAs=
        ```

        Generates a new key pair and returns a custom object containing the base64-encoded
        public and private keys.

        .EXAMPLE
        New-SodiumKeyPair -Seed "MySecureSeed"

        Output:
        ```powershell
        PublicKey                                    PrivateKey
        ---------                                    ----------
        WQakMx2mIAQMwLqiZteHUTwmMP6mUdK2FL0WEybWgB8= ci5/7eZ0IbGXtqQMaNvxhJ2d9qwFxA8Kjx+vivSTXqU=
        ```

        Generates a deterministic key pair using the given seed string. The same seed will produce
        the same key pair every time.

        .EXAMPLE
        "MySecureSeed" | New-SodiumKeyPair

        Output:
        ```powershell
        PublicKey                                    PrivateKey
        ---------                                    ----------
        WQakMx2mIAQMwLqiZteHUTwmMP6mUdK2FL0WEybWgB8= ci5/7eZ0IbGXtqQMaNvxhJ2d9qwFxA8Kjx+vivSTXqU=
        ```

        Generates a deterministic key pair using the given seed string via pipeline. The same seed will produce
        the same key pair every time.

        .OUTPUTS

        PSCustomObject

        .NOTES
        Returns a PowerShell custom object with the following properties:
        - **PublicKey**:  The base64-encoded public key.
        - **PrivateKey**: The base64-encoded private key.
        If key generation fails, an exception is thrown.

        .LINK
        https://psmodule.io/Sodium/Functions/New-SodiumKeyPair/

        .LINK
        https://doc.libsodium.org/public-key_cryptography/public-key_signatures
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Scope = 'Function',
        Justification = 'Does not change state'
    )]
    [OutputType([PSCustomObject])]
    [CmdletBinding(DefaultParameterSetName = 'NewKeyPair')]
    param(
        # A seed value to use for key generation.
        [Parameter(
            Mandatory,
            ParameterSetName = 'SeededKeyPair',
            ValueFromPipeline
        )]
        [string] $Seed
    )

    begin {
        if (-not $script:Supported) { throw 'Sodium is not supported on this platform.' }
        $null = [PSModule.Sodium]::sodium_init()
    }

    process {
        $pkSize = [PSModule.Sodium]::crypto_box_publickeybytes().ToUInt32()
        $skSize = [PSModule.Sodium]::crypto_box_secretkeybytes().ToUInt32()
        $publicKey = New-Object byte[] $pkSize
        $privateKey = New-Object byte[] $skSize

        switch ($PSCmdlet.ParameterSetName) {
            'SeededKeyPair' {
                # Derive a 32-byte seed from the provided string seed (using SHA-256)
                $seedBytes = [System.Text.Encoding]::UTF8.GetBytes($Seed)
                $derivedSeed = [System.Security.Cryptography.SHA256]::Create().ComputeHash($seedBytes)
                $result = [PSModule.Sodium]::crypto_box_seed_keypair($publicKey, $privateKey, $derivedSeed)
                break
            }
            default {
                $result = [PSModule.Sodium]::crypto_box_keypair($publicKey, $privateKey)
            }
        }

        if ($result -ne 0) {
            throw 'Key pair generation failed.'
        }

        return [pscustomobject]@{
            PublicKey  = [Convert]::ToBase64String($publicKey)
            PrivateKey = [Convert]::ToBase64String($privateKey)
        }
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [New-SodiumKeyPair] - Done"
#endregion [functions] - [public] - [New-SodiumKeyPair]
Write-Debug "[$scriptName] - [functions] - [public] - Done"
#endregion [functions] - [public]
#region    [variables] - [private]
Write-Debug "[$scriptName] - [variables] - [private] - Processing folder"
#region    [variables] - [private] - [Supported]
Write-Debug "[$scriptName] - [variables] - [private] - [Supported] - Importing"
$script:Supported = $false
Write-Debug "[$scriptName] - [variables] - [private] - [Supported] - Done"
#endregion [variables] - [private] - [Supported]
Write-Debug "[$scriptName] - [variables] - [private] - Done"
#endregion [variables] - [private]
#region    [main]
Write-Debug "[$scriptName] - [main] - Importing"
switch ($true) {
    $IsLinux {
        Import-Module "$PSScriptRoot/libs/linux-x64/PSModule.Sodium.dll"
        $script:Supported = $true
    }
    $IsMacOS {
        if ("$(sysctl -n machdep.cpu.brand_string)" -Like 'Apple*') {
            Import-Module "$PSScriptRoot/libs/osx-arm64/PSModule.Sodium.dll"
        } else {
            Import-Module "$PSScriptRoot/libs/osx-x64/PSModule.Sodium.dll"
        }
        $script:Supported = $true
    }
    $IsWindows {
        if ([System.Environment]::Is64BitProcess) {
            Import-Module "$PSScriptRoot/libs/win-x64/PSModule.Sodium.dll"
        } else {
            Import-Module "$PSScriptRoot/libs/win-x86/PSModule.Sodium.dll"
        }
        $script:Supported = Assert-VisualCRedistributableInstalled -Version '14.0'
    }
    default {
        throw 'Unsupported platform. Please refer to the documentation for more information.'
    }
}
Write-Debug "[$scriptName] - [main] - Done"
#endregion [main]

#region    Member exporter
$exports = @{
    Alias    = '*'
    Cmdlet   = ''
    Function = @(
        'ConvertFrom-SodiumSealedBox'
        'ConvertTo-SodiumSealedBox'
        'Get-SodiumPublicKey'
        'New-SodiumKeyPair'
    )
    Variable = ''
}
Export-ModuleMember @exports
#endregion Member exporter

