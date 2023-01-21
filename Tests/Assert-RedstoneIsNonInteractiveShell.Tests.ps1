Describe 'Assert-RedstoneIsNonInteractiveShell' {
    BeforeAll {
        $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
        . ('{0}\PSRedstone\Public\Assert-RedstoneIsNonInteractiveShell.ps1' -f $psProjectRoot.FullName)
    }

    It 'Assert-RedstoneIsNonInteractiveShell' {
        { Assert-RedstoneIsNonInteractiveShell } | Should -Not -Throw
    }

    It 'Return Boolean' {
        Assert-RedstoneIsNonInteractiveShell | Should -BeOfType 'System.Boolean'
    }
}
