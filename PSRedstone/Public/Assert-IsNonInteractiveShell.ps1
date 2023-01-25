<#
.SYNOPSIS
Is the current process running in a non-interactive shell?
.DESCRIPTION
There are two ways to determine if the current process is in a non-interactive shell:

- See if the user environment is marked as interactive.
- See if PowerShell was launched with the -NonInteractive
.EXAMPLE
Assert-IsNonInteractiveShell
If you're typing this into PowerShell, you should see `$false`.
.NOTES
- [Powershell test for noninteractive mode](https://stackoverflow.com/a/34098997/615422)
- [Environment.UserInteractive Property](https://learn.microsoft.com/en-us/dotnet/api/system.environment.userinteractive)
- [About PowerShell.exe: NonInteractive](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_powershell_exe?view=powershell-5.1#-noninteractive)
.LINK
https://github.com/VertigoRay/PSRedstone/wiki/Functions#assert-isnoninteractiveshell
#>
function Assert-IsNonInteractiveShell {
    [OutputType([boolean])]
    [CmdletBinding()]
    param()

    # Test each Arg for match of abbreviated '-NonInteractive' command.
    $NonInteractive = [Environment]::GetCommandLineArgs() | Where-Object{ $_ -like '-NonI*' }

    if ([Environment]::UserInteractive -and -not $NonInteractive) {
        # We are in an interactive shell.
        return $false
    }

    return $true
}
