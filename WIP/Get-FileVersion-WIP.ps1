<#
.SYNOPSIS
Gets the version of the specified file
.DESCRIPTION
Gets the version of the specified file
.PARAMETER File
Path of the file.
.EXAMPLE
Get-FileVersion -File "$envProgramFilesX86\Adobe\Reader 11.0\Reader\AcroRd32.exe"
.NOTES
.LINK
#>
function Global:Get-FileVersionInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullorEmpty()]
        [string]
        $File
    )

    Write-Information "> $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Verbose "Function Invocation: $($MyInvocation | Out-String)"

	$File = (Resolve-Path $File -ErrorAction 'Stop').Path
    
    try {
    	$return = (Get-Command -Name $File -ErrorAction 'Stop').FileVersionInfo
    } catch {
    	$return = (Get-ItemProperty $EXE -ErrorAction 'Stop').VersionInfo
    }

    Write-Information "Return: $($return | ConvertTo-Json -Compress)"
    return $return 
}