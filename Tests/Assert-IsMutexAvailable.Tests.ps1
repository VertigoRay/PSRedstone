Describe 'Assert-IsMutexAvailable' {
    BeforeAll {
        $script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
        . ('{0}\PSRedstone\Public\Assert-IsMutexAvailable.ps1' -f $psProjectRoot.FullName)
    }

    It 'Assert-IsMutexAvailable' {
        { Assert-IsMutexAvailable -MutexName 'Global\_MSIExecute' -MutexWaitTimeInMilliseconds 1 } | Should -Not -Throw
    }

    It 'Return Boolean' {
        Assert-IsMutexAvailable -MutexName 'Global\_MSIExecute' -MutexWaitTimeInMilliseconds 1 | Should -BeOfType 'System.Boolean'
    }
}
