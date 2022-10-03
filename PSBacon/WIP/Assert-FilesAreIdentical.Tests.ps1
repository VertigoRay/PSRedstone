
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"


Describe $sut {
    $File1 = "${env:Temp}\File1-$(New-Guid).txt"
    $File2 = "${env:Temp}\File2-$(New-Guid).txt"
    $File3 = "${env:Temp}\File3-$(New-Guid).txt"
    $File4 = "${env:Temp}\File4-$(New-Guid).txt"

    $File1_Content = New-Guid
    $File2_Content = $File1_Content
    $File3_Content = New-Guid
    $File4_Content = "$(New-Guid)$([System.Environment]::NewLine)$(New-Guid)"

    $File1_Content | Out-File $File1
    $File2_Content | Out-File $File2
    $File3_Content | Out-File $File3
    $File4_Content | Out-File $File4

    It 'Exact Same File' {
        Assert-FilesAreIdentical $File1 $File1 | Should Be $true
    }

    It 'Files Are Identical' {
        Assert-FilesAreIdentical $File1 $File2 | Should Be $true
    }

    It 'Same Size, Diff SHA' {
        Assert-FilesAreIdentical $File1 $File3 | Should Be $false
    }

    It 'Diff Size' {
        Assert-FilesAreIdentical $File1 $File4 | Should Be $false
    }

    It 'File1 is not a file' {
        { Assert-FilesAreIdentical "This_File_Does_Not_Exist_$(New-Guid)" $File2 } | Should Throw
    }

    It 'File2 is not a file' {
        { Assert-FilesAreIdentical $File1 "This_File_Does_Not_Exist_$(New-Guid)" } | Should Throw
    }
}
