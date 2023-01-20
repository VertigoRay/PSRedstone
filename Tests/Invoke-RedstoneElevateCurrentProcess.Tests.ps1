Describe 'Invoke-RedstoneElevateCurrentProcess' {
    BeforeAll {
        $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
        . ('{0}\PSRedstone\Public\Invoke-RedstoneElevateCurrentProcess.ps1' -f $psProjectRoot.FullName)
        . ('{0}\PSRedstone\Public\Get-RedstoneTranslatedErrorCode.ps1' -f $psProjectRoot.FullName)
    }

    It 'Invoke-RedstoneElevateCurrentProcess' {
        { Invoke-RedstoneElevateCurrentProcess } | Should -Not -Throw
    }
}
