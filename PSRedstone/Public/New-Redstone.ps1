<#
.SYNOPSIS
Create a RedStone Class.
.DESCRIPTION
Create a Redstone Class with an easy to use function.
.PARAMETER SettingsJson
Path to the settings.json file.
.PARAMETER Publisher
Name of the publisher, like "Mozilla".
.PARAMETER Product
Name of the product, like "Firefox ESR".
.PARAMETER Version
Version of the product, like "108.0.1".
This was deliberatly not cast as a [version] to allow handling of non-semantic versioning.
.PARAMETER Action
Action that is being taken.
This is purely cosmetic and directly affects the log name. For Example:
    - Using the examples from the Publisher, Product, and Version parameters.
    - Set action to 'install'

The log file name will be: Mozilla Firefox ESR 108.0.1 Install.log

If you don't specify an action, the action will be taken from the name of the script your calling this function from.
.OUTPUTS
`System.Array` with two Values:
    1. Redstone. The Redstone class
    2. PSObject. The results of parsing the provided settings.json file. Null if parameters supplied.
.NOTES
Allows access to the Redstone class without having to use `Using Module Redstone`.
    - Ref: https://stephanevg.github.io/powershell/class/module/DATA-How-To-Write-powershell-Modules-with-classes/
.LINK
https://github.com/VertigoRay/PSRedstone/wiki/Functions#new-redstone
#>
function New-Redstone {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName='NoParams')]
    [OutputType([System.Object[]])]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'SettingsJson',
            HelpMessage = 'Path to the settings.json file.'
        )]
        [IO.FileInfo]
        $SettingsJson,

        [Parameter(
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'Settings',
            HelpMessage = 'Pre-existing settings variable.'
        )]
        [PSObject]
        $Settings,

        [Parameter(
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'ManuallyDefined',
            HelpMessage = 'Name of the publisher, like "Mozilla".'
        )]
        [string]
        $Publisher,

        [Parameter(
            Mandatory = $true,
            Position = 2,
            ParameterSetName = 'ManuallyDefined',
            HelpMessage = 'Name of the product, like "Firefox ESR".'
        )]
        [string]
        $Product,

        [Parameter(
            Mandatory = $true,
            Position = 3,
            ParameterSetName = 'ManuallyDefined',
            HelpMessage = 'Version of the product, like "108.0.1".'
        )]
        [string]
        $Version,

        [Parameter(
            Mandatory = $true,
            Position = 4,
            ParameterSetName = 'ManuallyDefined',
            HelpMessage = 'Action that is being taken.'
        )]
        [string]
        $Action
    )

    switch ($PSCmdlet.ParameterSetName) {
        'SettingsJson' {
            $redstone = [Redstone]::new($SettingsJson)
            return @(
                $redstone
                $redstone.Settings.JSON.Data
            )
        }
        'Settings' {
            $redstone = [Redstone]::new($Settings)
            return @(
                $redstone
                $redstone.Settings.JSON.Data
            )
        }
        'ManuallyDefined' {
            $redstone = [Redstone]::new($Publisher, $Product, $Version, $Action)
            return @(
                $redstone
                $redstone.Settings.JSON.Data
            )
        }
        default {
            # NoParams
            if (Get-Variable 'settings' -ErrorAction 'Ignore') {
                $redstone = [Redstone]::new($settings)
            } else {
                $redstone = [Redstone]::new()
            }
            return @(
                $redstone
                $redstone.Settings.JSON.Data
            )
        }
    }
}

New-Alias -Name 'New-' -Value 'New-Redstone'
