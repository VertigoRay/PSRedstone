<#
.SYNOPSIS
Confirms if the local cache is updated and validated.
.DESCRIPTION
Confirms if the local cache file is updated and validated by using the following, ordered methodology:

1. Check if the local cache file exists with the correct name.
2. Check if the local cache file is the expected size (bytes).
3. Check if the local cache file matches the expected SHA512 hash.

If any of the above checks fail, this function returns $false.
If all of the above checks pass, this function returns $true.
.PARAMETER Name
Default: `$global:Winstall.Cache.Name`

The cache name, as returned from the initial call to Winstall WWW.
.PARAMETER Folder
Default: `$global:Winstall.Cache.Folder`

The cache name, as returned from the initial call to Winstall WWW.
.PARAMETER SizeBytes
Default: `$global:Winstall.Cache.SizeBytes`

The cache name, as returned from the initial call to Winstall WWW.
.PARAMETER SHA512
Default: `$global:Winstall.Cache.SHA512`

The cache name, as returned from the initial call to Winstall WWW.
.OUTPUTS
[System.Boolean]
.EXAMPLE
> $result = Assert-WinstallCacheIsValid
> $result
True
#>
function Global:Assert-WinstallCacheIsValid {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, HelpMessage="Private Parameter; used for debug overrides.")]
        [string]
        $Name = $global:Winstall.Cache.Name
        ,
        [Parameter(Mandatory=$false, HelpMessage="Private Parameter; used for debug overrides.")]
        [string]
        $Folder = $global:Winstall.Cache.Folder
        ,
        [Parameter(Mandatory=$false, HelpMessage="Private Parameter; used for debug overrides.")]
        [string]
        $SizeBytes = $global:Winstall.Cache.SizeBytes
        ,
        [Parameter(Mandatory=$false, HelpMessage="Private Parameter; used for debug overrides.")]
        [string]
        $SHA512 = $global:Winstall.Cache.SHA512
    )

    Write-Information "> $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Debug "Function Invocation: $($MyInvocation | Out-String)"


    $local_zip = "{0}\{1}.zip" -f $Folder, $Name
    Write-Information "Local Zip File: ${local_zip}"
    if (-not (Test-Path $local_zip)) {
        Write-Information "Local Zip File: doesn't exist."
        Write-Information "Return: $false"
            return $false
    }
    Write-Information "Local Zip File: exists."

    $local_zip_length = (Get-ItemProperty $local_zip).Length
    Write-Information "Local Zip File Size: ${local_zip_length}"
    if ($local_zip_length -eq $SizeBytes) {
        Write-Information "Local Zip File: file size is correct."

        $local_zip_hash = (Get-FileHash -Algorithm 'SHA512' $local_zip).Hash
        Write-Information "Local Zip SHA512: ${local_zip_hash}"
        $return = $local_zip_hash -ieq $SHA512
    } else {
        Write-Information "Local Zip File: wrong file size."
        $return = $false
    }

    Write-Information "Return: $return"
    return $return
}