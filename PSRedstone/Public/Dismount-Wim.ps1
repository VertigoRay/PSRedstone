#Requires -RunAsAdministrator
<#
.SYNOPSIS
Dismount a WIM.
.DESCRIPTION
Dismount a WIM from the provided mount path.
.EXAMPLE
Dismount-Wim -MountPath $mountPath

Where `$mountPath` is the path returned by `Mount-Wim`.
.LINK
https://github.com/VertigoRay/PSRedstone/wiki/Functions#dismount-wim
#>
function Dismount-Wim {
    [CmdletBinding()]
    [OutputType([void])]
    param (
        # Specifies a path to one or more locations.
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = 'Path the WIM was mounted.')]
        [ValidateNotNullOrEmpty()]
        [IO.DirectoryInfo]
        $MountPath,

        [Parameter(Mandatory = $false, HelpMessage = 'Full path for the DISM log with {0} formatter to inject "DISM".')]
        [IO.FileInfo]
        $LogFileF
    )

    begin {
        Write-Verbose "[Dismount-Wim] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
        Write-Debug "[Dismount-Wim] Function Invocation: $($MyInvocation | Out-String)"

        $windowsImage = @{
            Path = $MountPath.FullName
            Discard = $true
            ErrorAction = 'Stop'
        }

        if ($LogFileF) {
            $windowsImage.Add('LogPath', ($LogFileF -f 'DISM'))
        }

        <#
            Script used inside of the Scheduled Task that's created, if needed.
        #>
        $mounted = {
            $mountedInvalid = Get-WindowsImage -Mounted | Where-Object { $_.MountStatus -eq 'Invalid' }
            $errorOccured = $false
            foreach ($mountedWim in $mountedInvalid) {
                $windowsImage = @{
                    Path = $mountedWim.Path
                    Discard = $true
                    ErrorAction = 'Stop'
                }

                try {
                    Dismount-WindowsImage @windowsImage
                } catch {
                    $errorOccured = $true
                }
            }

            if (-not $errorOccured) {
                Clear-WindowsCorruptMountPoint
                Unregister-ScheduledTask -TaskName 'Redstone Cleanup WIM' -Confirm:$false
            }
        }
        $encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($mounted.ToString()))
        $cleanupTaskAction = @{
            Execute = 'powershell.exe'
            Argument = '-Exe Bypass -Win Hidden -NoProfile -NonInteractive -EncodedCommand {0}' -f $encodedCommand.tostring()
        }
    }

    process {
        ## dismount the WIM whether we succeeded or failed
        try {
            Write-Verbose "[Dismount-Wim] Dismount-WindowImage: $($windowsImage | ConvertTo-Json)"
            Dismount-WindowsImage @windowsImage
        } catch [System.Runtime.InteropServices.COMException] {
            Write-Warning ('[Dismount-Wim] [{0}] {1}' -f $_.Exception.GetType().FullName, $_.Exception.Message)
            if ($_.Exception.Message -eq 'The system cannot find the file specified.') {
                Throw $_
            } else {
                # $_.Exception.Message -eq 'The system cannot find the file specified.'
                ## failed to cleanly dismount, so set a task to cleanup after reboot

                Write-Verbose ('[Dismount-Wim] Scheduled Task Action: {0}' -f ($cleanupTaskAction | ConvertTo-Json))

                $scheduledTaskAction = New-ScheduledTaskAction @cleanupTaskAction
                $scheduledTaskTrigger = New-ScheduledTaskTrigger -AtStartup

                $scheduledTask = @{
                    Action = $scheduledTaskAction
                    Trigger = $scheduledTaskTrigger
                    TaskName = 'Redstone Cleanup WIM'
                    Description = 'Clean up WIM Mount points that failed to dismount properly.'
                    User = 'NT AUTHORITY\SYSTEM'
                    RunLevel = 'Highest'
                    Force = $true
                }
                Write-Verbose ('[Dismount-Wim] Scheduled Task: {0}' -f ($scheduledTask | ConvertTo-Json))
                Register-ScheduledTask @scheduledTask
            }
        }

        $clearWindowsCorruptMountPoint = @{}
        if ($LogFileF) {
            $windowsImage.Add('LogPath', ($LogFileF -f ('DISM')))
        }

        Clear-WindowsCorruptMountPoint @clearWindowsCorruptMountPoint
    }

    end {}
}
#region DEVONLY
# Dismount-Wim
#endregion
