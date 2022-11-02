#Requires -RunAsAdministrator

function Dismount-BaconWim {
    [CmdletBinding()]
    param (
        # Specifies a path to one or more locations.
        [Parameter(
            Mandatory=$false,
            Position=0,
            ParameterSetName="ParameterSetName",
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            HelpMessage="Path to one or more locations."
        )]
        [ValidateNotNullOrEmpty()]
        [IO.DirectoryInfo]
        $MountPath = (Join-Path $PWD 'BaconMount'),

        [Parameter(Mandatory = $true)]
        [IO.FileInfo]
        $LogFileF
    )

    begin {
        Write-Verbose "[Dismount-BaconWim] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
        Write-Debug "[Dismount-BaconWim] Function Invocation: $($MyInvocation | Out-String)"

        $windowsImage = @{
            Path = $mountedWim.Path
            Discard = $true
            ErrorAction = 'Stop'
        }

        if ($LogFileF) {
            $windowsImage.Add('LogPath', ($LogFileF -f ('Dismount-' -f [System.Web.HTTPUtility]::UrlEncode($MountPath.FullName))))
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
                Unregister-ScheduledTask -TaskName 'Bacon Cleanup WIM' -Confirm:$false
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
            Write-Verbose "[Dismount-BaconWim] Dismount-WindowImage: $($windowsImage | ConvertTo-Json)"
            Dismount-WindowsImage @windowsImage
        } catch [System.Runtime.InteropServices.COMException] {
            Write-Warning ('[Dismount-BaconWim] [{0}] {1}' -f $_.Exception.GetType().FullName, $_.Exception.Message)
            if ($_.Exception.Message -eq 'The system cannot find the file specified.') {
                Throw $_
            } else {
                # $_.Exception.Message -eq 'The system cannot find the file specified.'
                ## failed to cleanly dismount, so set a task to cleanup after reboot

                Write-Verbose ('[Dismount-BaconWim] Scheduled Task Action: {0}' -f ($cleanupTaskAction | ConvertTo-Json))

                $scheduledTaskAction = New-ScheduledTaskAction @cleanupTaskAction
                $scheduledTaskTrigger = New-ScheduledTaskTrigger -AtStartup

                $scheduledTask = @{
                    Action = $scheduledTaskAction
                    Trigger = $scheduledTaskTrigger
                    TaskName = 'Bacon Cleanup WIM'
                    Description = 'Clean up WIM Mount points that failed to dismount properly.'
                    User = 'NT AUTHORITY\SYSTEM'
                    RunLevel = 'Highest'
                    Force = $true
                }
                Write-Verbose ('[Dismount-BaconWim] Scheduled Task: {0}' -f ($scheduledTask | ConvertTo-Json))
                Register-ScheduledTask @scheduledTask
            }
        }

        Clear-WindowsCorruptMountPoint -LogPath ($LogFileF -f 'DISM')
    }

    end {}
}

# Dismount-BaconWim