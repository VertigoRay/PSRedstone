<#
.SYNOPSIS

Get SeTakeOwnership, SeBackup and SeRestore privileges before executes next lines, script needs Admin privilege

.NOTES

Ref: https://stackoverflow.com/a/35843420/17552750
#>
function Invoke-RedstoneElevateCurrentProcess {
    [CmdletBinding()]
    param()

    Write-Information ('[Invoke-RedstoneElevateCurrentProcess] > {0}' -f ($MyInvocation.BoundParameters | ConvertTo-Json -Compress))
    Write-Debug ('[Invoke-RedstoneElevateCurrentProcess] Function Invocation: {0}' -f ($MyInvocation | Out-String))

    $import = '[DllImport("ntdll.dll")] public static extern int RtlAdjustPrivilege(ulong a, bool b, bool c, ref bool d);'
    $ntdll = Add-Type -Member $import -Name 'NtDll' -PassThru
    $privileges = @{
        SeTakeOwnership = 9
        SeBackup =  17
        SeRestore = 18
    }

    foreach ($privilege in $privileges.GetEnumerator()) {
        Write-Debug ('[Invoke-RedstoneElevateCurrentProcess] Adjusting Priv: {0}: {1}' -f $privilege.Name, $privilege.Value)
        $rtlAdjustPrivilege = $ntdll::RtlAdjustPrivilege($privilege.Value, 1, 0, [ref] 0)
        $returnedMessage = Get-RedstoneTranslatedErrorCode $rtlAdjustPrivilege
        Write-Debug ('[Invoke-RedstoneElevateCurrentProcess] Adjusted Prif: {0}' -f ($returnedMessage | Select-Object '*' | Out-String))
    }
}
