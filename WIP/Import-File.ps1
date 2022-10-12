<#
.SYNOPSIS
Import a file.
.DESCRIPTION
Just imports (`.`) the file. If the execution policy prevents this, read the file and try invoking the contents as an expression.

Note: The invocation will cause a STOP error on any error in the file.
.PARAMETER FilePaths
The FilePaths to the files you want to import. This can be one or more files.
.EXAMPLE
Import-File 'thing.ps1'
.EXAMPLE
Import-File (Get-ChildItem "${PSScriptRoot}\Functions" -Filter '*.ps1' -Exclude @('*.Tests.ps1', '.git*') -Recurse -File).FullName
#>
function global:Import-File {
    [CmdletBinding()]
	param(
        [Parameter(Mandatory=$true)]
        [string[]]
        $FilePaths
    )

    Write-Information "> $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Verbose "Function Invocation: $($MyInvocation | Out-String)"


    $FilePaths = Resolve-Path $FilePaths -ErrorAction 'Stop'
    Write-Verbose "FilePaths: $($FilePaths | Out-String)"

    if ($global:Winstall.Temp) {
        Write-Verbose "Using Winstall.Temp: $($global:Winstall.Temp)"
        $private:temp = $global:Winstall.Temp
    } elseif ($env:WinstallTemp) {
        Write-Verbose "Using env:WinstallTemp: ${env:WinstallTemp}"
        $private:temp = $env:WinstallTemp
    } else {
        Write-Warning 'Winstall Temp is not initialized ... this is odd ...'
        Write-Verbose "Using env:Temp: ${env:Temp}"
        $private:temp = $env:Temp
    }

    $guid = New-Guid
    $Functions_Path = "${private:temp}\Import-File-${guid}.ps1"

    foreach ($Path in $FilePaths) {
        Write-Verbose "Adding ``$(Split-Path $Path -Leaf)`` to: $Functions_Path"
        "$([System.Environment]::NewLine)#region ${Path}$([System.Environment]::NewLine)" | Out-File $Functions_Path -Append

        $source = Get-Content $Path
        $regex_function_name = '^function\s+((?!global[:]|local[:]|script[:]|private[:])[\w-]+)' # https://regex101.com/r/wT1vE2/2
        if ($source -match $regex_function_name) {
            Write-Verbose "Making Top Level Functions in this file Global functions..."
            foreach ($line in $source) {
                if ($line -match $regex_function_name) {
                    $function_name = $Matches[1]
                    break
                }
            }
            $source -replace $regex_function_name, 'function Global:$1' | Out-File $Functions_Path -Append
        } else {
            $source | Out-File $Functions_Path -Append
        }

        "$([System.Environment]::NewLine)#endregion ${Path}$([System.Environment]::NewLine)" | Out-File $Functions_Path -Append
    }

    $Functions_Path = Resolve-Path $Functions_Path
    Write-Verbose "Functions_Path: $($Functions_Path | Out-String)"
    Unblock-File $Functions_Path

    try {
        . $Functions_Path
    } catch [System.Management.Automation.PSSecurityException] {
        Write-Warning "[PSSecurityException] $_ $([System.Environment]::NewLine)$([System.Environment]::NewLine)Bypassing this Error! This will make your logs less useful, but it *shouldn't* have any other unexpected results."
        Invoke-Expression (Get-Content $Functions_Path | Out-String)
    } catch {
        Write-Error "[$($_.Exception.GetType().FullName)] ${_}"
    }
}