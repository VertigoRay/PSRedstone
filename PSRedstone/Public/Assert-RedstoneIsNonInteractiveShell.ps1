<#
.SYNOPSIS
Is the current process running in a non-interactive shell?
.DESCRIPTION
There are two ways to determine if the current process is in a non-interactive shell:

- See if the user environment is makred as interactive.
- See if powershell was launced with the -NonInteractive
.EXAMPLE
```powershell
Assert-RedstoneIsNonInteractiveShell
```
```
True
```
.NOTES

.LINK
# Powershell test for noninteractive mode
https://stackoverflow.com/a/34098997/615422
.LINK
# Environment.UserInteractive Property
https://learn.microsoft.com/en-us/dotnet/api/system.environment.userinteractive
.LINK
# About PowerShell.exe: NonInteractive
https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_powershell_exe?view=powershell-5.1#-noninteractive
#>
function Assert-RedstoneIsNonInteractiveShell {
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
