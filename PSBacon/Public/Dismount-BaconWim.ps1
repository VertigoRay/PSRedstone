function global:Dismount-BaconWim {
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
        $MountPath = (Join-Path $PWD 'BaconMount')
    )
    
    begin {
        Write-Information "[Dismount-BaconWim] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
        Write-Debug "[Dismount-BaconWim] Function Invocation: $($MyInvocation | Out-String)"

        $mounted = {
            $mountedInvalid = Get-WindowsImage -Mounted | Where-Object { $_.MountStatus -eq 'Invalid' }
            $errorOccured = $false
            foreach ($mountedWim in $mountedInvalid) {
                try {
                    $mountedWim | Dismount-WindowsImage -Discard -ErrorAction 'Stop'
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
            Dismount-WindowsImage -Path $MountPath -Discard
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
    }
    
    end {
        
    }
}

Dismount-BaconWim