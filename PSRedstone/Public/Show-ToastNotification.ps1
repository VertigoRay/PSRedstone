<#

.EXAMPLE
Show-ToastNotification @toastNotification

This displays a toast notification.

```powershell
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
```
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

    $SerializedXml = New-Object 'Windows.Data.Xml.Dom.XmlDocument'
    $SerializedXml.LoadXml($RawXml.OuterXml)

    $Toast = [Windows.UI.Notifications.ToastNotification]::new($SerializedXml)
    $Toast.Tag = $ToastNotifier.Split(':')[0]
    $Toast.Group = $ToastNotifier.Split(':')[0]
    $Toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(1)

    $Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($ToastNotifier)
    $Notifier.Show($Toast);
}
