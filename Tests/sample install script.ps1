<#
MECM Install Command:
    powershell.exe -Exe Bypass -Win Hidden -NoP -NonI -File 'sample install script.ps1' -Version 1.2.3
#>
param(
    # [Parameter(Mandatory = $true)]
    [Version]
    $Version = '1.2.3'
)
. 'C:\Users\qhm067\OneDrive - University of Texas at San Antonio\Git\PSWinstall\PSBacon\Private\Initialize.ps1'
$global:bacon = [Bacon]::new('Mozilla', 'Firefox', $Version, 'test')
$bacon

Write-Information ('{3}ing {0} {1} {2} ...' -f $bacon.Publisher, $bacon.Product, $bacon.Version, (Get-Culture).TextInfo.ToTitleCase($bacon.Action))

$Invoke_MSI = @{
    'Action' = 'Install'
    'Parameters' = @(
        "USERNAME=`"$($settings.Installer.UserName)`"",
        "COMPANYNAME=`"$($settings.Installer.CompanyName)`"",
        "SERIALNUMBER=`"$($settings.Installer.SerialNumber)`""
    )
}

if ([System.Environment]::Is64BitOperatingSystem) {
    Invoke-BaconMsi @Invoke_MSI -Path 'FirefoxSetup32and64Bit.msi'
} else {
    Invoke-BaconMsi @Invoke_MSI -Path 'FirefoxSetup32Bit.msi'
}

# $bacon.ExitCode = 1603

# asdfkljaslkdfjaslkdfj

# sdfsakdjflksajd

# sadflkjaslkdf

# Exit $bacon.ExitCode
# $Host.SetShouldExit($bacon.ExitCode)