<#
.DESCRIPTION
    This script can be used as part of a configuration item to setup computers with PSRedstone.
    This is much simpler than the Tools\Remediation.ps1.

    Just see if we have the latest version of PSRedstone installed.
#>
(Get-Module 'PSRedstone' -ListAvailable).Version -contains (Find-Module 'PSRedstone' -ErrorAction 'Ignore').Version
