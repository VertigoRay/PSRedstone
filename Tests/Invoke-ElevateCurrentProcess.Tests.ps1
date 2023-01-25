Describe 'Invoke-ElevateCurrentProcess' {
    BeforeAll {
        $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
        . ('{0}\PSRedstone\Public\Invoke-ElevateCurrentProcess.ps1' -f $psProjectRoot.FullName)
        . ('{0}\PSRedstone\Public\Get-TranslatedErrorCode.ps1' -f $psProjectRoot.FullName)
    }

    It 'Invoke-ElevateCurrentProcess' {
        { Invoke-ElevateCurrentProcess } | Should -Not -Throw
    }
}
