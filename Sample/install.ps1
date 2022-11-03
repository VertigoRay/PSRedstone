<#
MECM Install Command:
    powershell.exe -Exe Bypass -Win Hidden -NoP -NonI -File install.ps1
#>
#Requires -Modules PSBacon
$global:bacon = [Bacon]::new()
$global:settings = $bacon.Settings.JSON.Data

Write-Information ('{3}ing {0} {1} {2} ...' -f $bacon.Publisher, $bacon.Product, $bacon.Version, (Get-Culture).TextInfo.ToTitleCase($bacon.Action))

$invokeMSI = @{
    'Action' = 'Install'
    'Parameters' = @(
        "USERNAME=`"$($settings.Installer.UserName)`"",
        "COMPANYNAME=`"$($settings.Installer.CompanyName)`"",
        "SERIALNUMBER=`"$($settings.Installer.SerialNumber)`""
    )
}

if ([System.Environment]::Is64BitOperatingSystem) {
    Invoke-BaconMsi @invokeMSI -Path 'FirefoxSetup32and64Bit.msi'
} else {
    Invoke-BaconMsi @invokeMSI -Path 'FirefoxSetup32Bit.msi'
}
