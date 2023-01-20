Describe 'Assert-RedstoneIsMutexAvailable' {
    BeforeAll {
        $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
        . ('{0}\PSRedstone\Public\Assert-RedstoneIsMutexAvailable.ps1' -f $psProjectRoot.FullName)
    }

    It 'Assert-RedstoneIsMutexAvailable' {
        { Assert-RedstoneIsMutexAvailable -MutexName 'Global\_MSIExecute' -MutexWaitTimeInMilliseconds 1 } | Should -Not -Throw
    }

    It 'Return Boolean' {
        Assert-RedstoneIsMutexAvailable -MutexName 'Global\_MSIExecute' -MutexWaitTimeInMilliseconds 1 | Should -BeOfType 'System.Boolean'
    }
}
