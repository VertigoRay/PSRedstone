<#
.SYNOPSIS
Simplify the looping through user profiles and user registries.
.DESCRIPTION
Simplify the looping through user profiles and user registries by calling this function that gets what you need quickly.

Each user profile that is returned will contain information in the following hashtable:

```powershell
@{
    Domain = 'CONTOSO'
    Username = 'jsmith'
    Path = [IO.DirectoryInfo] 'C:\Users\jsmith'
    SID = 'S-1-5-21-1111111111-2222222222-3333333333-123456'
    RegistryKey = [Microsoft.Win32.RegistryKey] 'HKEY_USERS\S-1-5-21-1111111111-2222222222-3333333333-123456'
}
```
.PARAMETER Redstone
Provide the redstone class variable so we don't have to create a new one for you.
.PARAMETER AllProfiles
Include all user profiles, including service accounts.
Otherwise just [S-1-5-21 User Accounts](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/manage/understand-security-identifiers#security-identifier-architecture) would be included.
.PARAMETER AddDefaultUser
Include the default User.
Keep in mind, no Domain or SID information will be provided for the default user, and the username will be `DEFAULT`.
.PARAMETER IncludeUserRegistryKey
Include the path to each user hive (aka HKCU).

If `AddDefaultUser` was provided, the hive will be mounted and requires special considertion.
You should use [`Set-RedstoneRegistryHiveItemProperty`](https://github.com/VertigoRay/PSRedstone/wiki/Functions#set-redstoneregistryhiveitemproperty) to make changes to mounted hives.
The [`Dismount-RedstoneRegistryHive`](https://github.com/VertigoRay/PSRedstone/wiki/Functions#dismount-redstoneregistryhive) is registered to the `PowerShell.Exiting` event for you by the [`Mount-RedstoneRegistryHive`](https://github.com/VertigoRay/PSRedstone/wiki/Functions#mount-redstoneregistryhive) function.
.PARAMETER DomainSid
Filter for the provided Sid.
If an `*` is not included at the end, it will be added.
.PARAMETER NotDomainSid
Filter out the provided Sid.
If an `*` is not included at the end, it will be added.
.EXAMPLE
foreach ($profilePath in (Get-UserProfiles)) { $profilePath }
#>
function Get-UserProfiles ([Redstone] $Redstone, [switch] $AllProfiles, [string] $DomainSid = $null, [string] $NotDomainSid = $null, [switch] $AddDefaultUser, [switch] $IncludeUserRegKey) {
    if (-not $Redstone) {
        try {
            $Redstone, $null = New-Redstone
        } catch {
            Throw [System.Management.Automation.ItemNotFoundException] ('Unable to find or create a redstone class. If your Redstone class is not stored on the variable `$redstone` then you must provide it in the `-Redstone` parameter. Tried making you a redstone class, but got this instantiation error: {0}' -f $_)
        }
    }

    $profiles = $Redstone.ProfileList.Profiles

    if (-not $AllProfiles.IsPresent) {
        # filter down to only user accounts
        $profiles = $profiles | Where-Object { $_.SID.StartsWith('S-1-5-21-') }
    }

    if ($DomainSid.IsPresent) {
        $DomainSid = '{0}*' -f $DomainSid.TrimEnd('*')
        $profiles = $profiles | Where-Object { $_.SID -like $DomainSid }
    }

    if ($NotDomainSid.IsPresent) {
        $NotDomainSid = '{0}*' -f $NotDomainSid.TrimEnd('*')
        $profiles = $profiles | Where-Object { $_.SID -notlike $NotDomainSid }
    }

    if ($AddDefaultUser.IsPresent) {
        $profiles = $profiles + @(@{
            Domain = $null
            Username = 'DEFAULT'
            Path = $Redstone.ProfileList.Default
            SID = $null
        })
    }

    if ($IncludeUserRegistryKey.IsPresent) {
        $profiles = foreach ($profile in $profiles) {
            if ($profile.Username -eq 'DEFAULT') {
                $hive = Mount-RegistryHive -DefaultUser
                $profile.Add('RegistryKey', $hive)
            } elseif ($profile.SID) {
                $profile.Add('RegistryKey', (Get-Item ('Registry::HKEY_USERS\{0}' -f $profile.SID) -ErrorAction 'Ignore'))
            }

            Write-Output $profile
        }
    }

    return $profiles.GetEnumerator()
}