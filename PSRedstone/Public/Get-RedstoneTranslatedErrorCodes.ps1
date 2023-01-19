<#
.NOTES
    https://learn.microsoft.com/en-us/dotnet/api/system.componentmodel.win32exception
#>
function Get-RedstoneTranslatedErrorCode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [int]
        $ErrorCode
    )

    if ($result = $ErrorCode -as [ComponentModel.Win32Exception]) {
        if ($result.Message.StartsWith('Unknown error (')) {
            Get-CMErrorMessage {
                [CmdletBinding()]
                    param
                        (
                        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
                            [int64]$ErrorCode
                        )
                [void][System.Reflection.Assembly]::LoadFrom('C:\Program Files (x86)\Microsoft Configuration Manager\AdminConsole\bin\SrsResources.dll')
                [SrsResources.Localization]::GetErrorMessage($ErrorCode,"en-US")
            switch ($result.ErrorCode) {
                -1073741728 {
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
            return $result
        }
    } else {
        Write-Warning ('[Get-RedstoneTranslateErrorCode] ComponentModel.Win32Exception does not recognize: {0}' -f $ErrorCode)
        return $null
    }
}
