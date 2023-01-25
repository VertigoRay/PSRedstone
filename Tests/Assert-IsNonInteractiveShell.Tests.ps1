Describe 'Assert-IsNonInteractiveShell' {
    BeforeAll {
        $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
        . ('{0}\PSRedstone\Public\Assert-IsNonInteractiveShell.ps1' -f $psProjectRoot.FullName)
    }

    It 'Assert-IsNonInteractiveShell' {
        { Assert-IsNonInteractiveShell } | Should -Not -Throw
    }

    It 'Return Boolean' {
        Assert-IsNonInteractiveShell | Should -BeOfType 'System.Boolean'
    }
}
