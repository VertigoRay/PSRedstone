<#
.SYNOPSIS
Rename the current Winstall Log File.
.DESCRIPTION
This function renames the current Winstall Log File by applying the supplied `Formatter` to `$Winstall.Log.PathF`, renaming the current log file, and applying the changes to `$Winstall.Log`.
.PARAMETER Formatter
This is desired formatter for the log file change.
.EXAMPLE
PS > $Winstall.Log

Name                           Value
----                           -----
PathF                          C:\WINDOWS\Logs\Winstall\Adobe-CreativeCloud 2017 install{0}.log
FileName                       Adobe-CreativeCloud 2017 install.log
Name                           Adobe-CreativeCloud 2017 install
Path                           C:\WINDOWS\Logs\Winstall\Adobe-CreativeCloud 2017 install.log
Folder                         C:\WINDOWS\Logs\Winstall

PS > Rename-WinstallLogFile ' Photoshop'
PS > $Winstall.Log

Name                           Value
----                           -----
PathF                          C:\WINDOWS\Logs\Winstall\Adobe-CreativeCloud 2017 install Photoshop{0}.log
FileName                       Adobe-CreativeCloud 2017 install Photoshop.log
Name                           Adobe-CreativeCloud 2017 install Photoshop
Path                           C:\WINDOWS\Logs\Winstall\Adobe-CreativeCloud 2017 install Photoshop.log
Folder                         C:\WINDOWS\Logs\Winstall

#>
function Rename-WinstallLogFile {
    Param(
        [string]
        $Formatter
    )

    $new_log = $global:Winstall.Log.Clone()
    Write-Information $('[Rename-WinstallLogFile] Winstall.Log: {0}' -f ($new_log | ConvertTo-Json))

    $new_log.Name = '{0}{1}' -f $global:Winstall.Log.Name, $Formatter
    $new_log.FileName = '{0}.log' -f $new_log.Name
    $new_log.Path = Join-Path $new_log.Folder $new_log.FileName
    $new_log.PathF = Join-Path $new_log.Folder ('{0}{1}.log' -f $new_log.Name, '{0}')

    Write-Information $('[Rename-WinstallLogFile] Winstall.Log: {0}' -f ($new_log | ConvertTo-Json))

    if (Test-Path $new_log.Path) {
        $moveItem = @{
            LiteralPath = $new_log.Path
            Destination = $([System.IO.Path]::ChangeExtension($new_log.Path, 'lo_'))
            Force = $true
            PassThru = $true
        }
        Write-Information $('[Rename-WinstallLogFile] Move-Item: {0}' -f ($moveItem | ConvertTo-Json))

        $moved = Move-Item @moveItem
        Write-Information $('[Rename-WinstallLogFile] Backed up log: {0}' -f ($moved | Out-String))
    }

    $renameItem = @{
        LiteralPath = $new_log.Path
        Destination = $([System.IO.Path]::ChangeExtension($new_log.Path, 'lo_'))
        Force = $true
        PassThru = $true
    }
    Write-Information $('[Rename-WinstallLogFile] Rename-Item: {0}' -f ($renameItem | ConvertTo-Json))

    $renamed = Rename-Item -Path $global:Winstall.Log.Path -NewName $new_log.Path -Force -PassThru
    Write-Information $('[Rename-WinstallLogFile] Renamed log: {0}' -f ($renamed | Out-String))

    $PSDefaultParameterValues.Set_Item('Write-Log:LogFileName', $new_log.FileName)
    $global:Winstall.Log = $new_log.Clone()
    Write-Information $('[Rename-WinstallLogFile] Winstall.Log: {0}' -f ($new_log | ConvertTo-Json))

    Remove-Variable 'new_log'
}