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
#region    [functions] - [private] - [Format-UnitValue]
Write-Debug "[$scriptName] - [functions] - [private] - [Format-UnitValue] - Importing"
function Format-UnitValue {
    <#
        .SYNOPSIS
        Formats a numerical value with its corresponding unit.

        .DESCRIPTION
        This function takes an integer value and a unit and returns a formatted string.
        The format can be specified as Symbol, Abbreviation, or FullName.

        .EXAMPLE
        Format-UnitValue -Value 5 -Unit 'Hours' -Format Symbol

        Output:
        ```powershell
        5h
        ```

        Returns the formatted value with its symbol.

        .EXAMPLE
        Format-UnitValue -Value 5 -Unit 'Hours' -Format Abbreviation

        Output:
        ```powershell
        5hr
        ```

        Returns the formatted value with its abbreviation.

        .EXAMPLE
        Format-UnitValue -Value 1 -Unit 'Hours' -Format FullName

        Output:
        ```powershell
        1 hour
        ```

        Returns the formatted value with the full singular unit name.

        .EXAMPLE
        Format-UnitValue -Value 2 -Unit 'Hours' -Format FullName

        Output:
        ```powershell
        2 hours
        ```

        Returns the formatted value with the full plural unit name.

        .OUTPUTS
        string. A formatted string combining the value and its corresponding unit in the specified format.

        .LINK
        https://psmodule.io/TimeSpan/Functions/Format-UnitValue/
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The numerical value to be formatted with a unit.
        [Parameter(Mandatory)]
        [System.Int128] $Value,

        # The unit type to append to the value.
        [Parameter(Mandatory)]
        [string] $Unit,

        # The format for displaying the unit.
        [Parameter()]
        [ValidateSet('Symbol', 'Abbreviation', 'FullName')]
        [string] $Format = 'Symbol'
    )

    switch ($Format) {
        'FullName' {
            # Choose singular or plural form based on the value.
            $unitName = if ($Value -eq 1) { $script:UnitMap[$Unit].Singular } else { $script:UnitMap[$Unit].Plural }
            return "$Value $unitName"
        }
        'Abbreviation' {
            return "$Value$($script:UnitMap[$Unit].Abbreviation)"
        }
        'Symbol' {
            return "$Value$($script:UnitMap[$Unit].Symbol)"
        }
    }
}
Write-Debug "[$scriptName] - [functions] - [private] - [Format-UnitValue] - Done"
#endregion [functions] - [private] - [Format-UnitValue]
Write-Debug "[$scriptName] - [functions] - [private] - Done"
#endregion [functions] - [private]
#region    [functions] - [public]
Write-Debug "[$scriptName] - [functions] - [public] - Processing folder"
#region    [functions] - [public] - [completer]
Write-Debug "[$scriptName] - [functions] - [public] - [completer] - Importing"
Register-ArgumentCompleter -CommandName Format-TimeSpan -ParameterName BaseUnit -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
    $null = $commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter
    $($script:UnitMap.Keys) | Where-Object { $_ -like "$wordToComplete*" }
}
Write-Debug "[$scriptName] - [functions] - [public] - [completer] - Done"
#endregion [functions] - [public] - [completer]
#region    [functions] - [public] - [Format-TimeSpan]
Write-Debug "[$scriptName] - [functions] - [public] - [Format-TimeSpan] - Importing"
function Format-TimeSpan {
    <#
        .SYNOPSIS
        Formats a TimeSpan object into a human-readable string.

        .DESCRIPTION
        This function converts a TimeSpan object into a formatted string based on a chosen unit or precision.
        By default, it shows all units that have non-zero values. You can specify a base unit, the number of
        precision levels, and the format for displaying units. If the TimeSpan is negative, it is prefixed
        with a minus sign.

        .EXAMPLE
        New-TimeSpan -Minutes 90 | Format-TimeSpan

        Output:
        ```powershell
        1h 30m
        ```

        Formats the given TimeSpan showing all non-zero units with symbols (default behavior).

        .EXAMPLE
        New-TimeSpan -Minutes 90 | Format-TimeSpan -Format Abbreviation

        Output:
        ```powershell
        1hr 30min
        ```

        Formats the given TimeSpan showing all non-zero units using abbreviations instead of symbols.

        .EXAMPLE
        New-TimeSpan -Hours 2 -Minutes 30 -Seconds 10 | Format-TimeSpan -Format FullName

        Output:
        ```powershell
        2 hours 30 minutes 10 seconds
        ```

        Shows all non-zero units in full name format.

        .EXAMPLE
        New-TimeSpan -Hours 2 -Minutes 30 -Seconds 10 | Format-TimeSpan -Format FullName -IncludeZeroValues

        Output:
        ```powershell
        2 hours 30 minutes 10 seconds 0 milliseconds 0 microseconds
        ```

        Shows all units including those with zero values when the IncludeZeroValues switch is used.

        .EXAMPLE
        [TimeSpan]::FromSeconds(3661) | Format-TimeSpan -Precision 2 -Format FullName

        Output:
        ```powershell
        1 hour 1 minute
        ```

        Returns the TimeSpan formatted into exactly 2 components using full unit names.

        .EXAMPLE
        New-TimeSpan -Minutes 90 | Format-TimeSpan -Precision 1

        Output:
        ```powershell
        2h
        ```

        When precision is explicitly set to 1, uses the traditional behavior of showing only the most significant unit (rounded).

        .OUTPUTS
        System.String

        .NOTES
        The formatted string representation of the TimeSpan.

        .LINK
        https://psmodule.io/TimeSpan/Functions/Format-TimeSpan/
    #>
    [CmdletBinding()]
    param(
        # The TimeSpan object to format.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [TimeSpan] $TimeSpan,

        # Specifies the number of precision levels to include in the output. If not specified, automatically shows all units with non-zero values.
        [Parameter()]
        [int] $Precision,

        # Specifies the base unit to use for formatting the TimeSpan.
        [Parameter()]
        [string] $BaseUnit,

        # Specifies the format for displaying time units.
        [Parameter()]
        [ValidateSet('Symbol', 'Abbreviation', 'FullName')]
        [string] $Format = 'Symbol',

        # Includes units with zero values in the output. By default, only non-zero units are shown.
        [Parameter()]
        [switch] $IncludeZeroValues
    )

    process {
        $isNegative = $TimeSpan.Ticks -lt 0
        if ($isNegative) {
            $TimeSpan = [System.TimeSpan]::FromTicks(-1 * $TimeSpan.Ticks)
        }
        $originalTicks = $TimeSpan.Ticks

        # Ordered list of units from most to least significant.
        $orderedUnits = [System.Collections.ArrayList]::new()
        foreach ($key in $script:UnitMap.Keys) {
            $null = $orderedUnits.Add($key)
        }

        # If Precision is not specified, set behavior for auto-precision mode
        $autoPrecisionMode = $PSBoundParameters.ContainsKey('Precision') -eq $false
        if ($autoPrecisionMode) {
            # For auto-precision mode, process all units regardless of IncludeZeroValues
            # The filtering of zero values is handled later in the logic
            $Precision = $orderedUnits.Count
        }

        if ($Precision -eq 1) {
            # For precision=1, use the "fractional" approach.
            if ($BaseUnit) {
                $chosenUnit = $BaseUnit
            } else {
                # Pick the most significant unit that fits (unless all are zero).
                $chosenUnit = $null
                foreach ($unit in $orderedUnits) {
                    if (($script:UnitMap.Keys -contains $unit) -and $originalTicks -ge $script:UnitMap[$unit].Ticks) {
                        $chosenUnit = $unit; break
                    }
                }
                if (-not $chosenUnit) { $chosenUnit = 'Microseconds' }
            }

            $fractionalValue = $originalTicks / $script:UnitMap[$chosenUnit].Ticks
            $roundedValue = [math]::Round($fractionalValue, 0, [System.MidpointRounding]::AwayFromZero)
            $formatted = Format-UnitValue -Value $roundedValue -Unit $chosenUnit -Format $Format
            if ($isNegative) { $formatted = "-$formatted" }
            return $formatted
        } else {
            # For multi-component output, perform a sequential breakdown.
            if ($BaseUnit) {
                $startingIndex = $orderedUnits.IndexOf($BaseUnit)
                if ($startingIndex -lt 0) { throw "Invalid BaseUnit value: $BaseUnit" }
            } else {
                $startingIndex = 0
                foreach ($unit in $orderedUnits) {
                    if (($script:UnitMap.Keys -contains $unit) -and $originalTicks -ge $script:UnitMap[$unit].Ticks) { break }
                    $startingIndex++
                }
                if ($startingIndex -ge $orderedUnits.Count) { $startingIndex = $orderedUnits.Count - 1 }
            }

            $resultSegments = @()
            $remainder = $originalTicks
            $endIndex = [Math]::Min($startingIndex + $Precision - 1, $orderedUnits.Count - 1)
            for ($i = $startingIndex; $i -le $endIndex; $i++) {
                $unit = $orderedUnits[$i]
                $unitTicks = $script:UnitMap[$unit].Ticks
                if ($i -eq $endIndex) {
                    $value = [math]::Round($remainder / $unitTicks, 0, [System.MidpointRounding]::AwayFromZero)
                } else {
                    $value = [math]::Floor($remainder / $unitTicks)
                }
                $remainder = $remainder - ($value * $unitTicks)

                # When precision is explicitly specified, include values even if they're zero
                # When precision is not specified and IncludeZeroValues is false, only include non-zero values
                # When precision is not specified and IncludeZeroValues is true, include all values
                $shouldInclude = ($value -gt 0) -or $IncludeZeroValues -or ($PSBoundParameters.ContainsKey('Precision'))
                if ($shouldInclude) {
                    $resultSegments += Format-UnitValue -Value $value -Unit $unit -Format $Format
                }
            }
            $formatted = $resultSegments -join ' '
            if ($isNegative) { $formatted = "-$formatted" }
            return $formatted
        }
    }
}
Write-Debug "[$scriptName] - [functions] - [public] - [Format-TimeSpan] - Done"
#endregion [functions] - [public] - [Format-TimeSpan]
Write-Debug "[$scriptName] - [functions] - [public] - Done"
#endregion [functions] - [public]
#region    [variables] - [private]
Write-Debug "[$scriptName] - [variables] - [private] - Processing folder"
#region    [variables] - [private] - [UnitMap]
Write-Debug "[$scriptName] - [variables] - [private] - [UnitMap] - Importing"
$script:AverageDaysInMonth = 30.436875
$script:AverageDaysInYear = 365.2425
$script:DaysInWeek = 7
$script:HoursInDay = 24

$script:UnitMap = [ordered]@{
    'Millennia'    = @{
        Singular     = 'millennium'
        Plural       = 'millennia'
        Abbreviation = 'mill'
        Symbol       = 'kyr'
        Ticks        = [System.TimeSpan]::TicksPerDay * $script:AverageDaysInYear * 1000
    }
    'Centuries'    = @{
        Singular     = 'century'
        Plural       = 'centuries'
        Abbreviation = 'cent'
        Symbol       = 'c'
        Ticks        = [System.TimeSpan]::TicksPerDay * $script:AverageDaysInYear * 100
    }
    'Decades'      = @{
        Singular     = 'decade'
        Plural       = 'decades'
        Abbreviation = 'dec'
        Symbol       = 'dec'
        Ticks        = [System.TimeSpan]::TicksPerDay * $script:AverageDaysInYear * 10
    }
    'Years'        = @{
        Singular     = 'year'
        Plural       = 'years'
        Abbreviation = 'yr'
        Symbol       = 'y'
        Ticks        = [System.TimeSpan]::TicksPerDay * $script:AverageDaysInYear
    }
    'Months'       = @{
        Singular     = 'month'
        Plural       = 'months'
        Abbreviation = 'mon'
        Symbol       = 'mo'
        Ticks        = [System.TimeSpan]::TicksPerDay * $script:AverageDaysInMonth
    }
    'Weeks'        = @{
        Singular     = 'week'
        Plural       = 'weeks'
        Abbreviation = 'wk'
        Symbol       = 'wk'
        Ticks        = [System.TimeSpan]::TicksPerDay * $script:DaysInWeek
    }
    'Days'         = @{
        Singular     = 'day'
        Plural       = 'days'
        Abbreviation = 'day'
        Symbol       = 'd'
        Ticks        = [System.TimeSpan]::TicksPerDay
    }
    'Hours'        = @{
        Singular     = 'hour'
        Plural       = 'hours'
        Abbreviation = 'hr'
        Symbol       = 'h'
        Ticks        = [System.TimeSpan]::TicksPerHour
    }
    'Minutes'      = @{
        Singular     = 'minute'
        Plural       = 'minutes'
        Abbreviation = 'min'
        Symbol       = 'm'
        Ticks        = [System.TimeSpan]::TicksPerMinute
    }
    'Seconds'      = @{
        Singular     = 'second'
        Plural       = 'seconds'
        Abbreviation = 'sec'
        Symbol       = 's'
        Ticks        = [System.TimeSpan]::TicksPerSecond
    }
    'Milliseconds' = @{
        Singular     = 'millisecond'
        Plural       = 'milliseconds'
        Abbreviation = 'msec'
        Symbol       = 'ms'
        Ticks        = [System.TimeSpan]::TicksPerMillisecond
    }
    'Microseconds' = @{
        Singular     = 'microsecond'
        Plural       = 'microseconds'
        Abbreviation = 'µsec'
        Symbol       = "µs"
        Ticks        = 10
    }
}
Write-Debug "[$scriptName] - [variables] - [private] - [UnitMap] - Done"
#endregion [variables] - [private] - [UnitMap]
Write-Debug "[$scriptName] - [variables] - [private] - Done"
#endregion [variables] - [private]

#region    Member exporter
$exports = @{
    Alias    = '*'
    Cmdlet   = ''
    Function = 'Format-TimeSpan'
    Variable = ''
}
Export-ModuleMember @exports
#endregion Member exporter

