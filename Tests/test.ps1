. "$PSScriptRoot\..\PSWinstall\PSWinstall-ClassShell.ps1"

$winstall = [Winstall]::new($MyInvocation)
$winstall.MyInvocation
$winstall.AssertIsElevated()


hidden [psobject] GetRegOrDefault($RegistryKey, $RegistryValue, $DefaultValue) {
    Write-Verbose "[Winstall GetRegOrDefault] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Debug "[Winstall GetRegOrDefault] Function Invocation: $($MyInvocation | Out-String)"

    if ($this.OnlyUseDefaultSettings) {
        Write-Verbose "[Winstall GetRegOrDefault] OnlyUseDefaultSettings Set; Returning: ${DefaultValue}"
        return $DefaultValue
    }

    try {
        $ret = Get-ItemPropertyValue -Path ('{0}\{1}' -f $this.RegistryKeyRoot, $RegistryKey) -Name $RegistryValue -ErrorAction 'Stop'
        Write-Verbose "[Winstall GetRegOrDefault] Registry Set; Returning: ${ret}"
        return $ret
    } catch [System.Management.Automation.PSArgumentException] {
        Write-Verbose "[Winstall GetRegOrDefault] Registry Not Set; Returning Default: ${DefaultValue}"
        $Error.RemoveAt(0) # This isn't a real error, so I don't want it in the error record.
        return $DefaultValue
    } catch [System.Management.Automation.ItemNotFoundException] {
        Write-Verbose "[Winstall GetRegOrDefault] Registry Not Set; Returning Default: ${DefaultValue}"
        $Error.RemoveAt(0) # This isn't a real error, so I don't want it in the error record.
        return $DefaultValue
    }
}