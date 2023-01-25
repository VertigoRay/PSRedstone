<#
.NOTES
https://learn.microsoft.com/en-us/dotnet/api/system.componentmodel.win32exception
.LINK
https://github.com/VertigoRay/PSRedstone/wiki/Functions#get-translatederrorcode
#>
function Get-TranslatedErrorCode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ComponentModel.Win32Exception]
        $ErrorCode,

        [Parameter(Mandatory = $false)]
        [switch]
        $MECM
    )

    Write-Verbose ('[Get-TranslatedErrorCode] >')
    Write-Debug ('[Get-TranslatedErrorCode] > {0}' -f ($MyInvocation | Out-String))

    # Write-Host ($ErrorCode | Select-Object '*' | Out-String) -ForegroundColor Cyan

    $srsResourcesGetErrorMessage = {
        param([ComponentModel.Win32Exception] $ErrorCode)

        $dllSrsResources = [IO.Path]::Combine(([IO.DirectoryInfo] $env:SMS_ADMIN_UI_PATH).Parent.FullName, 'SrsResources.dll')
        [void] [System.Reflection.Assembly]::LoadFrom($dllSrsResources)

        $result = @{
            ErrorCode = $ErrorCode.NativeErrorCode
            Message = [SrsResources.Localization]::GetErrorMessage($ErrorCode.NativeErrorCode, (Get-Culture).Name)
        }
        if ($result.Message.StartsWith('Unknown error (') -or $result.Message.StartsWith('Unspecified error')) {
            $result = @{
                ErrorCode = $ErrorCode.ErrorCode
                Message = [SrsResources.Localization]::GetErrorMessage($ErrorCode.ErrorCode, (Get-Culture).Name)
            }
        }

        if ($result.Message.StartsWith('Unknown error (') -or $result.Message.StartsWith('Unspecified error')) {
            # If nothing at all could be found, send back original error object.
            return $ErrorCode
        }
        # If we found something, send back what we found.
        return ([PSObject]  $result)
    }

    if ($MECM.IsPresent -and $env:SMS_ADMIN_UI_PATH) {
        $result = & $srsResourcesGetErrorMessage -ErrorCode $ErrorCode
    } elseif ($MECM.IsPresent) {
        Throw [System.Management.Automation.ItemNotFoundException] ('Environment Variable Expected: SMS_ADMIN_UI_PATH (https://learn.microsoft.com/en-us/powershell/sccm/overview?view=sccm-ps)')
    } else {
        $result = $ErrorCode
    }

    if ($result.Message.StartsWith('Unknown error (') -and $env:SMS_ADMIN_UI_PATH) {
        # Let's try looking it up as a MECM error
        $result = & $srsResourcesGetErrorMessage -ErrorCode $ErrorCode
    }

    if ($result.Message.StartsWith('Unknown error (')) {
        # Let's define some unknown errors the best we can ...
        switch ($result.ErrorCode) {
            -1073741728 {
                # https://errorco.de/win32/ntstatus-h/status_no_such_privilege/-1073741728/
                return ([PSObject] @{
                    ErrorCode = $result.ErrorCode
                    Message = 'A required privilege is not held by the client. (STATUS_PRIVILEGE_NOT_HELD 0x{0:x})' -f $result.ErrorCode
                })
            }
            default {
                return $result
            }
        }
    } else {
        return $ErrorCode
    }
}
