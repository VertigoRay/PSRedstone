function Invoke-BaconRun {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [IO.FileInfo]
        $FilePath,

        [Parameter()]
        [string[]]
        $ArgumentList,

        [Parameter()]
        [hashtable]
        $SecureLog = @{}
    )

    Write-Debug ('[Invoke-BaconRun] MyInvocation: {0}' -f ($MyInvocation | Out-String))

    $run = @{
        FilePath = $FilePath.FullName
        ArgumentList = $ArgumentList
        Wait = $true
        PassThru = $true
        WindowStyle = 'Hidden'
        RedirectStandardError = New-TemporaryFile
        RedirectStandardOutput = New-TemporaryFile
    }
    
    Write-Verbose ('[Invoke-BaconRun] Starting: {0} {1}' -f $FilePath.BaseName, (($run.ArgumentList | Get-SecureLog $SecureLog) -join ' '))
    $result = Start-Process @run
    
    $stdOut = Get-Content $run.RedirectStandardOutput.FullName
    Remove-Item $run.RedirectStandardOutput.FullName -Force
    if ($stdOut) {
        Write-Host ($stdOut | Where-Object { -not [string]::IsNullOrEmpty($_) } | Get-SecureLog $SecureLog | Out-String)
    }

    $stdErr = Get-Content $run.RedirectStandardError.FullName
    Remove-Item $run.RedirectStandardError.FullName -Force
    if ($stdErr) {
        Write-Error ($stdErr | Where-Object { -not [string]::IsNullOrEmpty($_) } | Get-SecureLog $SecureLog | Out-String)
    }
    
    Write-Verbose ('[Invoke-BaconRun] ExitCode: {0}' -f $result.ExitCode)
}