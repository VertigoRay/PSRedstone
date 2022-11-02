#region DEVONLY
<#
.Synopsis
This is the main scaffolding the glues all the pieces together.
#>
$ps1s = Get-ChildItem -Path "${PSScriptRoot}\*.ps1" -Recurse -ErrorAction SilentlyContinue

foreach ($import in $ps1s) {
    try {
        . $import.FullName
    } catch {
        Write-Error -Message "Failed to import function: $($import.FullName): $_"
    }
}
#endregion

$psd1 = Import-PowerShellDataFile ([IO.Path]::Combine($PSScriptRoot, 'PSBacon.psd1'))
$moduleMember = @{
    Cmdlet = $psd1.CmdletsToExport
    Function = $psd1.FunctionsToExport
    Alias = $psd1.AliasesToExport
}
if ($psd1.VariablesToExport) {
    $moduleMember.Set_Item('Variable', $psd1.VariablesToExport)
}
Export-ModuleMember @moduleMember