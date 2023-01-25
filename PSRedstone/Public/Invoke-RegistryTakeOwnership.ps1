<#
.NOTES
Ref: https://stackoverflow.com/a/35843420/17552750
.LINK
https://github.com/VertigoRay/PSRedstone/wiki/Functions#invoke-registrytakeownership
#>
function Invoke-RegistryTakeOwnership {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]
        $RootKey,

        [Parameter(Mandatory = $true)]
        [string]
        $Key,

        [Parameter(Mandatory = $false)]
        [System.Security.Principal.SecurityIdentifier]
        $Sid,

        [Parameter(Mandatory = $false)]
        [bool]
        $Recurse = $true
    )

    Write-Information ('[Invoke-RegistryTakeOwnership] > {0}' -f ($MyInvocation.BoundParameters | ConvertTo-Json -Compress))
    Write-Debug ('[Invoke-RegistryTakeOwnership] Function Invocation: {0}' -f ($MyInvocation | Out-String))

    if (-not $RootKey -and ($Key -match '^(Microsoft\.PowerShell\.Core\\Registry\:\:|Registry\:\:)')) {
        $Key
    }

    switch -regex ($RootKey) {
        'HKCU|HKEY_CURRENT_USER'    { $RootKey = 'CurrentUser' }
        'HKLM|HKEY_LOCAL_MACHINE'   { $RootKey = 'LocalMachine' }
        'HKCR|HKEY_CLASSES_ROOT'    { $RootKey = 'ClassesRoot' }
        'HKCC|HKEY_CURRENT_CONFIG'  { $RootKey = 'CurrentConfig' }
        'HKU|HKEY_USERS'            { $RootKey = 'Users' }
    }

    # Escalate current process's privilege
    Invoke-ElevateCurrentProcess

    if (-not $Sid) {
        # Get Current User SID
        [System.Security.Principal.SecurityIdentifier] $Sid = (& whoami /USER | Select-Object -Last 1).Split(' ')[-1]
        Write-Verbose "[Invoke-RegistryTakeOwnership] Current User SID: $Sid"
    }
    Set-RegistryKeyPermissions $RootKey $Key $Sid $recurse
}