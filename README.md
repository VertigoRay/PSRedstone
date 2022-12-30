[![Build status](https://ci.appveyor.com/api/projects/status/a9whj5lwwi4fo9yo/branch/master?svg=true)](https://ci.appveyor.com/project/VertigoRay/psredstone)
[![codecov](https://codecov.io/gh/VertigoRay/PSRedstone/branch/master/graph/badge.svg)](https://codecov.io/gh/VertigoRay/PSRedstone)
[![version](https://img.shields.io/powershellgallery/v/PSRedstone.svg)](https://www.powershellgallery.com/packages/PSRedstone)
[![downloads](https://img.shields.io/powershellgallery/dt/PSRedstone.svg?label=downloads)](https://www.powershellgallery.com/stats/packages/PSRedstone?groupby=Version)

![PSRedstone](https://placehold.co/80x15/red/white?text=PSRedstone) is a module used to streamline installation of Windows Applications.
It includes a *Redstone* class, which is the core building block for the included functions.

- [Quick Start](#quick-start)
- [Instantiating *Redstone*](#instantiating-redstone)
  - [The Settings JSON File](#the-settings-json-file)
    - [Sample JSON](#sample-json)

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
$global:Redstone = [Redstone]::new()
#endregion Redstone Block
```

Using that, we can create a simple `install.ps1` for the installer:

```powershell
<#
MECM Install Command:
    powershell.exe -Exe Bypass -Win Hidden -NoP -NonI -File install.ps1
#>
#Requires -Modules PSRedstone
$global:Redstone = [Redstone]::new()

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
```

> ℹ: *Redstone* will automatically parse the `settings.json` file if it exists.
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

# Instantiating *Redstone*

*Redstone* can be instantiated in one of two way:

- Without parameters: `$global:Redstone = [Redstone]::new()`
- With parameters: `$global:Redstone = [Redstone]::new($Publisher, $Product, $Version, $Action)`; where all of those parameters are `[string]`s.

If *Redstone* is instantiated with no parameters, [a `settings.json`](#the-settings-json-file) must be provided.
## The Settings JSON File

*Redstone* will look for the case-insensitive JSON file named `settings.json` file in the following order:

1. In the current working directory using [`$PWD`](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables#pwd).
1. In the same directory where the executing script is; the [`$PSScriptRoot`](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables#psscriptroot) of the file that instantiated *Redstone*.

If a `settings.json` is provided *Redstone* will import the data to `$Redstone.Settings.JSON.Data`.
To make the data more accessible, Redstone will also create a `$global:settings` for the data in the `settings.json` file.

### Sample JSON

At a minimum, the following structure is required:

```json
{
    "Publisher": "Mozilla",
    "Product": "Firefox RR",
    "Version": "1.2.3"
}
```

After instantiation, `Publisher` should be accessed via:

- `$settings.Publisher`
- `$global:settings.Publisher`

> ℹ: If you instantiate with parameters, `Publisher` can be accessed the same way.

Anything else in the `settings.json` is arbitrary and is purely for use in your scripts.
See the [Quick Start](#quick-start) for an example.