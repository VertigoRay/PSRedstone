<#
.SYNOPSIS
Runs the given command.
.DESCRIPTION
This command sends a single command to `Start-Process` in a way that is standardized. For convenience, you can use the `Cmd` parameter, passing a single string that contains your executable and parameters; see examples.

The command will return a `[hashtable]` including the Process results, standard output, and standard error:

```
@{
    'Process' = $proc; # The result from Start-Process.
    'StdOut'  = $stdout; # This is an array, as returned from `Get-Content`.
    'StdErr'  = $stderr; # This is an array, as returned from `Get-Content`.
}
```

This function has been vetted for several years, but if you run into issues, try using `Start-Process`.
.PARAMETER Cmd
This is the command you wish to run, including arguments, as a single string.
.PARAMETER FilePath
Specifies the optional path and file name of the program that runs in the process. Enter the name of an executable file or of a document, such as a .txt or .doc file, that is associated with a program on the computer.

Passes Directly to `Start-Process`; see `Get-Help Start-Process`.
.PARAMETER ArgumentList
Specifies parameters or parameter values to use when this cmdlet starts the process.

Passes Directly to `Start-Process`; see `Get-Help Start-Process`.
.PARAMETER WorkingDirectory
Specifies the location of the executable file or document that runs in the process. The default is the current folder.

Passes Directly to `Start-Process`; see `Get-Help Start-Process`.
.PARAMETER PassThru
Returns a process object for each process that the cmdlet started. By default, this cmdlet does generate output.

Passes Directly to `Start-Process`; see `Get-Help Start-Process`.
.PARAMETER Wait
Indicates that this cmdlet waits for the specified process to complete before accepting more input. This parameter suppresses the command prompt or retains the window until the process finishes.

Passes Directly to `Start-Process`; see `Get-Help Start-Process`.
.PARAMETER WindowStyle
Specifies the state of the window that is used for the new process. The acceptable values for this parameter are: Normal, Hidden, Minimized, and Maximized.

Passes Directly to `Start-Process`; see `Get-Help Start-Process`.
.OUTPUTS
[hashtable]
.EXAMPLE
$result = Invoke-Run """${firefox_setup_exe}"" /INI=""${ini}"""
Use `Cmd` parameter
.EXAMPLE
$result = Invoke-Run -FilePath $firefox_setup_exe -ArgumentList @("/INI=""${ini}""")
Use `FilePath` and `ArgumentList` parameters
.EXAMPLE
$result.Process.ExitCode
Get the ExitCode
.LINK
https://github.com/VertigoRay/PSRedstone/wiki/Functions#invoke-run
#>
function Invoke-Run {
    [OutputType([hashtable])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Cmd')]
        [string]
        $Cmd,

        [Parameter(Mandatory = $true, ParameterSetName = 'FilePath')]
        [string]
        $FilePath,

        [Parameter(Mandatory = $false, ParameterSetName = 'FilePath')]
        [string[]]
        $ArgumentList,

        [Parameter(Mandatory = $false)]
        [switch]
        $CaptureConsoleOut,

        [Parameter(Mandatory = $false)]
        [string]
        $WorkingDirectory,

        [Parameter(Mandatory = $false)]
        [boolean]
        $PassThru = $true,

        [Parameter(Mandatory = $false)]
        [boolean]
        $Wait = $true,

        [Parameter(Mandatory = $false)]
        [string]
        $WindowStyle = 'Hidden',

        [Parameter(Mandatory = $false)]
        [IO.FileInfo]
        $LogFile
    )

    Write-Information ('[Invoke-Run] > {0}' -f ($MyInvocation.BoundParameters | ConvertTo-Json -Compress)) -Tags 'Redstone','Invoke-Run'
    Write-Debug ('[Invoke-Run] Function Invocation: {0}' -f ($MyInvocation | Out-String))

    if ($PsCmdlet.ParameterSetName -ieq 'Cmd') {
        Write-Verbose ('[Invoke-Run] Executing: {0}' -f $cmd)
        if ($Cmd -match '^(?:"([^"]+)")$|^(?:"([^"]+)") (.+)$|^(?:([^\s]+))$|^(?:([^\s]+)) (.+)$') {
            # https://regex101.com/r/uU4vH1/1

            Write-Verbose "Cmd Match: $($Matches | Out-String)"

            if ($Matches[1]) {
                $FilePath = $Matches[1]
            } elseif ($Matches[2]) {
                $FilePath = $Matches[2]
                $ArgumentList = $Matches[3]
            } elseif ($Matches[4]) {
                $FilePath = $Matches[4]
            } elseif ($Matches[5]) {
                $FilePath = $Matches[5]
                $ArgumentList = $Matches[6]
            }
        } else {
            Throw [System.Management.Automation.ParameterBindingException] ('Cmd Match Error: {0}' -f $cmd)
        }
    }

    [hashtable] $startProcess = @{
        FilePath                  = $FilePath
        PassThru                  = $PassThru
        Wait                      = $Wait
        WindowStyle               = $WindowStyle
    }

    if ($ArgumentList) {
        $startProcess.Add('ArgumentList', $ArgumentList)
    }

    if ($WorkingDirectory) {
        $startProcess.Add('WorkingDirectory', $WorkingDirectory)
    }

    if ($CaptureConsoleOut.IsPresent) {
        [IO.FileInfo] $stdout = New-TemporaryFile
        [IO.FileInfo] $stderr = New-TemporaryFile

        while (-not $stdout.Exists -or -not $stderr.Exists) {
            # Sometimes this is too fast
            # Let's wait for the tmp file to show up.
            Start-Sleep -Milliseconds 100
            $stdout.Refresh()
            $stderr.Refresh()
        }

        $startProcess.Add('RedirectStandardOutput', $stdout.FullName)
        $startProcess.Add('RedirectStandardError', $stderr.FullName)

        $monScript = {
            Param ([string] $Std, [IO.FileInfo] $Tmp, [IO.FileInfo] $LogFile)
            Get-Content $Tmp.FullName -Wait | ForEach-Object {
                ('STD{0}: {1}' -f $Std.ToUpper(), $_) | Out-File -Encoding 'utf8' -LiteralPath $LogFile.FullName -Append -Force
            }
        }

        $stdoutMon = [powershell]::Create()
        [void] $stdoutMon.AddScript($monScript).AddParameters(@{
            Std = 'Out'
            Tmp = $stdout.FullName
            LogFile = $LogFile.FullName
        })
        [void] $stdoutMon.BeginInvoke()

        $stderrMon = [powershell]::Create()
        [void] $stderrMon.AddScript($monScript).AddParameters(@{
            Std = 'Out'
            Tmp = $stderr.FullName
            LogFile = $LogFile.FullName
        })
        [void] $stderrMon.BeginInvoke()
    }

    Write-Information ('[Invoke-Run] Start-Process: {0}' -f (ConvertTo-Json $startProcess)) -Tags 'Redstone','Invoke-Run'
    $proc = Start-Process @startProcess
    Write-Verbose ('[Invoke-Run] ExitCode:' -f $proc.ExitCode)

    $return = @{
        Process = $proc
    }

    if ($CaptureConsoleOut.IsPresent) {
        $return.Add('StdOut', ((Get-Content $stdout.FullName | Out-String).Trim().Split([System.Environment]::NewLine)))
        $return.Add('StdErr', ((Get-Content $stderr.FullName | Out-String).Trim().Split([System.Environment]::NewLine)))

        $stdoutMon.Dispose()
        $stderrMon.Dispose()

        $stdout.FullName | Remove-Item -ErrorAction 'SilentlyContinue' -Force
        $stderr.FullName | Remove-Item -ErrorAction 'SilentlyContinue' -Force
    }

    try {
        Write-Information ('[Invoke-Run] Return: {0}' -f (ConvertTo-Json $return -Depth 1 -ErrorAction 'Stop')) -Tags 'Redstone','Invoke-Run'
    } catch {
        Write-Information ('[Invoke-Run] Return: {0}' -f ($return | Out-String)) -Tags 'Redstone','Invoke-Run'
    }
    return $return
}
