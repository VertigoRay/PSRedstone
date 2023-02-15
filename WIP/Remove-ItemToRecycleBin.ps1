<#
.SYNOPSIS
Remove a directory or file, sending to the Recycle Bin.
.DESCRIPTION
Remove a directory or file, sending to the Recycle Bin.

This function was not setup to handle the pipline.
.PARAMETER Path
Specifies a path of the items being removed.
.EXAMPLE
# Remove a File
Remove-ItemToRecycleBin 'C:\Temp\thing.txt'
.EXAMPLE
# Remove a Directory
Remove-ItemToRecycleBin 'C:\Temp\'
.EXAMPLE
# Remove a bunch of stuff
Get-ChildItem 'C:\Temp\' | %{ Remove-ItemToRecycleBin $_.FullName }
#>
function Remove-ItemToRecycleBin {
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$True, Position=0)]
        [string]
        $Path
    )
    Write-Information "> $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Debug "Function Invocation: $($MyInvocation | Out-String)"

    Add-Type -AssemblyName Microsoft.VisualBasic

    $Path = Resolve-Path $Path -ErrorAction 'Stop'
    Write-Information ("Moving '{0}' to the Recycle Bin" -f $Path.Path)

    if (Test-Path -Path $Path.Path -PathType Container) {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($Path.Path, 'OnlyErrorDialogs', 'SendToRecycleBin')
    } else {
        [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($Path.Path, 'OnlyErrorDialogs', 'SendToRecycleBin')
    }
}