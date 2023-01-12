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
)

if ($File.Name -like '*.Tests.*') {
    [IO.FileInfo] $runPath = $File.FullName
    $path = [IO.Path]::Combine($WorkspaceFolder.FullName, $WorkspaceFolder.Name)
    $filter = $File.Name.Replace('.Tests', '')
    try {
        [IO.FileInfo] $codecovPath = (Get-ChildItem $path -Filter $filter -File -Recurse)[0]
    } catch {
        Throw [System.IO.FileNotFoundException] ('Cannot find "{0}" in "{1}".' -f $filter, $path)
    }
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
