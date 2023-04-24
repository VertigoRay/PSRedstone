<#
.SYNOPSIS
Kill a process and all of its child processes.
.DESCRIPTION
Kill a process and all of its child processes.
Returns any processes that failed to stop; returning nothing if everything stopped sucessfully.
.OUTPUTS
System.Diagnostics.Process
.EXAMPLE
$stillRunning = Get-Process 'overwolf' | Stop-ProcessTree -Force
.EXAMPLE
$stillRunning = Stop-ProcessTree -Id 12345 -Force
.EXAMPLE
$stillRunning = Stop-ProcessTree -Name 'overwolf' -Force
#>
function Stop-ProcessTree {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'Process', HelpMessage = 'Provide a Process Object', ValueFromPipeline = $true)]
        [PSObject]
        $InputObject,

        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'ProcessId', HelpMessage = 'Provide a Process ID')]
        [int]
        $Id,

        [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'ProcessName', HelpMessage = 'Provide a Process Name')]
        [string]
        $Name,

        [Parameter(ParameterSetName = 'Process', HelpMessage = 'Force the Stop-Process')]
        [Parameter(ParameterSetName = 'ProcessId', HelpMessage = 'Force the Stop-Process')]
        [Parameter(ParameterSetName = 'ProcessName', HelpMessage = 'Force the Stop-Process')]
        [switch]
        $Force
    )


    Begin {}

    Process {
        if ($MyInvocation.BoundParameters.Id) {
            $InputObject = Get-Process -Id $MyInvocation.BoundParameters.Id
        }
        if ($MyInvocation.BoundParameters.Name) {
            $InputObject = Get-Process -Name $MyInvocation.BoundParameters.Name
        }
        Write-Verbose ('InputObject: {0}' -f $InputObject)

        foreach ($process in $InputObject) {
            Write-Verbose ('process: {0}' -f $process)
            Get-CimInstance 'Win32_Process' | Where-Object { $_.ParentProcessId -eq $process.Id } | ForEach-Object { Stop-ProcessTree -Id $_.ProcessId }
            try {
                if ($Force.IsPresent) {
                    Write-Verbose ('[Stop-ProcessTree] Stop-Process -Force: ({0}) {1} ({2}, {3}, {4}) {5}' -f $process.Id, $process.Name, $process.Company, $process.Product, $process.Description, $process.Path)
                    $process | Stop-Process -Force -ErrorAction 'Stop'
                } else {
                    Write-Verbose ('[Stop-ProcessTree] Stop-Process: ({0}) {1} ({2}, {3}, {4}) {5}' -f $process.Id, $process.Name, $process.Company, $process.Product, $process.Description, $process.Path)
                    $process | Stop-Process -ErrorAction 'Stop'
                }
            } catch {
                Write-Warning $_.Exception.Message
                Write-Output $process
            }
        }
    }

    End {}
}
