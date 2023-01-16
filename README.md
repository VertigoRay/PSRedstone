[![Build status](https://ci.appveyor.com/api/projects/status/a9whj5lwwi4fo9yo/branch/master?svg=true)](https://ci.appveyor.com/project/VertigoRay/psredstone)
[![codecov](https://codecov.io/gh/VertigoRay/PSRedstone/branch/master/graph/badge.svg)](https://codecov.io/gh/VertigoRay/PSRedstone)
[![version](https://img.shields.io/powershellgallery/v/PSRedstone.svg)](https://www.powershellgallery.com/packages/PSRedstone)
[![downloads](https://img.shields.io/powershellgallery/dt/PSRedstone.svg?label=downloads)](https://www.powershellgallery.com/stats/packages/PSRedstone?groupby=Version)
[![PSScriptAnalyzer](https://github.com/VertigoRay/PSRedstone/actions/workflows/powershell.yml/badge.svg)](https://github.com/VertigoRay/PSRedstone/actions/workflows/powershell.yml)
[![Codacy Security Scan](https://github.com/VertigoRay/PSRedstone/actions/workflows/codacy.yml/badge.svg)](https://github.com/VertigoRay/PSRedstone/actions/workflows/codacy.yml)
[![DevSkim](https://github.com/VertigoRay/PSRedstone/actions/workflows/devskim.yml/badge.svg)](https://github.com/VertigoRay/PSRedstone/actions/workflows/devskim.yml)

![PSRedstone](https://tinyurl.com/2p8xny2m) is a module used to streamline the installation of Windows applications.
It includes a *Redstone* class, which is the core building block for the included functions.
It is designed to be lightweight and easy to deploy.
While I use [MECM for my CM tool](https://learn.microsoft.com/en-us/mem/configmgr/), you should be able to use *PSRedstone* with [whatever tool you choose](https://www.reddit.com/r/sysadmin/comments/2go43q/comment/ckkydh4/).

**Why did I name this module *Redstone*?**It should go without saying that [I'm a fan](https://namemc.com/profile/VertigoRay) of [Minecraft](https://www.minecraft.net).
The simplicity of the game and how far you can push things into automation, even without any mods, is quite enthralling.
Obviously, mining [redstone](https://minecraft.fandom.com/wiki/Redstone_Ore) is the first step to building more elaborate creations in Minecraft.
I believe that using PSRedstone will be a good first step to building more elaborate, yet simple, deployment packages.

- [Quick Start](#quick-start)
- [Instantiating *Redstone*](#instantiating-redstone)
  - [The Settings JSON File](#the-settings-json-file)
    - [Sample JSON](#sample-json)
- [Logging](#logging)

# Quick Start

Start with a `settings.json` file and a very basic configuration:

```json
{
    "Publisher": "Mozilla",
    "Product": "Firefox RR",
    "Version": "1.2.3",
    "Installer": {
        "UserName": "VertigoRay",
        "CompanyName": "PSRedstone & Co.",
        "SerialNumber": "bfa7409e-485c-45cf-bd42-1652c2c84e17"
    }
}
```

> ℹ: The version *should* be injected/updated via automated processes, but we statically defined it for this example.

You just need a *Redstone Block* ( ͡° ͜ʖ ͡°) at the top of your script to use the module:

```powershell
#region Redstone Block
#Requires -Modules PSRedstone
$redstone, $settings = New-Redstone
#endregion Redstone Block
```

Using that, we can create a simple `install.ps1` for the installer:

```powershell
<#
MECM Install Command:
    powershell.exe -Exe Bypass -Win Hidden -NoP -NonI -File install.ps1
#>
#Requires -Modules PSRedstone
$redstone, $settings = New-Redstone

Write-Information ('{3}ing {0} {1} {2} ...' -f $redstone.Publisher, $redstone.Product, $redstone.Version, (Get-Culture).TextInfo.ToTitleCase($redstone.Action))

$invokeMSI = @{
    'Action' = 'Install'
    # Obviously, Firefox doesn't require these advanced install options.
    # This is just for show ...
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
```

> ℹ: *Redstone* will automatically parse the `settings.json` file, because it exists.
> The `settings.json` data is in the class, but we create you a `$settings` variable as well.
>   - `$Redstone.Publisher`: taken directly from the root key in the `settings.json`.
>   - `$Redstone.Product`: taken directly from the root key in the `settings.json`.
>   - `$Redstone.Version`: taken directly from the root key in the `settings.json`; this would normally be injected into the file during the set up of the MECM Package Source files.
>   - `$Redstone.Action`: taken directly from the filename of the script; in this case the *Action* is `"install"` taken from `install.ps1`.
>     - We use `Get-Culture` to capitalize the first letter and make it `"Install"`.
>
> Given the above details, the output of `Write-Information` will be:
>
>     Installing Mozilla Firefox RR 1.2.3 ...
>
> The `Invoke-RedstoneMsi` will call the `msiexec` silently by default and provide a standardized location for the MSI log file under `C:\Windows\Logs`.

The goal has been achieved: a simplified install script with predictable results.

> ℹ: Check out the [Advanced Start](https://github.com/VertigoRay/PSRedstone/wiki/Advanced-Start) wiki for more assistance getting started.
