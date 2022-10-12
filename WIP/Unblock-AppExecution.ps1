<#
.SYNOPSIS
Unblocks the execution of all Application blocks created by the `Block-AppExecution` function.
.DESCRIPTION
Unblocks the execution of all Application blocks created by the `Block-AppExecution` function.
.PARAMETER IFEOKey
Default: `$global:Winstall.Settings.Functions.UnblockAppExecution.IFEOKey`

Registry Key for 'Image File Execution Options'.
.EXAMPLE
Unblock-AppExecution
.NOTES
This is a job within a job because:

- If the popup message doesn't occur within a sub-job, the pop-up message will halt the searching for moreblocked apps until the popup goes away; after the `PopSecondsToWait` param times out.
.LINK
#>
function Global:Unblock-AppExecution {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string]
        $IFEOKey = $global:Winstall.Settings.Functions.UnblockAppExecution.IFEOKey
    )
    
    Write-Information "> $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Debug "Function Invocation: $($MyInvocation | Out-String)"

    foreach ($child in (Get-ChildItem $IFEOKey)) {
        $key = $child.Name -replace "^$($child.PSDrive.Root)", "$($child.PSDrive.Name):"

        try {
            $properties = Get-ItemProperty -Path $key -ErrorAction 'Stop'
        } catch [System.Management.Automation.ItemNotFoundException] {
            Write-Error "[ItemNotFoundException] Unexpected Error; should never see this: $_"
            continue
        }

        if ($properties.WinstallMadeMe) {
            Write-Information "Deleting Key: ${key}"
            Remove-Item $key -Recurse -Force -ErrorAction 'Stop' | Out-Null
        } elseif ($properties.WinstallMadeDebugger) {
            Write-Information "Deleting Key Value: ${key} : Debugger"
            Remove-ItemProperty -Path $key -Name 'Debugger' -ErrorAction 'Stop' | Out-Null

            Write-Information "Deleting Key Value: ${key} : WinstallMadeDebugger"
            Remove-ItemProperty -Path $key -Name 'WinstallMadeDebugger' -ErrorAction 'Stop' | Out-Null
        } elseif ($properties.Debugger_WinstallRenamedMe) {
            Write-Information "Deleting Key Value: ${key} : Debugger"
            Remove-ItemProperty -Path $key -Name 'Debugger' -ErrorAction 'Stop' | Out-Null

            Write-Information "Renaming Key: ${key} : Debugger_WinstallRenamedMe > Debugger"
            New-ItemProperty -Path $key -Name 'Debugger' -Value $properties.Debugger_WinstallRenamedMe -ErrorAction 'Stop' | Out-Null
            Remove-ItemProperty -Path $key -Name 'Debugger_WinstallRenamedMe' -ErrorAction 'Stop' | Out-Null
        }
    }
}