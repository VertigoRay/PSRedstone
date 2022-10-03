<#
.SYNOPSIS
Confirms if the two supplied files are identical.
.DESCRIPTION
Confirms if the two supplied files are identical by using the following, ordered methodology:

1. Check if the files are the same size.
3. Check if the files have the same SHA512 hash.

If any of the above checks fail, this function returns $false.
If all of the above checks pass, this function returns $true.
.PARAMETER File1
First file to compare.
.PARAMETER File2
File to compare to first file.
.OUTPUTS
[System.Boolean]
.EXAMPLE
> $src = 'Winstall:\config\local-settings.js'
> $dst = 'C:\Program Files (x86)\Mozilla Firefox\browser\defaults\preferences\local-settings.js'
> $result = Assert-FilesAreIdentical $src $dst
> $result
True
#>
function Assert-FilesAreIdentical {
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="First file to compare.")]
        [ValidateScript({Resolve-Path $_ -ErrorAction 'Ignore'})]
        [string]
        $File1
        ,
        [Parameter(Mandatory=$true, Position=1, HelpMessage="File to compare to first file.")]
        [ValidateScript({Resolve-Path $_ -ErrorAction 'Ignore'})]
        [string]
        $File2
    )

    Write-Information "> $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Debug "Function Invocation: $($MyInvocation | Out-String)"



    $File1_FileSize = (Get-ItemProperty $File1).Length
    Write-Verbose "File1 Size: ${File1_FileSize}"
    $File2_FileSize = (Get-ItemProperty $File2).Length
    Write-Verbose "File2 Size: ${File2_FileSize}"

    if ($File1_FileSize -ne $File2_FileSize) {
        Write-Information "File Sizes do not match:`n`t1:{${File1_FileSize}}`n`t2:{${File2_FileSize}}"
        return $false
    }

    $File1_SHA512 = (Get-FileHash -Algorithm 'SHA512' $File1).Hash
    Write-Verbose "File1 SHA512: ${File1_SHA512}"
    $File2_SHA512 = (Get-FileHash -Algorithm 'SHA512' $File2).Hash
    Write-Verbose "File2 SHA512: ${File2_SHA512}"

    if ($File1_SHA512 -ne $File2_SHA512) {
        Write-Information "File SHA512s do not match:`n`t1:{${File1_SHA512}}`n`t2:{${File2_SHA512}}"
        return $false
    }

    Write-Information "Files are the same size and have the same SHA512."
    return $true
}