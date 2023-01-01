<#
.SYNOPSIS
Runs the given command in ComSpec (aka: Command Prompt).
.DESCRIPTION
This just runs a command in ComSpec by passing it to `Invoke-RedstoneRun`.

If you don't *need* ComSpec to run the command, it's normally best to just use `Invoke-RedstoneRun`.
.PARAMETER Cmd
Under normal usage, the string passed in here just gets appended to `cmd.exe /c `.
.PARAMETER KeepOpen
Applies /K instead of /C, but *why would you want to do this?*

/C      Carries out the command specified by string and then terminates
/K      Carries out the command specified by string but remains
.PARAMETER StringMod
Applies /S:  Modifies the treatment of string after /C or /K (run cmd.exe below)
.PARAMETER Quiet
Applies /Q:  Turns echo off
.PARAMETER DisableAutoRun
Applies /D:  Disable execution of AutoRun commands from registry (see below)
.PARAMETER ANSI
Applies /A:  Causes the output of internal commands to a pipe or file to be ANSI
.PARAMETER Unicode
Applies /U:  Causes the output of internal commands to a pipe or file to be Unicode
.OUTPUTS
[Hashtable] As returned from `Invoke-RedstoneRun`.
@{
    'Process' = $proc; # The result from Start-Process; as returned from `Invoke-RedstoneRun`.
    'StdOut'  = $stdout;
    'StdErr'  = $stderr;
}
.EXAMPLE
Invoke-RedstoneCmd "MKLINK /D Temp C:\Temp"
.LINK
https://git.cas.unt.edu/winstall/winstall/wikis/Invoke-RedstoneCmd
#>
function Invoke-RedstoneCmd {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=1)]
        [string]
        $Cmd,

        [Parameter(Mandatory=$false)]
        [switch]
        $KeepOpen,

        [Parameter(Mandatory=$false)]
        [switch]
        $StringMod,

        [Parameter(Mandatory=$false)]
        [switch]
        $Quiet,

        [Parameter(Mandatory=$false)]
        [switch]
        $DisableAutoRun,

        [Parameter(Mandatory=$false)]
        [switch]
        $ANSI,

        [Parameter(Mandatory=$false)]
        [switch]
        $Unicode
    )

    Write-Information "[Invoke-RedstoneCmd] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Debug "[Invoke-RedstoneCmd] Function Invocation: $($MyInvocation | Out-String)"

    [System.Collections.ArrayList] $ArgumentList = @()
    if ($KeepOpen) {
        $ArgumentList.Add('/K')
    } else {
        $ArgumentList.Add('/C')
    }
    if ($StringMod)      { $ArgumentList.Add('/S') }
    if ($Quiet)          { $ArgumentList.Add('/Q') }
    if ($DisableAutoRun) { $ArgumentList.Add('/D') }
    if ($ANSI)           { $ArgumentList.Add('/A') }
    if ($Unicode)        { $ArgumentList.Add('/U') }
    $ArgumentList.Add($Cmd)

    Write-Verbose "[Invoke-RedstoneCmd] Executing: cmd $($ArgumentList -join ' ')"

    Write-Verbose "[Invoke-RedstoneCmd] Invoke-RedstoneRun ..."
    $proc = Invoke-RedstoneRun -FilePath $env:ComSpec -ArgumentList $ArgumentList
    Write-Verbose "[Invoke-RedstoneCmd] ExitCode: $($proc.Process.ExitCode)"

    Write-Information "[Invoke-RedstoneCmd] Return: $($proc | Out-String)"
    return $proc
}
