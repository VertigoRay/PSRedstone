<#
.SYNOPSIS
Touch - change file timestamps.
.DESCRIPTION
Update the access and modification times of the Path to the current time.
A path argument that does not exist is created empty, unless -c or is supplied.
.PARAMETER Path
Specifies a path to a file.
.PARAMETER AccessTimeOnly
Change only the access time.
.PARAMETER NoCreate
Do not create any files.
.PARAMETER Date
Use instead of current time.
.PARAMETER WriteTimeOnly
Change only the modification time.
.PARAMETER Reference
Use this file's times instead of current time.
.PARAMETER PassThru
Return the IO.FileInfo for the *touched* file.
.EXAMPLE
Invoke-Touch 'C:\Temp\foo.txt'

Update the access and modification times of `foo.txt` to the current time.
.EXAMPLE
Get-ChildItem $env:Temp -File | Invoke-Touch

Update the access and modification times of all files in the temp directory to the current time.
Not specifying the `-File` parameter may cause directories to be passed in; this will cause a `ParameterBindingException` to be thrown.
.EXAMPLE
Get-ChildItem $env:Temp -File | Invoke-Touch -PassThru | Invoke-MoreActions

Update the access and modification times of all files in the temp directory to the current time and pass the file info through on the pipeline.
Not specifying the `-File` parameter may cause directories to be passed in; this will cause a `ParameterBindingException` to be thrown.
.NOTES
Ref:

- [touch - Linux Manual Page](https://man7.org/linux/man-pages/man1/touch.1.html)
.LINK
#>
function Invoke-Touch {
    [CmdletBinding(DefaultParameterSetName = 'Now')]
    [OutputType([IO.FileInfo])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'Now', Position = 0)]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'NowAccessTimeOnly', Position = 0)]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'NowWriteTimeOnly', Position = 0)]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'DateAccessTimeOnly', Position = 0)]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'DateWriteTimeOnly', Position = 0)]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ReferenceAccessTimeOnly', Position = 0)]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ReferenceWriteTimeOnly', Position = 0)]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo[]]
        $Path,

        [Parameter(ParameterSetName = 'NowAccessTimeOnly')]
        [Parameter(ParameterSetName = 'DateAccessTimeOnly')]
        [Parameter(ParameterSetName = 'ReferenceAccessTimeOnly')]
        [Alias('a')]
        [switch]
        $AccessTimeOnly,

        [Parameter(ParameterSetName = 'Now')]
        [Parameter(ParameterSetName = 'NowAccessTimeOnly')]
        [Parameter(ParameterSetName = 'NowWriteTimeOnly')]
        [Parameter(ParameterSetName = 'DateAccessTimeOnly')]
        [Parameter(ParameterSetName = 'DateWriteTimeOnly')]
        [Parameter(ParameterSetName = 'ReferenceAccessTimeOnly')]
        [Parameter(ParameterSetName = 'ReferenceWriteTimeOnly')]
        [Alias('c')]
        [switch]
        $NoCreate,

        [Parameter(HelpMessage = 'Use instead of current time.', ParameterSetName = 'DateAccessTimeOnly')]
        [Parameter(HelpMessage = 'Use instead of current time.', ParameterSetName = 'DateWriteTimeOnly')]
        [ValidateNotNullOrEmpty()]
        [Alias('d')]
        [datetime]
        $Date,

        [Parameter(ParameterSetName = 'NowWriteTimeOnly')]
        [Parameter(ParameterSetName = 'DateWriteTimeOnly')]
        [Parameter(ParameterSetName = 'ReferenceWriteTimeOnly')]
        [Alias('m')]
        [switch]
        $WriteTimeOnly,

        [Parameter(HelpMessage = 'Use this file''s times instead of current time.', ParameterSetName = 'ReferenceAccessTimeOnly')]
        [Parameter(HelpMessage = 'Use this file''s times instead of current time.', ParameterSetName = 'ReferenceWriteTimeOnly')]
        [Alias('r')]
        [IO.FileInfo]
        $Reference,

        [Parameter(ParameterSetName = 'Now')]
        [Parameter(ParameterSetName = 'NowAccessTimeOnly')]
        [Parameter(ParameterSetName = 'NowWriteTimeOnly')]
        [Parameter(ParameterSetName = 'DateAccessTimeOnly')]
        [Parameter(ParameterSetName = 'DateWriteTimeOnly')]
        [Parameter(ParameterSetName = 'ReferenceAccessTimeOnly')]
        [Parameter(ParameterSetName = 'ReferenceWriteTimeOnly')]
        [switch]
        $PassThru
    )

    Begin {
        if ($Date) {
            $lastAccessTime = $Date
            $lastWriteTime = $Date
        } elseif ($Reference) {
            if ($Reference.Exists) {
                $lastAccessTime = $Reference.LastAccessTime
                $lastWriteTime = $Reference.LastWriteTime
            } else {
                Write-Warning ('[Invoke-Touch] Reverting to current time, reference file does not exist: {0}' -f $Reference.FullName)
                $now = Get-Date
                $lastAccessTime = $now
                $lastWriteTime = $now
            }
        } else {
            $now = Get-Date
            $lastAccessTime = $now
            $lastWriteTime = $now
        }
    }

    Process {
        foreach ($p in $Path) {
            if (-not $p.Exists -and -not $NoCreate.IsPresent) {
                New-Item -Type 'File' -Path $p | Out-Null
            } elseif (-not $p.Exists -and $NoCreate.IsPresent) {
                Write-Verbose ('[Invoke-Touch] Path does not exist, but we cannot create it: {0}' -f $p.FullName)
            } else {
                if (-not $WriteTimeOnly.IsPresent) {
                    $p.LastAccessTime = $lastAccessTime
                }
                if (-not $AccessTimeOnly.IsPresent) {
                    $p.LastWriteTime = $lastWriteTime
                }
            }

            if ($PassThru.IsPresent) {
                $p.Refresh()
                Write-Output $p
            }
        }
    }

    End {}
}
