<#
.SYNOPSIS
Close the supplied process.
.DESCRIPTION
The supplied process is expected to be a program and have a visible window.
This function will attempt to safely close the window before force killing the process.
It's a little safer than just doing a `Stop-Process -Force`.
.EXAMPLE
Get-Process code | Close-Program
.EXAMPLE
$codes = Get-Process code; $codes | Close-Program -SleepSeconds [math]::Ceiling($codes.Count / 2)
#>
function Close-Program {
    [CmdletBinding()]
    param (
        # Process to close.
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [System.Diagnostics.Process]
        $Process,

        # The number of seconds to wait after closing the main window before we force kill.
        # If passing this in a pipeline, this is per pipeline item; otherwise, it is the wait time for all processes.
        [Parameter(Mandatory = $false)]
        [int32]
        $SleepSeconds = 1
    )
    process {
        foreach ($proc in $Process) {
            $Process | ForEach-Object { $_.CloseMainWindow() | Out-Null }

            # Wait for windows to close before attempting a force kill.
            $sw = [System.Diagnostics.Stopwatch]::new()
            $sw.Start()

            while ($Process.HasExited -contains $false) {
                Start-Sleep -Milliseconds 250
                if ($sw.Elapsed.TotalSeconds -gt $SleepSeconds) {
                    break
                }
            }

            # In case gracefull shutdown did not succeed, try hard kill
            $Process | Where-Object { -not $_.HasExited } | Stop-Process -Force
        }
    }
}
