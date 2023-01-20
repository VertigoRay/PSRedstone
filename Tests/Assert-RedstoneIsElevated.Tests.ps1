Describe 'Assert-RedstoneIsElevated' {
    BeforeAll {
        $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
        . ('{0}\PSRedstone\Public\Assert-RedstoneIsElevated.ps1' -f $psProjectRoot.FullName)
    }

    It 'Assert-RedstoneIsElevated' {
        { Assert-RedstoneIsElevated } | Should -Not -Throw
    }

    It 'Return Boolean' {
        Assert-RedstoneIsElevated | Should -BeOfType 'System.Boolean'
    }
}
