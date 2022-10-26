<#
.SYNOPSIS
Wait, up to a timeout value, to check if current thread is able to acquire an exclusive lock on a system mutex.
.DESCRIPTION
A mutex can be used to serialize applications and prevent multiple instances from being opened at the same time.
Wait, up to a timeout (default is 1 millisecond), for the mutex to become available for an exclusive lock.
.PARAMETER MutexName
The name of the system mutex.
.PARAMETER MutexWaitTimeInMilliseconds
The number of milliseconds the current thread should wait to acquire an exclusive lock of a named mutex. Default is: $global:bacon.Settings.'Test-BaconIsMutexAvailable'.MutexWaitTimeInMilliseconds
A wait time of -1 milliseconds means to wait indefinitely. A wait time of zero does not acquire an exclusive lock but instead tests the state of the wait handle and returns immediately.
.EXAMPLE
Assert-IsMutexAvailable -MutexName 'Global\_MSIExecute' -MutexWaitTimeInMilliseconds 500
.EXAMPLE
Assert-IsMutexAvailable -MutexName 'Global\_MSIExecute' -MutexWaitTimeInMilliseconds (New-TimeSpan -Minutes 5).TotalMilliseconds
.EXAMPLE
Assert-IsMutexAvailable -MutexName 'Global\_MSIExecute' -MutexWaitTimeInMilliseconds (New-TimeSpan -Seconds 60).TotalMilliseconds
.NOTES
This is an internal script function and should typically not be called directly.
.LINK
http://msdn.microsoft.com/en-us/library/aa372909(VS.85).asp
http://psappdeploytoolkit.com
#>
function global:Assert-BaconIsMutexAvailable {
    [OutputType([bool])]
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,260)]
        [string]
        $MutexName,

        [Parameter(Mandatory=$false)]
        [ValidateRange(-1,[int32]::MaxValue)]
        [int32]
        $MutexWaitTimeInMilliseconds = 300000 #5min
    )

    Write-Information "> $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Debug "Function Invocation: $($MyInvocation | Out-String)"


    ## Initialize Variables
    [timespan] $MutexWaitTime = [timespan]::FromMilliseconds($MutexWaitTimeInMilliseconds)
    if ($MutexWaitTime.TotalMinutes -ge 1) {
        [string] $WaitLogMsg = "$($MutexWaitTime.TotalMinutes) minute(s)"
    } elseif ($MutexWaitTime.TotalSeconds -ge 1) {
        [string] $WaitLogMsg = "$($MutexWaitTime.TotalSeconds) second(s)"
    } else {
        [string] $WaitLogMsg = "$($MutexWaitTime.Milliseconds) millisecond(s)"
    }
    [boolean] $IsUnhandledException = $false
    [boolean] $IsMutexFree = $false
    [Threading.Mutex] $OpenExistingMutex = $null

    Write-Information "Check to see if mutex [$MutexName] is available. Wait up to [$WaitLogMsg] for the mutex to become available."
    try {
        ## Using this variable allows capture of exceptions from .NET methods. Private scope only changes value for current function.
        $private:previousErrorActionPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'

        ## Open the specified named mutex, if it already exists, without acquiring an exclusive lock on it. If the system mutex does not exist, this method throws an exception instead of creating the system object.
        [Threading.Mutex] $OpenExistingMutex = [Threading.Mutex]::OpenExisting($MutexName)
        ## Attempt to acquire an exclusive lock on the mutex. Use a Timespan to specify a timeout value after which no further attempt is made to acquire a lock on the mutex.
        $IsMutexFree = $OpenExistingMutex.WaitOne($MutexWaitTime, $false)
    } catch [Threading.WaitHandleCannotBeOpenedException] {
        ## The named mutex does not exist
        $IsMutexFree = $true
    } catch [ObjectDisposedException] {
        ## Mutex was disposed between opening it and attempting to wait on it
        $IsMutexFree = $true
    } catch [UnauthorizedAccessException] {
        ## The named mutex exists, but the user does not have the security access required to use it
        $IsMutexFree = $false
    } catch [Threading.AbandonedMutexException] {
        ## The wait completed because a thread exited without releasing a mutex. This exception is thrown when one thread acquires a mutex object that another thread has abandoned by exiting without releasing it.
        $IsMutexFree = $true
    } catch {
        $IsUnhandledException = $true
        ## Return $true, to signify that mutex is available, because function was unable to successfully complete a check due to an unhandled exception. Default is to err on the side of the mutex being available on a hard failure.
        Write-Error "Unable to check if mutex [$MutexName] is available due to an unhandled exception. Will default to return value of [$true]. `n$(Resolve-Error)"
        $IsMutexFree = $true
    } finally {
        if ($IsMutexFree) {
            if (-not $IsUnhandledException) {
                Write-Information "Mutex [$MutexName] is available for an exclusive lock."
            }
        } else {
            if ($MutexName -eq 'Global\_MSIExecute') {
                ## Get the command line for the MSI installation in progress
                try {
                    [string] $msiInProgressCmdLine = Get-CimInstance -Class 'Win32_Process' -Filter "name = 'msiexec.exe'" -ErrorAction 'Stop' | Where-Object { $_.CommandLine } | Select-Object -ExpandProperty 'CommandLine' | Where-Object { $_ -match '\.msi' } | ForEach-Object { $_.Trim() }
                } catch {
                    Write-Warning ('Unexpected/Unhandled Error caught: {0}' -f $_)
                }
                Write-Warning "Mutex [$MutexName] is not available for an exclusive lock because the following MSI installation is in progress [$msiInProgressCmdLine]."
            } else {
                Write-Information "Mutex [$MutexName] is not available because another thread already has an exclusive lock on it."
            }
        }

        if (($null -ne $OpenExistingMutex) -and ($IsMutexFree)) {
            ## Release exclusive lock on the mutex
            $null = $OpenExistingMutex.ReleaseMutex()
            $OpenExistingMutex.Close()
        }
        if ($private:previousErrorActionPreference) { $ErrorActionPreference = $private:previousErrorActionPreference }
    }

    return $IsMutexFree
}
