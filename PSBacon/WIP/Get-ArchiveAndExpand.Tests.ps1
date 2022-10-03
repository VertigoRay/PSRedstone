$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

$TestDownloadZip_URL = 'http://its.cas.unt.edu/~casits/TestDownload_DONOTDELETE.zip'
$PSDefaultParameterValues.Set_Item('Get-ArchiveAndExpand:ZipFile', (Join-Path $env:Temp (Split-Path $TestDownloadZip_URL -Leaf)))

Describe $sut {
    Remove-Variable -Scope 'global' -Name 'result' -ErrorAction 'Ignore'

    Context 'Simple URI' {
        $guid = (New-Guid).Guid
        Write-Verbose "GUID: $guid"
        New-Item $guid -Type 'Directory'
        Push-Location $guid

        It 'Get and Expand' {
            { $global:result = Get-ArchiveAndExpand $TestDownloadZip_URL } | Should Not Throw
        }

        It 'DestinationPath' {
            $global:result.DestinationPath | Should Be "$(Get-Location)\TestDownload_DONOTDELETE"
        }

        It 'DestinationPath Exists' {
            Test-Path $global:result.DestinationPath | Should Be $true
        }

        It 'Zip File' {
            $global:result.ZipFile | Should Be "${env:Temp}\TestDownload_DONOTDELETE.zip"
        }

        It 'Zip File not deleted' {
            $global:result.ZipDeleted | Should Be $false
        }

        It 'ZipFile Exists' {
            Test-Path $global:result.ZipFile | Should Be $true
        }

        Pop-Location
        Remove-Item $guid -Recurse -Force
        Remove-Item $global:result.ZipFile -Force
        Remove-Variable -Scope 'global' -Name 'result'
    }

    Write-Verbose 'Waiting to prevent flooding the server ...'
    Start-Sleep -Seconds 1

    Context 'Complex URI' {
        $global:result = $null
        $guid = (New-Guid).Guid
        New-Item $guid -Type 'Directory'
        Push-Location $guid

        It 'Get and Expand' {
            { $global:result = Get-ArchiveAndExpand "${TestDownloadZip_URL}?foo=bar" } | Should Not Throw
        }

        It 'DestinationPath' {
            $global:result.DestinationPath | Should Be "$(Get-Location)\TestDownload_DONOTDELETE"
        }

        It 'DestinationPath Exists' {
            Test-Path $global:result.DestinationPath | Should Be $true
        }

        It 'Zip File' {
            $global:result.ZipFile | Should Be "${env:Temp}\TestDownload_DONOTDELETE.zip"
        }

        It 'Zip File not deleted' {
            $global:result.ZipDeleted | Should Be $false
        }

        It 'ZipFile Exists' {
            Test-Path $global:result.ZipFile | Should Be $true
        }

        Pop-Location
        Remove-Item $guid -Recurse -Force
        Remove-Item $global:result.ZipFile -Force
        Remove-Variable -Scope 'global' -Name 'result'
    }

    Write-Verbose 'Waiting to prevent flooding the server ...'
    Start-Sleep -Seconds 1

    Context 'Simple URI; DeleteZip' {
        $global:result = $null
        $guid = (New-Guid).Guid
        New-Item $guid -Type 'Directory'
        Push-Location $guid

        It 'Get and Expand' {
            { $global:result = Get-ArchiveAndExpand $TestDownloadZip_URL -DeleteZip } | Should Not Throw
        }

        It 'DestinationPath' {
            $global:result.DestinationPath | Should Be "$(Get-Location)\TestDownload_DONOTDELETE"
        }

        It 'DestinationPath Exists' {
            Test-Path $global:result.DestinationPath | Should Be $true
        }

        It 'Zip File' {
            $global:result.ZipFile | Should Be "${env:Temp}\TestDownload_DONOTDELETE.zip"
        }

        It 'Zip File deleted' {
            $global:result.ZipDeleted | Should Be $true
        }

        It 'ZipFile not sxists' {
            Test-Path $global:result.ZipFile | Should Be $false
        }

        Pop-Location
        Remove-Item $guid -Recurse -Force
        Remove-Variable -Scope 'global' -Name 'result'
    }
}