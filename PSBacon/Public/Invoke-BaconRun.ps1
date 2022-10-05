<#
.SYNOPSIS
Runs the given command.
.DESCRIPTION
This command sends a single command to `Start-Process` in a way that is standardized for Winstall. For convenience, you can use the `Cmd` parameter, passing a single string that contains your executable and parameters; see examples.

The command will return a `[hashtable]` including the Process results, standard output, and standard error.

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
Default: $$true

Returns a process object for each process that the cmdlet started. By default, this cmdlet does generate output.

Passes Directly to `Start-Process`; see `Get-Help Start-Process`.
.PARAMETER Wait
Default: $true

Indicates that this cmdlet waits for the specified process to complete before accepting more input. This parameter suppresses the command prompt or retains the window until the process finishes.

Passes Directly to `Start-Process`; see `Get-Help Start-Process`.
.PARAMETER WindowStyle
Default: Hidden

Specifies the state of the window that is used for the new process. The acceptable values for this parameter are: Normal, Hidden, Minimized, and Maximized.

Passes Directly to `Start-Process`; see `Get-Help Start-Process`.
.OUTPUTS
[hashtable]
@{
    'Process' = $proc; # The result from Start-Process.
    'StdOut'  = $stdout; # This is an array, as returned from `Get-Content`.
    'StdErr'  = $stderr; # This is an array, as returned from `Get-Content`.
}
.EXAMPLE
# Use `Cmd` parameter
$result = Invoke-Run """${firefox_setup_exe}"" /INI=""${ini}"""
.EXAMPLE
# Use `FilePath` and `ArgumentList` parameters
$result = Invoke-Run -FilePath $firefox_setup_exe -ArgumentList @("/INI=""${ini}""")
.EXAMPLE
# Get the ExitCode
$result = Invoke-Run """${firefox_setup_exe}"" /INI=""${ini}"""
$result.Process.ExitCode
.LINK
https://git.cas.unt.edu/winstall/winstall/wikis/Invoke-Run
#>
function Global:Invoke-Run {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0, ParameterSetName='Cmd')]
        [string]
        $Cmd,

        [Parameter(Mandatory=$true, ParameterSetName='FilePath')]
        [string]
        $FilePath,

        [Parameter(Mandatory=$false, ParameterSetName='FilePath')]
        [string[]]
        $ArgumentList,

        [Parameter(Mandatory=$false)]
        [string]
        $WorkingDirectory,

        [Parameter(Mandatory=$false)]
        [boolean]
        $PassThru = $true,

        [Parameter(Mandatory=$false)]
        [boolean]
        $Wait = $true,

        [Parameter(Mandatory=$false)]
        [string]
        $WindowStyle = 'Hidden',

        [Parameter(Mandatory=$false)]
        [IO.FileInfo]
        $LogFile
    )

    Write-Information "> $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Debug "Function Invocation: $($MyInvocation | Out-String)"


    if ($PsCmdlet.ParameterSetName -ieq 'Cmd') {
        Write-Verbose "Executing: $cmd"
        if ($cmd -match '^(?:"([^"]+)")$|^(?:"([^"]+)") (.+)$|^(?:([^\s]+))$|^(?:([^\s]+)) (.+)$') {
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
            $msg = "Cmd Match Error: ${cmd}"
            Write-Error $msg
            Throw [System.Management.Automation.ParameterBindingException] $msg
        }
    }

    [string] $process_guid = New-Guid
    [string] $stdout = New-TemporaryFile
    [string] $stderr = New-TemporaryFile

    [hashtable] $start_process = @{
        'FilePath'                  = $FilePath;
        'PassThru'                  = $PassThru;
        'Wait'                      = $Wait;
        'WindowStyle'               = $WindowStyle;
        'RedirectStandardError'     = $stderr
        'RedirectStandardOutput'    = $stdout
    }
    
    if ($ArgumentList) {
        [void] $start_process.Add('ArgumentList', $ArgumentList)
    }
    
    if ($WorkingDirectory) {
        [void] $start_process.Add('WorkingDirectory', $WorkingDirectory)
    }

    if ($LogFile) {
        # Monitor STDOUT and send to Log
        $stdout_job = Start-Job -Name "StdOut ${process_guid}" -ScriptBlock {
            param($stdout,$logFile)

            while (-not (Test-Path $stdout)) {
                Start-Sleep -Milliseconds 100
            }
            Write-Verbose "Monitoring STDOUT!"
            Get-Content $stdout.FullName -Wait | ForEach-Object{
                "STDOUT: $_"  | Out-File -Encoding 'utf8' -LiteralPath $logFile.FullName -Append -Force
            }
        } -ArgumentList @($stdout, $LogFile)
    
        # Monitor STDERR and send to Log
        $stderr_job = Start-Job -Name "StdErr ${process_guid}" -ScriptBlock {
            param($stderr,$logFile)

            while (-not (Test-Path $stderr)) {
                Start-Sleep -Milliseconds 100
            }
            Write-Verbose "Monitoring STDERR!"
            Get-Content $stderr.FullName -Wait | ForEach-Object{
                "STDERR: $_" | Out-File -Encoding 'utf8' -LiteralPath $logFile.FullName -Append -Force
            }
        } -ArgumentList @($stderr, $LogFile)
    }

    Write-Information "Start-Process: $(ConvertTo-Json $start_process)"
    $proc = Start-Process @start_process
    Write-Verbose "ExitCode: $($proc.ExitCode)"

    $stdout_job | Stop-Job
    $stderr_job | Stop-Job

    $return = @{
        'Process' = $proc;
        'StdOut'  = Get-Content $stdout;
        'StdErr'  = Get-Content $stderr;
    }

    $stdout | Remove-Item -Force
    $stderr | Remove-Item -Force

    try {
        Write-Information "Return (converted to json): $(ConvertTo-Json $return -Depth 1 -ErrorAction 'Stop')"
    } catch {
        Write-Information "Return: $($return | Out-String)"
    }
    return $return
}