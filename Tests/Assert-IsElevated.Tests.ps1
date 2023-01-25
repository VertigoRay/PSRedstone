Describe 'Assert-IsElevated' {
    BeforeAll {
        $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
        . ('{0}\PSRedstone\Public\Assert-IsElevated.ps1' -f $psProjectRoot.FullName)
    }

    It 'Assert-IsElevated' {
        { Assert-IsElevated } | Should -Not -Throw
    }

    It 'Return Boolean' {
        Assert-IsElevated | Should -BeOfType 'System.Boolean'
    }
}
