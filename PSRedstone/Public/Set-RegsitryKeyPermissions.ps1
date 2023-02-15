<#
.NOTES
Ref: https://stackoverflow.com/a/35843420/17552750
.LINK
https://github.com/VertigoRay/PSRedstone/wiki/Functions#set-regsitrykeypermissions
#>
function Set-RegsitryKeyPermissions {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [string]
        $RootKey,

        [string]
        $Key,

        [System.Security.Principal.SecurityIdentifier]
        $Sid,

        [bool]
        $Recurse,

        [int]
        $RecurseLevel = 0
    )

    Write-Information ('[Invoke-Download] > {0}' -f ($MyInvocation.BoundParameters | ConvertTo-Json -Compress))
    Write-Debug ('[Invoke-Download] Function Invocation: {0}' -f ($MyInvocation | Out-String))

    # Get ownerships of key - it works only for current key
    $regKey = [Microsoft.Win32.Registry]::$RootKey.OpenSubKey($Key, 'ReadWriteSubTree', 'TakeOwnership')
    $acl = New-Object System.Security.AccessControl.RegistrySecurity
    $acl.SetOwner($Sid)
    $regKey.SetAccessControl($acl)

    # Enable inheritance of permissions (not ownership) for current key from parent
    $acl.SetAccessRuleProtection($false, $false)
    $regKey.SetAccessControl($acl)

    # Only for top-level key, change permissions for current key and propagate it for subkeys
    # to enable propagations for subkeys, it needs to execute Steps 2-3 for each subkey (Step 5)
    if ($RecurseLevel -eq 0) {
        $regKey = $regKey.OpenSubKey('', 'ReadWriteSubTree', 'ChangePermissions')
        $rule = New-Object System.Security.AccessControl.RegistryAccessRule($Sid, 'FullControl', 'ContainerInherit', 'None', 'Allow')
        $acl.ResetAccessRule($rule)
        $regKey.SetAccessControl($acl)
    }

    # Recursively repeat steps 2-5 for subkeys
    if ($Recurse) {
        foreach($subKey in $regKey.OpenSubKey('').GetSubKeyNames()) {
            Set-RegsitryKeyPermissions $RootKey ($Key+'\'+$subKey) $Sid $Recurse ($RecurseLevel+1)
        }
    }
}
