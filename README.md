[![Build status](https://ci.appveyor.com/api/projects/status/a9whj5lwwi4fo9yo/branch/master?svg=true)](https://ci.appveyor.com/project/VertigoRay/psredstone)
[![codecov](https://codecov.io/gh/VertigoRay/PSRedstone/branch/master/graph/badge.svg)](https://codecov.io/gh/VertigoRay/PSRedstone)
[![version](https://img.shields.io/powershellgallery/v/PSRedstone.svg)](https://www.powershellgallery.com/packages/PSRedstone)
[![downloads](https://img.shields.io/powershellgallery/dt/PSRedstone.svg?label=downloads)](https://www.powershellgallery.com/stats/packages/PSRedstone?groupby=Version)
[![PSScriptAnalyzer](https://github.com/VertigoRay/PSRedstone/actions/workflows/powershell.yml/badge.svg)](https://github.com/VertigoRay/PSRedstone/actions/workflows/powershell.yml)
[![Codacy Security Scan](https://github.com/VertigoRay/PSRedstone/actions/workflows/codacy.yml/badge.svg)](https://github.com/VertigoRay/PSRedstone/actions/workflows/codacy.yml)
[![DevSkim](https://github.com/VertigoRay/PSRedstone/actions/workflows/devskim.yml/badge.svg)](https://github.com/VertigoRay/PSRedstone/actions/workflows/devskim.yml)

![PSRedstone](https://tinyurl.com/2p8xny2m) is a module used to streamline installation of Windows Applications.
It includes a *Redstone* class, which is the core building block for the included functions.
It is designed to be light-weight and easy to deploy.
While I use [MECM for my CM tool](https://learn.microsoft.com/en-us/mem/configmgr/), you should be able to use *PSRedstone* with [whatever tool you choose](https://www.reddit.com/r/sysadmin/comments/2go43q/comment/ckkydh4/).

**Why did I name this module *Redstone*?**
It shoud go without saying that [I'm a fan](https://namemc.com/profile/VertigoRay) of [Minecraft](https://www.minecraft.net).
The simplicity of the game and how far you can push things into automation, even with out any mods, is quite enthralling.
Obviously, mining [redstone](https://minecraft.fandom.com/wiki/Redstone_Ore) is the first step to building more elaborate creations in Minecraft.
I believe that using PSRedstone will be a good first step to building more elaborate, yet simple, deployment packages.

- [Quick Start](#quick-start)
- [Advanced Start](#advanced-start)
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

# Advanced Start

As *PSRedstone* evolves, backwards compatibility will be a concern.
The only way for you to be sure that your install scripts will not break as *PSRedstone* updates, is to lock in the version of the module that you tested during package development.
Luckily, [the `#Requires` statement](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_requires?view=powershell-5.1) has this capability built right in.
Here's how you would set up a Redstone Block defining the tested version of *PSRedstone*.

```powershell
#region Redstone Block
#Requires -Modules @{ModuleName = 'PSRedstone'; RequiredVersion = '2023.1.4.62137'}
$redstone, $settings = New-Redstone
#endregion Redstone Block
```

That's great, but there's a few questions left to be answered:

1. How do I ensure all versions of *PSRedstone* that I need are pre-loaded on a brand new system?
2. How do I prevent version bloat and remove old *PSRedstone* versions that are no longer needed?

Anytime this Module is used, the version and timestamp will be stored in the registry under `HKEY_LOCAL_MACHINE\SOFTWARE\VertigoRay\PSRedstone\VersionsUsed`.
This will allow us to know what versions are still being used so that we can intelligently purge any unused versions.
Of course, a brand new computer will not have older versions of *PSRedstone* installed.
The easiest way around this (for now) would be to just install all versions os *PSRedstone* during imaging and let the script purge things after they have proven to not be in use.

I use an [MECM configuration item](https://learn.microsoft.com/en-us/mem/configmgr/compliance/deploy-use/create-configuration-items) to solve this, but you can use any method you have to deploy a script to your systems.
Take a look at the provided [`Remediation.ps1`](https://github.com/VertigoRay/PSRedstone/blob/master/Tools/Remediation.ps1), which will do the following:

> On first run, this script will install every version of *PSRedstone* from the minimum version required (see parameter `$MinimumVersionRequired`) to the latest version.
> It will timestamp each version in the registry with the current date at midnight (e.g.: `2023-01-08T00:00:00.0000000`).
> This should stand out to you as a version that was likely installed and never actually used.
>
> *PSRedstone* will also update the timestamp of it's current version each time the module is imported.
> This makes it very easy to tell what versions are active on the system.
> The second parameter (`$DaysAfterUnusedVersionAreUninstalled`) helps us decide when to uninstall unused versions.
>
> On the second run and all subsequent runs, this script will update to the lastest version of PSRestone, if needed.
> It will also go through all versions that are currently installed and purge any versions from the system that have not been used.

Of course, every good remediation needs a detection.
Take a look at the provided [`Detection.ps1`](https://github.com/VertigoRay/PSRedstone/blob/master/Tools/Detection.ps1) to see how I'm doing it.

# Instantiating *Redstone*

*Redstone* can be instantiated in one of three way:

- Without parameters: `New-Redstone`
- With a parameter: `New-Redstone $fullPathToSettingsJson`; where the parameter can be cast as `[IO.FileInfo]`, so a UNC path will not work.
- With parameters: `New-Redstone $Publisher $Product $Version $Action`; where all of those parameters are `[string]`s.

If *Redstone* is instantiated with no parameters, [a `settings.json`](#the-settings-json-file) must exist.
## The Settings JSON File

*Redstone* will look for the case-insensitive JSON file named `settings.json` file in the following order:

1. In the current working directory using [`$PWD`](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables#pwd).
1. In the same directory where the executing script is; the [`$PSScriptRoot`](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables#psscriptroot) of the file that instantiated *Redstone*.
1. In the parent of the current working directory using [`$PWD`](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables#pwd).
1. In the parent of the directory where the executing script is; the [`$PSScriptRoot`](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables#psscriptroot) of the file that instantiated *Redstone*.

If a `settings.json` is provided *Redstone* will import the data to `$Redstone.Settings.JSON.Data`.
To make the data more accessible, *Redstone* will output the JSON data as the second item of the returned array.
That's why we suggest setting up the *Redstone Block* the way we have.

### Sample JSON

At a minimum, the following structure is required:

```json
{
    "Publisher": "Mozilla",
    "Product": "Firefox RR",
    "Version": "1.2.3"
}
```

Assuming your *Redstone Block* was setup the same as our example above, `Publisher` should be accessed via:

- `$redstone.Settings.JSON.Data.Publisher`
- `$settings.Publisher`

> ℹ: If you instantiate with parameters, the `$settings` variable will be empty.

Anything else in the `settings.json` is arbitrary and is purely for use in your scripts.
See the [Quick Start](#quick-start) for an example.

# Logging

There are a many ways to log with PowerShell.
I have created a way that works well for me whether I'm in development, or troubleshooting a production run of a PowerShell script.
However, I did not build it into *PSRedstone*.
I believe that it can, and should, stand alone as its own module and be used regardless of if you are using *PSRedstone* or not.
So, check out [*PSWriteLog*](https://github.com/VertigoRay/PSWriteLog) and decide for yourself.
If you don't love it, come up with your own way of logging that suits your needs.

Here's how I set up *PSWriteLog* in my *PSRedstone Block*.

```powershell
#region Redstone Block
#Requires -Modules @{ModuleName = 'PSRedstone'; RequiredVersion = '2023.1.4.62137'},@{ModuleName = 'PSWriteLog'}
$redstone, $settings = New-Redstone

$PSDefaultParameterValues.Set_Item('Write-Log:FilePath', $redstone.Settings.Log.File.FullName)
$InformationPreference = 'Continue'
#endregion Redstone Block
```

> ℹ: If any of that is confusing to you, I suggest that you head over to the [*PSWriteLog* README](https://github.com/VertigoRay/PSWriteLog) for details.
