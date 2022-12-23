<#
MECM Install Command:
    powershell.exe -Exe Bypass -Win Hidden -NoP -NonI -File install.ps1
#>
#Requires -Modules PSRedstone
$global:Redstone = [Redstone]::new()
$global:settings = $Redstone.Settings.JSON.Data

Write-Information ('{3}ing {0} {1} {2} ...' -f $Redstone.Publisher, $Redstone.Product, $Redstone.Version, (Get-Culture).TextInfo.ToTitleCase($Redstone.Action))

$invokeMSI = @{
    'Action' = 'Install'
    'Parameters' = @(
        "USERNAME=`"$($settings.Installer.UserName)`"",
        "COMPANYNAME=`"$($settings.Installer.CompanyName)`"",
        "SERIALNUMBER=`"$($settings.Installer.SerialNumber)`""
    )
}

if ([System.Environment]::Is64BitOperatingSystem) {
    Invoke-RedstoneMsi @invokeMSI -Path 'FirefoxSetup32and64Bit.msi'
} else {
    Invoke-RedstoneMsi @invokeMSI -Path 'FirefoxSetup32Bit.msi'
}
