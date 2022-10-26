function Get-BaconRegistryValueOrDefault {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]
        $RegistryKey,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]
        $RegistryValue,

        [Parameter(Mandatory = $true, Position = 2)]
        $DefaultValue,

        [Parameter(Mandatory = $false)]
        [string]
        $RegistryKeyRoot,

        [Parameter(HelpMessage = 'Do Not Expand Environment Variables.')]
        [switch]
        $DoNotExpand,

        [Parameter(HelpMessage = 'For development.')]
        [bool]
        $OnlyUseDefaultSettings
    )

    Write-Verbose "[Get-BaconRegistryValueOrDefault] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Debug "[Get-BaconRegistryValueOrDefault] Function Invocation: $($MyInvocation | Out-String)"

    if ($OnlyUseDefaultSettings) {
        Write-Verbose "[Get-BaconRegistryValueOrDefault] OnlyUseDefaultSettings Set; Returning: ${DefaultValue}"
        return $DefaultValue
    }

    if ($RegistryKeyRoot -as [bool]) {
        $RegistryDrives = (Get-PSDrive -PSProvider Registry).Name + 'Registry:' | ForEach-Object { '{0}:' -f $_ }
        if ($RegistryKey -notmatch ($RegistryDrives -join '|')) {
            $RegistryKey = Join-Path $RegistryKeyRoot $RegistryKey
            Write-Debug "[Get-BaconRegistryValueOrDefault] RegistryKey adjusted to: ${RegistryKey}"
        }
    }

    try {
        if ($DoNotExpand.IsPresent) {
            $result = Get-RegistryValueDoNotExpandEnvironmentName -Key $RegistryKey -Value $RegistryValue
            Write-Verbose "[Get-BaconRegistryValueOrDefault] Registry Set; Returning: ${result}"
        } else {
            $result = Get-ItemPropertyValue -Path $RegistryKey -Name $RegistryValue -ErrorAction 'Stop'
            Write-Verbose "[Get-BaconRegistryValueOrDefault] Registry Set; Returning: ${result}"
        }
        return $result
    } catch [System.Management.Automation.PSArgumentException] {
        Write-Verbose "[Get-BaconRegistryValueOrDefault] Registry Not Set; Returning Default: ${DefaultValue}"
        if ($Error) { $Error.RemoveAt(0) } # This isn't a real error, so I don't want it in the error record.
        return $DefaultValue
    } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Verbose "[Get-BaconRegistryValueOrDefault] Registry Not Set; Returning Default: ${DefaultValue}"
        if ($Error) { $Error.RemoveAt(0) } # This isn't a real error, so I don't want it in the error record.
        return $DefaultValue
    }
}
