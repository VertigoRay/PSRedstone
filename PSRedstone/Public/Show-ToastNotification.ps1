<#

.EXAMPLE
Show-ToastNotification @toastNotification

This re

if ($ScheduleJob) { $jobTimespan = New-TimeSpan -Start ([datetime]::Now) -End $ScheduleJob }
    if ($ScheduleReboot) { $rebootTimespan = New-TimeSpan -Start ([datetime]::Now) -End $ScheduleReboot }

    $toastNotification  = @{
        ToastNotifier = 'Tech Solutions: Endpoint Solutions Engineering'
        ToastTitle = 'Windows Update'
        ToastText =  'This computer is overdue for {0} Windows Update{1} and the time threshold has exceeded. {2} being forced on your system {3}.{4}' -f @(
            $updateCount
            $(if ($updateCount -gt 1) { 's' } else { $null })
            $(if ($updateCount -eq 1) { 'Updates are' } else { 'The update is' })
            $(if ($ScheduleJob) { 'on {0}' -f $ScheduleJob } else { 'now' })
            $(if ($ScheduleReboot) { ' Reboot will occur on {0}.' -f $ScheduleReboot } else { $null })
        )
    }

    Show-ToastNotification @toastNotification
#>
function Show-ToastNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]
        $ToastNotifier,

        [Parameter(Mandatory = $true)]
        [string]
        $ToastTitle,

        [Parameter(Mandatory = $true)]
        [string]
        $ToastText
    )

    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
    $Template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)

    $RawXml = [xml] $Template.GetXml()
    ($RawXml.toast.visual.binding.text | Where-Object { $_.id -eq '1' }).AppendChild($RawXml.CreateTextNode($ToastTitle)) | Out-Null
    ($RawXml.toast.visual.binding.text | Where-Object { $_.id -eq '2' }).AppendChild($RawXml.CreateTextNode($ToastText)) | Out-Null

    $SerializedXml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $SerializedXml.LoadXml($RawXml.OuterXml)

    $Toast = [Windows.UI.Notifications.ToastNotification]::new($SerializedXml)
    $Toast.Tag = $ToastNotifier.Split(':')[0]
    $Toast.Group = $ToastNotifier.Split(':')[0]
    $Toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(1)

    $Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($ToastNotifier)
    $Notifier.Show($Toast);
}

if (($PSVersionTable.PSVersion -ge '5.1')) {
    Install-PackageProvider -Name 'NuGet' -MinimumVersion 2.8.5.201 -Force | Out-Null
    Install-Module 'PSWindowsUpdate' -Scope 'CurrentUser' -Confirm:$false -Force -ErrorAction Ignore | Out-Null

    $updateCount = (Get-WindowsUpdate | Measure-Object).Count

    if ($updateCount -eq 0) {
        Write-Output 'Update Count: 0'
        Exit 0
    } else {
        Write-Output ('Update Count: {0}' -f $updateCount)
    }

    $toastNotification  = @{
        ToastNotifier = 'Tech Solutions: Endpoint Solutions Engineering'
        ToastTitle = 'Windows Update'
        ToastText =  'This computer is overdue for {0} Windows Update{1} and the time threshold has exceeded. {2} being forced on your system {3}.{4}' -f @(
            $updateCount
            $(if ($updateCount -gt 1) { 's' } else { $null })
            $(if ($updateCount -eq 1) { 'Updates are' } else { 'The update is' })
            $(if ($ScheduleJob) { 'on {0}' -f $ScheduleJob } else { 'now' })
            $(if ($ScheduleReboot) { ' Reboot will occur on {0}.' -f $ScheduleReboot } else { $null })
        )
    }

    Show-ToastNotification @toastNotification
}

Stop-Service -Name 'wuauserv'
Remove-Item 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' -Recurse -Force
Remove-Item 'C:\Windows\SoftwareDistribution\*' -Recurse -Force

& dism.exe /Online /Cleanup-Image /Restorehealth | Out-Null
& sfc /scannow | Out-Null

Get-Service 'wuauserv' | Set-Service -StartupType Automatic | Out-Null
Start-Service -name 'wuauserv'

try {
    Install-PackageProvider -Name 'NuGet' -MinimumVersion 2.8.5.201 -Force | Out-Null
    Install-Module 'PSWindowsUpdate' -Scope 'CurrentUser' -Confirm:$false -Force -ErrorAction 'Ignore' | Out-Null

    [IO.FileInfo] $psd1 = (Get-Module 'PSWindowsUpdate' -ListAvailable).Path
    [IO.FileInfo] $settingsXml = [IO.Path]::Combine($psd1.Directory.FullName, 'PSWUSettings.xml')

    @{
        SmtpServer = 'osmtp.utsa.edu'
        From = '{1} <{0}@utsarr.net>' -f (& HOSTNAME.EXE), $env:ComputerName
        To = 'endpoints@utsa.edu'
        Port = 25
    } | Export-Clixml -Path $settingsXml.FullName

    $installWindowsUpdate = @{
        MicrosoftUpdate = $true
        SendReport = $true
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
    if (Get-Command 'UsoClient.exe' -ErrorAction 'Ignore') {
        # wuauclt has been replaced by usoclient; if it exists, use it.
        & UsoClient.exe RefreshSettings StartScan StartDownload StartInstall
    } else {
        & wuauclt.exe /detectnow /updatenow
    }
}
