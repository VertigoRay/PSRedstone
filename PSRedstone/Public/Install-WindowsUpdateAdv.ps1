<#
.SYNOPSIS
This is an advanced function for scheduling the install and reboot Windows Updates.
It utilizes and augments functionality provided by [PSWindowsUpdate](https://www.powershellgallery.com/packages/PSWindowsUpdate).
.DESCRIPTION
This advanced function for installing Windows Updates will try to fix Windows Updates, if desired, and fail back to non-PowerShell mechanisms for forcing Windows Updates.
It utilizes and augments functionality provided by [PSWindowsUpdate](https://www.powershellgallery.com/packages/PSWindowsUpdate).

If you want PSWindowsUpdate to send a report, you can use [PSDefaultParameterValues](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parameters_default_values?view=powershell-5.1) to make that happen:

```powershell
$PSDefaultParameterValues.Set_Item('Install-WindowsUpdate:SendReport', $true)
$PSDefaultParameterValues.Set_Item('Install-WindowsUpdate:SendHistory', $true)
$PSDefaultParameterValues.Set_Item('Install-WindowsUpdate:PSWUSettings', @{
    SmtpServer = 'smtp.sendgrid.net'
    Port = 465
    UseSsl = $true
    From = '{1} <{0}@mailinator.com>' -f (& HOSTNAME.EXE), $env:ComputerName
    To = 'PSRedstone@mailinator.com'
})
```
.PARAMETER LastDeploymentChangeThresholdDays
When using `PSWindowsUpdate`, this will check the `LastDeploymentChangeTime` and install updates past the threshold.
.PARAMETER ScheduleJob
Schedule with a valid `[datetime]` value.
I suggest using `Get-Date -Format O` to get a convertable string.

```powershell
$scheduleJob = (Get-Date -Format 'MM-dd-yyyy' | Get-Date).AddDays(1).AddHours(-7) | Get-Date -Format 'O' # 5pm today
```
.PARAMETER ScheduleReboot
Schedule with a valid `[datetime]` value.
I suggest using `Get-Date -Format O` to get a convertable string.

```powershell
$scheduleReboot = (Get-Date -Format 'MM-dd-yyyy' | Get-Date).AddDays(1).AddHours(-1) | Get-Date -Format 'O' # 11pm today
```
.PARAMETER NoPSWindowsUpdate
Do NOT install the PSWindowsUpdate module.
When this option is used, none of the advanced scheduling or reporting options are available.
.PARAMETER ToastNotification
If this parameter is not provided, not Toast Notification will be shown.
A hashtable used to [splat](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting?view=powershell-5.1) into the PSRedstone Show-ToastNotification function.

The `ToastText` parameter will be [formatted](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators?view=powershell-5.1#format-operator--f) with:

0. `$updateCount`
1. `$ToastNotification.ToastTextFormatters[0][$updateCount -gt 1]`
2. `$ToastNotification.ToastTextFormatters[1][$updateCount -gt 1]`
3. `$ToastNotification.ToastTextFormatters[2][$ScheduleJob -as [bool]]`
4. `$ToastNotification.ToastTextFormatters[3][$ScheduleReboot -as [bool]]`

Here's an example:

```powershell
$lastDeploymentChangeThresholdDays = 30
$scheduleJob = (Get-Date -Format 'MM-dd-yyyy' | Get-Date).AddDays(1).AddHours(-7) | Get-Date -Format 'O' # 5pm today
$scheduleReboot = (Get-Date -Format 'MM-dd-yyyy' | Get-Date).AddDays(1).AddHours(-1) | Get-Date -Format 'O' # 11pm today

$toastNotification  = @{
    ToastNotifier = 'Tech Solutions: Endpoint Solutions Engineering'
    ToastTitle = 'Windows Update'
    ToastText = 'This computer is at least 30 days overdue for {0} Windows Update{1}. {2} being forced on your system {3}. A reboot may occur {4}.'
    ToastTextFormatters = @(
        @($null, 's')
        @('The update is', 'Updates are')
        @(('on {0}' -f ($scheduleJob | Get-Date -Format (Get-Culture).DateTimeFormat.FullDateTimePattern)), 'now')
        @(('on {0}' -f ($scheduleReboot | Get-Date -Format (Get-Culture).DateTimeFormat.FullDateTimePattern)), 'immediately afterwards')
    )
}
```

When `$toastNotification` is passed to this function, and there are five Windows Updates past due, it will result in a Toast Notification like this:

> `Tech Solutions: Endpoint Solutions Engineering`
>
> # Windows Update
>
> This computer is at least 30 days overdue for 5 Windows Updates. Updates are being forced on your system on Saturday, February 11, 2023 5:00:00 PM. Reboot will occur on Saturday, February 11, 2023 11:00:00 PM.
.PARAMETER FixWUAU
Attempt to fix the WUAU service.
.EXAMPLE
Install-WindowsUpdateAdv

This will install all available updates now and restart now.
.EXAMPLE
Install-WindowsUpdateAdv -FixWUAU

This will attempt to fix the WUAU service, install all available updates now, and restart immediately afterwards.
.EXAMPLE
Install-WindowsUpdateAdv -LastDeploymentChangeThresholdDays 30 -FixWUAU

This will attempt to fix the WUAU service, install all available updates now that are more than 30 days old, and restart immediately afterwards.
.EXAMPLE
Install-WindowsUpdateAdv -LastDeploymentChangeThresholdDays 30 -FixWUAU -ScheduleJob ((Get-Date -Format 'MM-dd-yyyy' | Get-Date).AddDays(1).AddHours(-7) | Get-Date -Format 'O')

This will attempt to fix the WUAU service now, install all available updates today at 5 pm that are more than 30 days old, and restart immediately afterwards.
.EXAMPLE
Install-WindowsUpdateAdv -LastDeploymentChangeThresholdDays 30 -FixWUAU -ScheduleJob ((Get-Date -Format 'MM-dd-yyyy' | Get-Date).AddDays(1).AddHours(-7) | Get-Date -Format 'O') -ScheduleReboot ((Get-Date -Format 'MM-dd-yyyy' | Get-Date).AddDays(1).AddHours(-1) | Get-Date -Format 'O')

This will attempt to fix the WUAU service now, install all available updates today at 5 pm that are more than 30 days old, and restart today at 11 pm.
.EXAMPLE
Install-WindowsUpdateAdv -LastDeploymentChangeThresholdDays 30 -FixWUAU -ScheduleJob $scheduleJob -ScheduleReboot $scheduleReboot -ToastNotification $toastNotification

This will show a toast notification for any logged on users, attempt to fix the WUAU service now, install all available updates today at 5 pm that are more than 30 days old, and restart today at 11 pm. The variables were defined like this:

```powershell
$scheduleJob = (Get-Date -Format 'MM-dd-yyyy' | Get-Date).AddDays(1).AddHours(-7) | Get-Date -Format 'O' # 5pm today
$scheduleReboot = (Get-Date -Format 'MM-dd-yyyy' | Get-Date).AddDays(1).AddHours(-1) | Get-Date -Format 'O' # 11pm today

$toastNotification  = @{
    ToastNotifier = 'Tech Solutions: Endpoint Solutions Engineering'
    ToastTitle = 'Windows Update'
    ToastText = 'This computer is at least 30 days overdue for {0} Windows Update{1}. {2} being forced on your system {3}. A reboot may occur {4}.'
    ToastTextFormatters = @(
        @($null, 's')
        @('The update is', 'Updates are')
        @(('on {0}' -f ($scheduleJob | Get-Date -Format (Get-Culture).DateTimeFormat.FullDateTimePattern)), 'now')
        @(('on {0}' -f ($scheduleReboot | Get-Date -Format (Get-Culture).DateTimeFormat.FullDateTimePattern)), 'immediately afterwards')
    )
}
```
.EXAMPLE
Install-WindowsUpdateAdv -FixWUAU -NoPSWindowsUpdate

This will attempt to fix the WUAU service, install all available updates now, and restart immediately afterwards.
.NOTES
#>
function Install-WindowsUpdateAdv {
    [CmdletBinding(DefaultParameterSetName = 'PSWindowsUpdate')]
    param(
        [Parameter(HelpMessage = 'When using PSWindowsUpdate, this will check the LastDeploymentChangeTime and install updates past the threshold.', ParameterSetName = 'PSWindowsUpdate')]
        [int]
        $LastDeploymentChangeThresholdDays,

        [Parameter(HelpMessage = 'Schedule with a valid datetime value. I suggest using `Get-Date -Format O` to get a convertable string.', ParameterSetName = 'PSWindowsUpdate')]
        [datetime]
        $ScheduleJob,

        [Parameter(HelpMessage = 'Schedule with a valid datetime value. I suggest using `Get-Date -Format O` to get a convertable string.', ParameterSetName = 'PSWindowsUpdate')]
        [datetime]
        $ScheduleReboot,

        [Parameter(HelpMessage = 'Do NOT install the PSWindowsUpdate module.', ParameterSetName = 'NoPSWindowsUpdate')]
        [switch]
        $NoPSWindowsUpdate,

        [Parameter(HelpMessage = 'Parameters for Show-ToastNotification, if a toast notification is desired.', ParameterSetName = 'PSWindowsUpdate')]
        [Parameter(HelpMessage = 'Parameters for Show-ToastNotification, if a toast notification is desired.', ParameterSetName = 'NoPSWindowsUpdate')]
        [hashtable]
        $ToastNotification,

        [Parameter(HelpMessage = 'Attempt to fix the WUAU service.', ParameterSetName = 'PSWindowsUpdate')]
        [Parameter(HelpMessage = 'Attempt to fix the WUAU service.', ParameterSetName = 'NoPSWindowsUpdate')]
        [switch]
        $FixWUAU
    )

    if (($PSVersionTable.PSVersion -ge '5.1')) {
        if (-not $NoPSWindowsUpdate.IsPresent) {
            [version] $nugetPPMinVersion = '2.8.5.201'
            if (-not (Get-PackageProvider -Name 'NuGet' -ErrorAction 'Ignore' | Where-Object { $_.Version -ge $nugetPPMinVersion })) {
                Install-PackageProvider -Name 'NuGet' -MinimumVersion $nugetPPMinVersion -Force | Out-Null
            }
            [version] $psWindowsUpdateMinVersion = '2.2.0.3'
            if (-not (Get-Module -Name 'PSWindowsUpdate' -ErrorAction 'Ignore' | Where-Object { $_.Version -ge $psWindowsUpdateMinVersion })) {
                Install-Module -Name 'PSWindowsUpdate' -Scope 'CurrentUser' -MinimumVersion $psWindowsUpdateMinVersion -Confirm:$false -Force -ErrorAction Ignore | Out-Null
            }
        }

        $updates = Get-WindowsUpdate
        if ($MyInvocation.BoundParameters.Keys -contains 'LastDeploymentChangeThresholdDays') {
            $updates | Where-Object { $_.LastDeploymentChangeTime -lt (Get-Date).AddDays(-$LastDeploymentChangeThresholdDays) }
        }
        $updateCount = ($updates | Measure-Object).Count
        if ($updateCount -eq 0) {
            Write-Verbose '[Install-WindowsUpdate] Update Count: 0'
            return $updates
        } else {
            Write-Output ('[Install-WindowsUpdate] Update Count: {0}' -f $updateCount)
        }

        if ($ToastNotification) {
            $toastNotification  = @{
                ToastNotifier = 'Tech Solutions: Endpoint Solutions Engineering'
                ToastTitle = 'Windows Update'
                ToastText =  'This computer is overdue for {0} Windows Update{1} and the time threshold has exceeded. {2} being forced on your system {3}.{4}' -f @(
                    $updateCount
                    $ToastNotification.ToastTextFormatters[0][$updateCount -gt 1]
                    $ToastNotification.ToastTextFormatters[1][$updateCount -gt 1]
                    $ToastNotification.ToastTextFormatters[2][$ScheduleJob -as [bool]]
                    $ToastNotification.ToastTextFormatters[3][$ScheduleReboot -as [bool]]
                )
            }
            $ToastNotification.Remove('ToastTextFormatters')

            Show-ToastNotification @toastNotification
        }
    }

    if ($FixWUAU.IsPresent) {
        Stop-Service -Name 'wuauserv'
        Remove-Item 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Recurse -Force
        Remove-Item ([IO.Path]::Combine($env:SystemRoot, 'SoftwareDistribution', '*')) -Recurse -Force

        & dism.exe /Online /Cleanup-Image /Restorehealth | Out-Null
        & sfc.exe /scannow | Out-Null

        Get-Service -Name 'wuauserv' | Set-Service -StartupType 'Automatic' | Out-Null
        Start-Service -Name 'wuauserv'
    }

    $altWindowsUpdate = {
        if (Get-Command -Name 'UsoClient.exe' -ErrorAction 'Ignore') {
            # wuauclt has been replaced by usoclient; if it exists, use it.
            & UsoClient.exe RefreshSettings StartScan StartDownload StartInstall
        } else {
            & wuauclt.exe /detectnow /updatenow
        }
    }

    if (-not $NoPSWindowsUpdate.IsPresent) {
        try {
            $installWindowsUpdate = @{
                MicrosoftUpdate = $true
                SendHistory = $true
                AcceptAll = $true
            }

            if ($ScheduleJob) {
                $installWindowsUpdate.Add('ScheduleJob', $ScheduleJob)
            }

            if ($ScheduleReboot) {
                $installWindowsUpdate.Add('ScheduleReboot', $ScheduleReboot)
            } else {
                $installWindowsUpdate.Add('AutoReboot', $true)
            }

            Install-WindowsUpdate @installWindowsUpdate -Verbose
        } catch {
            & $altWindowsUpdate
        }
    } else {
        & $altWindowsUpdate
    }
}
