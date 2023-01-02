[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [IO.FileInfo]
    $File,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [IO.DirectoryInfo]
    $WorkspaceFolder

    # [Parameter()]
    # [switch]
    # $PressAnyKeyToContinue
)

# $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent

# [version] $requiredPesterVersion = '5.3.3'
# if ((Get-Module 'Pester') -and ((Get-Module 'Pester').Version -ne $requiredPesterVersion)) {
#     foreach ($pester in (Get-Module 'Pester')) {
#         if (([IO.DirectoryInfo] $pester.ModuleBase).Parent.Exists) {
#             # https://pester.dev/docs/introduction/installation#removing-the-built-in-version-of-pester
#             $oldPesterModule = ([IO.DirectoryInfo] $pester.ModuleBase).Parent.FullName
#             & takeown /F "${oldPesterModule}" /A /R | Out-Null
#             & icacls "${oldPesterModule}" /reset | Out-Null
#             & icacls "${oldPesterModule}" /grant "*S-1-5-32-544:F" /inheritance:d /T | Out-Null
#             Remove-Item -Path $oldPesterModule -Recurse -Force -Confirm:$false
#         }
#     }
#     Remove-Module 'Pester' -Force

#     Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
#     Install-Module 'Pester' -RequiredVersion $requiredPesterVersion -SkipPublisherCheck -Force
# }
# Import-Module 'Pester' -Passthru

# Push-Location $psProjectRoot.FullName
# Push-Location 'Tests'

# $invokePester = @{
#     # OutputFile = (Join-Path (Join-Path $psProjectRoot.FullName 'dev') 'pesterResults.xml')
#     # OutputFormat = 'NUnitXML'
#     Output = 'Diagnostic'
# }

# if ($File) {
#     Write-Host ('Looking for test for: {0}' -f ($File | ConvertTo-Json)) -ForegroundColor 'Cyan'
#     Get-ChildItem -Path "*${File}*" | ForEach-Object {
#         $invokePester.Set_Item('Path', $_)

#         Write-Host ('Invoke Pester Test: {0}' -f ($invokePester | ConvertTo-Json)) -ForegroundColor 'Cyan'
#         Invoke-Pester @invokePester
#     }
# } else {
#     Write-Host ('Invoke Pester Tests: {0}' -f ($invokePester | ConvertTo-Json)) -ForegroundColor 'Cyan'
#     Invoke-Pester @invokePester
# }


# if ($PressAnyKeyToContinue.IsPresent) {
#     Write-Host -NoNewLine 'Press any key to continue...'
#     $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
# }

if ($File.Name -like '*.Tests.*') {
    [IO.FileInfo] $runPath = $File.FullName
    [IO.FileInfo] $codecovPath = (Get-ChildItem ([IO.Path]::Combine($WorkspaceFolder.FullName, $WorkspaceFolder.Name)) -Filter $File.Name.Replace('.Tests', '') -File -Recurse)[0]
} else {
    [IO.FileInfo] $runPath = [IO.Path]::Combine($WorkspaceFolder.FullName, 'Tests', $File.Name.Replace('.ps1', '.Tests.ps1'))
    [IO.FileInfo] $codecovPath = $File.FullName
}

$invokePester = @{
    Configuration = @{
        Run = @{
            Path = $runPath.FullName
            PassThru = $true
            Exit = if ($env:CI) { $true } else { $false }
        }
        TestResult = @{
            Enabled = $true
            OutputPath = [IO.Path]::Combine($script:psScriptRootParent.FullName, 'dev', 'testResults.xml')
        }
        CodeCoverage = @{
            Enabled = $true
            Path = $codecovPath.FullName
            OutputPath = [IO.Path]::Combine($script:psScriptRootParent.FullName, 'dev', 'coverage.xml')
        }
        Output = @{
            Verbosity = 'Detailed'
        }
    }
}
Write-Host ('[InvokePester] Invoke-Pester: {0}' -f ($invokePester | ConvertTo-Json)) -ForegroundColor 'DarkMagenta'
Invoke-Pester @invokePester
