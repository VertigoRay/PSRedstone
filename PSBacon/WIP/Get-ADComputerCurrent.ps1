<#
.SYNOPSIS
Returns an object with AD Computer information for the current computer.
.DESCRIPTION
This script queries the Domain Controller for information, so a connection to the DC must exist.

All of the Directory Services properties that are not null, are placed in the DS key with `DS_` stripped from the beginning. See the examples for the details.
.PARAMETER DistinguishedName
Since the most common use of this, is probably just to get the DN back. This switch returns just that, as a string.
.OUTPUTS
[hashtable]
[string]
.EXAMPLE
> # Easiest way to get the DN of the current computer.
> $current_computer = Get-ADComputerCurrent -DistinguishedName
> $current_computer
CN=CAS-WKTST-7X64,OU=Win7,OU=Workstations,OU=CAS Support,OU=UNT,DC=unt,DC=ad,DC=unt,DC=edu
.EXAMPLE
> # Two other ways to get the DN of the current computer.
> $current_computer = Get-ADComputerCurrent
> $current_computer.DS.distinguishedName
CN=CAS-WKTST-7X64,OU=Win7,OU=Workstations,OU=CAS Support,OU=UNT,DC=unt,DC=ad,DC=unt,DC=edu
> ($current_computer.Properties | ?{$_.Name -eq 'DS_distinguishedName'}).Value
CN=CAS-WKTST-7X64,OU=Win7,OU=Workstations,OU=CAS Support,OU=UNT,DC=unt,DC=ad,DC=unt,DC=edu
.EXAMPLE
> $current_computer = Get-ADComputerCurrent
> $current_computer

PS C:\Users\peterv> $current_computer

Name                           Value
----                           -----
__SERVER                       CAS-WKTST-7X64
__PATH                         \\CAS-WKTST-7X64\root\directory\ldap:ds_computer.ADSIPath="LDAP://CN=CAS-WKTST-7X64,O...
Path                           \\CAS-WKTST-7X64\root\directory\ldap:ds_computer.ADSIPath="LDAP://CN=CAS-WKTST-7X64,O...
ADSIPath                       LDAP://CN=CAS-WKTST-7X64,OU=Win7,OU=Workstations,OU=CAS Support,OU=UNT,DC=unt,DC=ad,D...
Properties                     {ADSIPath, DS_accountExpires, DS_accountNameHistory, DS_aCSPolicyName...}
SystemProperties               {__GENUS, __CLASS, __SUPERCLASS, __DYNASTY...}
__RELPATH                      ds_computer.ADSIPath="LDAP://CN=CAS-WKTST-7X64,OU=Win7,OU=Workstations,OU=CAS Support...
__GENUS                        2
__CLASS                        ds_computer
Options                        System.Management.ObjectGetOptions
DS                             {logonCount, description, distinguishedName, objectClass...}
__SUPERCLASS                   ads_computer
__NAMESPACE                    root\directory\ldap
Scope                          System.Management.ManagementScope
ClassPath                      \\CAS-WKTST-7X64\root\directory\ldap:ds_computer
__DYNASTY                      DS_LDAP_Root_Class
PSComputerName                 CAS-WKTST-7X64
__PROPERTY_COUNT               902
__DERIVATION                   {ads_computer, ads_user, ads_organizationalperson, ads_person...}
Qualifiers                     {cn, defaultObjectCategory, defaultSecurityDescriptor, dynamic...}

> $current_computer.DS

Name                           Value
----                           -----
logonCount                     2865
description                    {{"IPInfo":{"TimeStamp":"10/26/2016 15:15:25","org":"AS589 University of North Texas"...
distinguishedName              CN=CAS-WKTST-7X64,OU=Win7,OU=Workstations,OU=CAS Support,OU=UNT,DC=unt,DC=ad,DC=unt,D...
objectClass                    {top, person, organizationalPerson, user...}
lastLogonTimestamp             131214343669675868
whenChanged                    20161026151620.000000-300
location                       [TEST: GAB313G] (2014-09-17 16:47:24)
sAMAccountName                 CAS-WKTST-7X64$
sAMAccountType                 805306369
operatingSystemServicePack     Service Pack 1
accountExpires                 9223372036854775807
cn                             CAS-WKTST-7X64
operatingSystem                Windows 7 Enterprise
instanceType                   4
uSNCreated                     252131015
objectGUID                     System.Management.ManagementBaseObject
operatingSystemVersion         6.1 (7601)
whenCreated                    20120308190441.000000-360
nTSecurityDescriptor           System.Management.ManagementBaseObject
objectCategory                 CN=Computer,CN=Schema,CN=Configuration,DC=ad,DC=unt,DC=edu
dSCorePropagationData          {20160615165836.000000-300, 20160225154605.000000-360, 20150522103056.000000-300, 201...
servicePrincipalName           {WSMAN/CAS-WkTst-7x64.unt.ad.unt.edu, WSMAN/CAS-WkTst-7x64, RestrictedKrbHost/CAS-WKT...
memberOf                       {CN=CAS-GPO-ITSS-WebProxy,OU=Workstations,OU=CAS Support,OU=UNT,DC=unt,DC=ad,DC=unt,D...
lastLogon                      131219805514703319
msDS_SupportedEncryptionTypes  28
uSNChanged                     1369882302
userAccountControl             4096
objectSid                      System.Management.ManagementBaseObject
primaryGroupID                 515
pwdLastSet                     131202025019155035
name                           CAS-WKTST-7X64
dNSHostName                    CAS-WKTST-7X64.unt.ad.unt.edu
.NOTES
I can add more switch parameters if the need arises.
#>
function Global:Get-ADComputerCurrent {
    param(
        [switch]
        $DistinguishedName
    )

    Write-Information "[Get-ADComputerCurrent] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Debug "[Get-ADComputerCurrent] Function Invocation: $($MyInvocation | Out-String)"

    if ($DistinguishedName) {
        Write-Information "[Get-ADComputerCurrent] Requesting DistinguishedName: ${DistinguishedName}"
        $computer = Get-WmiObject -Namespace 'root\directory\ldap' -Query "SELECT DS_distinguishedName FROM DS_computer WHERE DS_cn = '${env:ComputerName}'"
        $adComputer = $computer.DS_distinguishedName
    } else {
        Write-Information "[Get-ADComputerCurrent] Requesting ComputerName: ${env:ComputerName}"
        $computer = Get-WmiObject -Namespace 'root\directory\ldap' -Query "SELECT * FROM DS_computer WHERE DS_cn = '${env:ComputerName}'"
        
        $adComputer = @{}
        $adComputer.DS = @{}
        
        if ($computer) {
            Write-Information "[Get-ADComputerCurrent] Computer Found: $($computer | ConvertTo-Json)"
    
            foreach ($property in $computer.PSObject.Properties) {
                if ($property.Value) {
                    if (($property.Name).StartsWith('DS_')) {
                        $adComputer.DS.Add(($property.Name).TrimStart('DS_'), $property.Value)
                    } else {
                        $adComputer.Add($property.Name, $property.Value)
                    }
                }
            }
        } else {
            Write-Information "[Get-ADComputerCurrent] Computer NOT Found; trying [ADSISearcher] to at least get the DN."
            try {
                $computer = ([adsisearcher]"(&(name=${env:ComputerName})(objectcategory=computer))").FindOne()
            } catch [System.Management.Automation.MethodInvocationException] {
                if ($Error[0].Exception.InnerException.Message) {
                    Write-Warning "[Get-ADComputerCurrent][ADSISearcher] $($Error[0].Exception.InnerException.Message)"
                } else {
                    Write-Warning "[Get-ADComputerCurrent][ADSISearcher] $($Error[0].Exception.Message)"
                }
            }
            
            if ($computer) {
                Write-Information "[Get-ADComputerCurrent][ADSISearcher] Computer Found: $($computer | ConvertTo-Json)"
                $adComputer.DS.distinguishedName = $computer.Path -replace '^LDAP://', ''
            } else {
                Write-Warning "[Get-ADComputerCurrent][ADSISearcher] Computer Not Found! Two known reasons:`n- This needs to be run as `System` or a domain user account to authenticate to the domain, we're currently running as: $(whoami); ${env:UserName}.`n- Computer may have lost trust with the domain."
            }
        }
    }

    Write-Information "[Get-ADComputerCurrent] Return: $($adComputer | ConvertTo-Json)"
    return $adComputer
}