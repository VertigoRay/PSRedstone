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
# The PSD1 is generated from the build pipeline.
#endregion
$psd1 = Import-PowerShellDataFile ([IO.Path]::Combine($PSScriptRoot, 'PSRedstone.psd1'))

# Check if the current context is elevated (Are we running as an administrator?)
if ((New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Anytime this Module is used, the version and timestamp will be stored in the registry.
    # This will allow more intelligent purging of unused versions.
    $versionUsed = @{
        LiteralPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\VertigoRay\PSRedstone\VersionsUsed'
        Name = $psd1.ModuleVersion
        Value = (Get-Date -Format 'O')
        Force = $true
    }
    Write-Debug ('Version Used: {0}' -f ($versionUsed | ConvertTo-Json))
    if (-not (Test-Path $versionUsed.LiteralPath)) {
        New-Item -Path $versionUsed.LiteralPath -Force
    }
    Set-ItemProperty @versionUsed
}

# Load Module Members
$moduleMember = @{
    Cmdlet = $psd1.CmdletsToExport
    Function = $psd1.FunctionsToExport
    Alias = $psd1.AliasesToExport
}
if ($psd1.VariablesToExport) {
    $moduleMember.Set_Item('Variable', $psd1.VariablesToExport)
}
Export-ModuleMember @moduleMember
