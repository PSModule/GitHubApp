[CmdletBinding()]
param()
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
$script:PSModuleInfo = Test-ModuleManifest -Path "$PSScriptRoot\$baseName.psd1"
$script:PSModuleInfo | Format-List | Out-String -Stream | ForEach-Object { Write-Debug $_ }
$scriptName = $script:PSModuleInfo.Name
Write-Debug "[$scriptName] - Importing module"
#region    [functions] - [public]
Write-Debug "[$scriptName] - [functions] - [public] - Processing folder"
#region    [functions] - [public] - [ConvertFrom-UriQueryString]
Write-Debug "[$scriptName] - [functions] - [public] - [ConvertFrom-UriQueryString] - Importing"
filter ConvertFrom-UriQueryString {
    <#
        .SYNOPSIS
        Parses a URL query string into a hashtable of parameters.

        .DESCRIPTION
        Takes a URI query string (the portion after the '?') and converts it into a hashtable
        where each key is a parameter name and the corresponding value is the parameter value.
        If the query string contains the same parameter multiple times, the resulting value
        will be an array of those values. Percent-encoded characters in the input are decoded
        back to their normal representation.

        .EXAMPLE
        ConvertFrom-UriQueryString -Query 'name=John%20Doe&age=30&age=40'

        Output:
        ```powershell
        Name                           Value
        ----                           -----
        name                           John Doe
        age                            {30, 40}
        ```

        Parses the given query string and returns a hashtable where keys are parameter names and
        values are decoded parameter values.

        .EXAMPLE
        '?q=PowerShell%20URI' | ConvertFrom-UriQueryString

        Output:
        ```powershell
        Name                           Value
        ----                           -----
        q                              PowerShell URI
        ```

        Parses a query string that contains a single parameter and returns the corresponding value.

        .LINK
        https://psmodule.io/Uri/Functions/ConvertFrom-UriQueryString/
    #>
    [OutputType([hashtable])]
    [CmdletBinding()]
    param(
        # The query string to parse. This can include the leading '?' or just the key-value pairs.
        # For example, both "?foo=bar&count=10" and "foo=bar&count=10" are acceptable.
        [Parameter(ValueFromPipeline)]
        [AllowNull()]
        [string] $Query
    )

    if ([string]::IsNullOrEmpty($Query)) {
        Write-Verbose 'Query string is null or empty.'
        return @{}
    }

    Write-Verbose "Parsing query string: $Query"
    # Remove leading '?' if present
    if ($Query.StartsWith('?')) {
        $Query = $Query.Substring(1)
    }

    $result = @{}
    # Split by '&' to get each key=value pair
    $pairs = $Query.Split('&')
    foreach ($pair in $pairs) {
        if ([string]::IsNullOrWhiteSpace($pair)) { continue }  # skip empty segments (e.g. "&&")

        $key, $value = $pair.Split('=', 2)  # split into two parts at first '='
        $key = [System.Uri]::UnescapeDataString($key)
        if ($null -ne $value) {
            $value = [System.Uri]::UnescapeDataString($value)
        } else {
            $value = ''  # if no '=' present, treat value as empty string
        }

        if ($result.Contains($key)) {
            # If key already exists, convert value to array or add to existing array
            if ($result[$key] -is [System.Collections.IEnumerable] -and $result[$key] -isnot [string]) {
                # If already an array or collection, just add
                $result[$key] += $value
            } else {
                # If a single value exists, turn it into an array
                $result[$key] = @($result[$key], $value)
            }
        } else {
            $result[$key] = $value
        }
    }
    return $result
}
Write-Debug "[$scriptName] - [functions] - [public] - [ConvertFrom-UriQueryString] - Done"
#endregion [functions] - [public] - [ConvertFrom-UriQueryString]
#region    [functions] - [public] - [ConvertTo-UriQueryString]
Write-Debug "[$scriptName] - [functions] - [public] - [ConvertTo-UriQueryString] - Importing"
filter ConvertTo-UriQueryString {
    <#
        .SYNOPSIS
        Converts a hashtable of parameters into a URL query string.

        .DESCRIPTION
        Takes a hashtable or dictionary of query parameters (keys and values) and constructs
        a properly encoded query string (e.g. "key1=value1&key2=value2"). By default, all keys
        and values are URL-encoded per RFC3986 rules to ensure the query string is valid. If a value
        is an array, multiple entries for the same key are generated.

        .EXAMPLE
        ConvertTo-UriQueryString -Query @{ foo = 'bar'; search = 'hello world'; ids = 1,2,3 }

        Output:
        ```powershell
        foo=bar&search=hello%20world&ids=1&ids=2&ids=3
        ```

        Converts the hashtable into a URL-encoded query string. Spaces are replaced with `%20`.

        .EXAMPLE
        ConvertTo-UriQueryString -Query @{ q = 'PowerShell'; verbose = $true }

        Output:
        ```powershell
        q=PowerShell&verbose=True
        ```

        Converts the query parameters into a valid query string.

        .LINK
        https://psmodule.io/Uri/Functions/ConvertTo-UriQueryString
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The hashtable (or IDictionary) containing parameter names and values. Each key becomes a parameter name.
        # Values can be strings or other types convertible to string. If a value is an array or collection, each element
        # in it will result in a separate instance of that parameter name in the output string.
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [System.Collections.IDictionary] $Query
    )

    Write-Verbose 'Converting hashtable to query string with URL encoding'
    Write-Verbose "Query: $($Query | Out-String)"
    # Build the query string by iterating through each key-value pair
    $pairs = @()
    foreach ($key in $Query.Keys) {
        # URL-encode the key.
        $name = [System.Uri]::EscapeDataString($key.ToString())
        $value = $Query[$key]

        if ($null -eq $value) {
            # Null value -> include key with empty value
            $pairs += "$name="
        } elseif ([System.Collections.IEnumerable].IsAssignableFrom($value.GetType()) -and -not ($value -is [string])) {
            foreach ($item in $value) {
                $itemValue = [System.Uri]::EscapeDataString("$item")
                $pairs += "$name=$itemValue"
            }
        } else {
            # Single value (includes strings, numbers, booleans, etc.)
            $itemValue = [System.Uri]::EscapeDataString("$value")
            $pairs += "$name=$itemValue"
        }
    }
    return [string]::Join('&', $pairs)
}
Write-Debug "[$scriptName] - [functions] - [public] - [ConvertTo-UriQueryString] - Done"
#endregion [functions] - [public] - [ConvertTo-UriQueryString]
#region    [functions] - [public] - [Get-Uri]
Write-Debug "[$scriptName] - [functions] - [public] - [Get-Uri] - Importing"
function Get-Uri {
    <#
        .SYNOPSIS
        Converts a string into a System.Uri, System.UriBuilder, or a normalized URI string.

        .DESCRIPTION
        The Get-Uri function processes a string and attempts to convert it into a valid URI.
        It supports three output formats: a System.Uri object, a System.UriBuilder object,
        or a normalized absolute URI string. If no scheme is present, "http://" is prefixed
        to ensure a valid URI. The function enforces mutual exclusivity between the output
        format parameters.

        .EXAMPLE
        Get-Uri -Uri 'example.com'

        Output:
        ```powershell
        AbsolutePath   : /
        AbsoluteUri    : http://example.com/
        LocalPath      : /
        Authority      : example.com
        HostNameType   : Dns
        IsDefaultPort  : True
        IsFile         : False
        IsLoopback     : False
        PathAndQuery   : /
        Segments       : {/}
        IsUnc          : False
        Host           : example.com
        Port           : 80
        Query          :
        Fragment       :
        Scheme         : http
        OriginalString : http://example.com
        DnsSafeHost    : example.com
        IdnHost        : example.com
        IsAbsoluteUri  : True
        UserEscaped    : False
        UserInfo       :
        ```

        Converts 'example.com' into a normalized absolute URI string.

        .EXAMPLE
        Get-Uri -Uri 'https://example.com/path' -AsUriBuilder

        Output:
        ```powershell
        Scheme   : https
        UserName :
        Password :
        Host     : example.com
        Port     : 443
        Path     : /path
        Query    :
        Fragment :
        Uri      : https://example.com/path
        ```

        Returns a [System.UriBuilder] object for the specified URI.

        .EXAMPLE
        'example.com/path' | Get-Uri -AsString

        Output:
        ```powershell
        http://example.com/path
        ```

        Returns a [string] with the full absolute URI.

        .LINK
        https://psmodule.io/Uri/Functions/Get-Uri
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSReviewUnusedParameter', 'AsString',
        Scope = 'Function',
        Justification = 'Present for parameter sets'
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSReviewUnusedParameter', 'AsUriBuilder',
        Scope = 'Function',
        Justification = 'Present for parameter sets'
    )]
    [OutputType(ParameterSetName = 'UriBuilder', [System.UriBuilder])]
    [OutputType(ParameterSetName = 'String', [string])]
    [OutputType(ParameterSetName = 'AsUri', [System.Uri])]
    [CmdletBinding(DefaultParameterSetName = 'AsUri')]
    param(
        # The string representation of the URI to be processed.
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string] $Uri,

        # Outputs a System.UriBuilder object.
        [Parameter(Mandatory, ParameterSetName = 'AsUriBuilder')]
        [switch] $AsUriBuilder,

        # Outputs the URI as a normalized string.
        [Parameter(Mandatory, ParameterSetName = 'AsString')]
        [switch] $AsString
    )

    process {
        $inputString = $Uri.Trim()
        if ([string]::IsNullOrWhiteSpace($inputString)) {
            throw 'The Uri parameter cannot be null or empty.'
        }

        # Attempt to create a System.Uri (absolute) from the string
        $uriObject = $null
        $success = [System.Uri]::TryCreate($inputString, [System.UriKind]::Absolute, [ref]$uriObject)
        if (-not $success) {
            # If no scheme present, try adding "http://"
            if ($inputString -notmatch '^[A-Za-z][A-Za-z0-9+.-]*:') {
                $success = [System.Uri]::TryCreate("http://$inputString", [System.UriKind]::Absolute, [ref]$uriObject)
            }
            if (-not $success) {
                throw "The provided value '$Uri' cannot be converted to a valid URI."
            }
        }

        switch ($PSCmdlet.ParameterSetName) {
            'AsUriBuilder' {
                return ([System.UriBuilder]::new($uriObject))
            }
            'AsString' {
                return ($uriObject.GetComponents([System.UriComponents]::AbsoluteUri, [System.UriFormat]::SafeUnescaped))
            }
            'AsUri' {
                return $uriObject
            }
        }
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Get-Uri] - Done"
#endregion [functions] - [public] - [Get-Uri]
#region    [functions] - [public] - [New-Uri]
Write-Debug "[$scriptName] - [functions] - [public] - [New-Uri] - Importing"
function New-Uri {
    <#
        .SYNOPSIS
        Constructs a URI from base, paths, query parameters, and fragment.

        .DESCRIPTION
        Builds a URI string or object by combining a base URI with additional path segments,
        query parameters, and an optional fragment. Ensures proper encoding (per [RFC3986](https://datatracker.ietf.org/doc/html/rfc3986))
        and correct placement of '/' in paths, handles query parameter merging, and appends
        fragment identifiers. By default, returns a `[System.Uri]` object.

        .EXAMPLE
        # Simple usage with base and path
        New-Uri -BaseUri 'https://example.com' -Path 'products/item'

        Output:
        ```powershell
        AbsolutePath   : /products/item
        AbsoluteUri    : https://example.com/products/item
        LocalPath      : /products/item
        Authority      : example.com
        HostNameType   : Dns
        IsDefaultPort  : True
        IsFile         : False
        IsLoopback     : False
        PathAndQuery   : /products/item
        Segments       : {/, products/, item}
        IsUnc          : False
        Host           : example.com
        Port           : 443
        Query          :
        Fragment       :
        Scheme         : https
        OriginalString : https://example.com:443/products/item
        DnsSafeHost    : example.com
        IdnHost        : example.com
        IsAbsoluteUri  : True
        UserEscaped    : False
        UserInfo       :
        ```

        Constructs a URI with the given base and path.

        .EXAMPLE
        # Adding query parameters via hashtable
        New-Uri 'https://example.com/api' -Path 'search' -Query @{ q = 'test search'; page = @(2, 4) } -AsUriBuilder

        Output:
        ```powershell
        Scheme   : https
        UserName :
        Password :
        Host     : example.com
        Port     : 443
        Path     : /api/search
        Query    : ?q=test%20search&page=2&page=4
        Fragment :
        Uri      : https://example.com/api/search?q=test search&page=2&page=4
        ```

        Adds query parameters to the URI, automatically encoding values.

        .EXAMPLE
        # Merging with existing query and using -MergeQueryParameter
        New-Uri 'https://example.com/data?year=2023' -Query @{ year = 2024; sort = 'asc' } -MergeQueryParameters -AsString

        Output:
        ```powershell
        https://example.com/data?sort=asc&year=2023&year=2024
        ```

        Merges new query parameters with the existing ones instead of replacing them.

        .OUTPUTS
        System.Uri

        .OUTPUTS
        System.UriBuilder

        .OUTPUTS
        string

        .NOTES
        - Merging query parameters allows keeping multiple values for the same key.

        .LINK
        https://psmodule.io/Uri/Functions/New-Uri
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Scope = 'Function',
        Justification = 'Creates a new URI object without changing state'
    )]
    [OutputType(ParameterSetName = 'AsString', [string])]
    [OutputType(ParameterSetName = 'AsUri', [System.Uri])]
    [OutputType(ParameterSetName = 'AsUriBuilder', [System.UriBuilder])]
    [CmdletBinding(DefaultParameterSetName = 'AsUri')]
    param(
        # The base URI (string or [System.Uri]) to start from.
        [Parameter(Mandatory, Position = 0)]
        [Alias('Uri')]
        [object] $BaseUri,

        # One or more path segments to append to the base URI.
        [Parameter(Position = 1)]
        [string[]] $Path,

        # Query parameters to add to the URI.
        [Parameter()]
        [object] $Query,

        # A URI fragment to append (the part after '#').
        [Parameter()]
        [string] $Fragment,

        # If set, allows duplicate query keys instead of overriding.
        [Parameter()]
        [switch] $MergeQueryParameters,

        # Outputs the resulting URI as a string.
        [Parameter(Mandatory, ParameterSetName = 'AsString')]
        [switch] $AsString,

        # Outputs the resulting URI as a System.UriBuilder object.
        [Parameter(Mandatory, ParameterSetName = 'AsUriBuilder')]
        [switch] $AsUriBuilder
    )

    # Validate and prepare base URI
    try {
        $baseUriObj = if ($BaseUri -is [System.Uri]) {
            $BaseUri
        } else {
            [System.Uri]::new([string]$BaseUri)  # may throw if invalid
        }
    } catch {
        throw "BaseUri '$BaseUri' is not a valid URI: $($_.Exception.Message)"
    }

    # Use UriBuilder for convenient manipulation
    $builder = [System.UriBuilder]::new($baseUriObj)

    # Handle path segments
    if ($Path) {
        $basePath = $builder.Path  # e.g. "/" from 'https://example.com'
        $segments = @()

        # If a single element containing '/' was passed, split it into segments.
        if ($Path.Count -eq 1 -and $Path[0] -match '/') {
            $segments = $Path[0].Split('/') | Where-Object { $_ -ne '' }
        } else {
            $segments = $Path
        }

        # Normalize base path: ensure it ends with '/' if we need to append, except if base path is empty or just "/"
        if ([string]::IsNullOrEmpty($basePath) -or $basePath -eq '/') {
            $basePath = ''
        } elseif ($basePath[-1] -ne '/') {
            $basePath += '/'
        }

        # Build combined path string from segments, always encoding
        $encodedSegments = @()
        foreach ($seg in $segments) {
            $encodedSegments += [System.Uri]::EscapeDataString($seg)
        }

        $combinedPath = if ($basePath -ne '' -and $basePath -ne '/') {
            "$basePath$([string]::Join('/', $encodedSegments))"
        } else {
            '/' + [string]::Join('/', $encodedSegments)
        }

        # Preserve trailing slash if original single string ended with '/'
        if ($Path.Count -eq 1 -and $Path[0].EndsWith('/')) {
            $combinedPath += '/'
        }
        $builder.Path = $combinedPath
    }

    # Handle query parameters
    if ($null -ne $Query) {
        # Convert base URI's existing query to hashtable for merging (if any)
        $baseQueryParams = @{}
        if ($builder.Query -and $builder.Query.Length -gt 1) {
            # builder.Query returns string starting with '?'
            $existingQueryString = $builder.Query.Substring(1)  # drop the '?'
            $baseQueryParams = ConvertFrom-UriQueryString -Query $existingQueryString
        }

        # Determine new query parameters from $Query input
        $newQueryParams = @{}
        if ($Query -is [hashtable] -or $Query -is [System.Collections.IDictionary]) {
            $newQueryParams = $Query
        } elseif ($Query -is [string]) {
            # Remove leading '?' if present
            $queryStr = $Query
            if ($queryStr.StartsWith('?')) { $queryStr = $queryStr.Substring(1) }
            if ($queryStr -ne '') {
                $newQueryParams = ConvertFrom-UriQueryString -Query $queryStr
            }
        } else {
            throw 'Query parameter must be a hashtable or query string (string).'
        }

        # Merge base and new query params
        $mergedParams = @{}
        foreach ($key in $baseQueryParams.Keys) {
            $mergedParams[$key] = $baseQueryParams[$key]
        }
        foreach ($key in $newQueryParams.Keys) {
            if ($MergeQueryParameters -and $mergedParams.Contains($key)) {
                # Merge same parameter: ensure value becomes an array of all values
                $existingVal = $mergedParams[$key]
                # Convert single existing value to array if not already
                if ($null -ne $existingVal -and $existingVal.GetType().IsArray -eq $false) {
                    $existingVal = , $existingVal  # wrap in array
                }
                $newVal = $newQueryParams[$key]
                if ($null -ne $newVal -and $newVal.GetType().IsArray -eq $false) {
                    $newVal = , $newVal
                }
                # Combine arrays (or values) into one array
                $combinedVal = @()
                if ($existingVal) { $combinedVal += $existingVal }
                if ($newVal) { $combinedVal += $newVal }
                $mergedParams[$key] = $combinedVal
            } else {
                # New value overwrites or adds
                $mergedParams[$key] = $newQueryParams[$key]
            }
        }

        # Convert merged hashtable to query string (always encoding)
        $finalQueryString = ConvertTo-UriQueryString -Query $mergedParams
        $builder.Query = $finalQueryString  # UriBuilder handles the '?' automatically
    }

    # Handle fragment
    if ($PSBoundParameters.ContainsKey('Fragment')) {
        if ([string]::IsNullOrEmpty($Fragment)) {
            $builder.Fragment = ''  # remove any existing fragment
        } else {
            $builder.Fragment = [System.Uri]::EscapeDataString(($Fragment -replace '^#', ''))
        }
    }
    # (If fragment not provided, any fragment in base URI stays as is)

    # Output based on switches
    switch ($PSCmdlet.ParameterSetName) {
        'AsUriBuilder' {
            return $builder
        }
        'AsUri' {
            return $builder.Uri
        }
        'AsString' {
            $uriString = "$($builder.Scheme)://$($builder.Host)$($builder.Uri.PathAndQuery)"
            if ($builder.Fragment) { $uriString += "$($builder.Fragment)" -replace '(%20| )', '-' }
            return $uriString
        }
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [New-Uri] - Done"
#endregion [functions] - [public] - [New-Uri]
#region    [functions] - [public] - [Test-Uri]
Write-Debug "[$scriptName] - [functions] - [public] - [Test-Uri] - Importing"
function Test-Uri {
    <#
        .SYNOPSIS
        Validates whether a given string is a valid URI.

        .DESCRIPTION
        The Test-Uri function checks whether a given string is a valid URI. By default, it enforces absolute URIs.
        If the `-AllowRelative` switch is specified, it allows both absolute and relative URIs.

        .EXAMPLE
        Test-Uri -Uri "https://example.com"

        Output:
        ```powershell
        True
        ```

        Checks if `https://example.com` is a valid URI, returning `$true`.

        .EXAMPLE
        Test-Uri -Uri "invalid-uri"

        Output:
        ```powershell
        False
        ```

        Returns `$false` for an invalid URI string.

        .EXAMPLE
        "https://example.com", "invalid-uri" | Test-Uri

        Output:
        ```powershell
        True
        False
        ```

        Accepts input from the pipeline and validates multiple URIs.

        .OUTPUTS
        [System.Boolean]

        .NOTES
        Returns `$true` if the input string is a valid URI, otherwise returns `$false`.

        .LINK
        https://psmodule.io/Uri/Functions/Test-Uri
    #>
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        # Accept one or more URI strings from parameter or pipeline.
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $Uri,

        # If specified, allow valid relative URIs.
        [Parameter()]
        [switch] $AllowRelative
    )

    process {
        # If -AllowRelative is set, try to create a URI using RelativeOrAbsolute.
        # Otherwise, enforce an Absolute URI.
        $uriKind = if ($AllowRelative) {
            [System.UriKind]::RelativeOrAbsolute
        } else {
            [System.UriKind]::Absolute
        }

        # Try to create the URI. The out parameter is not used.
        $dummy = $null
        [System.Uri]::TryCreate($Uri, $uriKind, [ref]$dummy)
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Test-Uri] - Done"
#endregion [functions] - [public] - [Test-Uri]
Write-Debug "[$scriptName] - [functions] - [public] - Done"
#endregion [functions] - [public]

#region    Member exporter
$exports = @{
    Alias    = '*'
    Cmdlet   = ''
    Function = @(
        'ConvertFrom-UriQueryString'
        'ConvertTo-UriQueryString'
        'Get-Uri'
        'New-Uri'
        'Test-Uri'
    )
    Variable = ''
}
Export-ModuleMember @exports
#endregion Member exporter

