$script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
Write-Host ('$script:psProjectRoot: {0}' -f ($script:psProjectRoot.FullName)) -ForegroundColor Cyan

[IO.DirectoryInfo] $modulePath = [IO.Path]::Combine($script:psProjectRoot.FullName, 'PSBacon')
Write-Host ('$modulePath: {0}' -f ($modulePath.FullName)) -ForegroundColor Cyan

$ps1s = Get-ChildItem $modulePath -Filter '*.ps1' -Recurse -File | Where-Object {
    # I don't trust the filter; see the SyntaxJson.Tests.ps1
    $_.Extension -eq '.ps1'
}

$skipRules = @(
    'PSUseUsingScopeModifierInNewRunspaces'
)

Describe 'PSScriptAnalyzer analysis' -Tag 'Syntax','PSScriptAnalyzer' {
    It "<IncludeRule>: <RelativePath>" -TestCases @(
        foreach ($p in $ps1s) {
            foreach ($r in (Get-ScriptAnalyzerRule | Where-Object { $_.RuleName -notin $skipRules })) {
                @{
                    IncludeRule = $r.RuleName
                    RelativePath = $p.FullName.Replace($script:psProjectRoot.FullName, '')
                    Path = $p.FullName
                }
            }
        }
    ) {
        param($IncludeRule, $RelativePath, $Path)
        Invoke-ScriptAnalyzer -Path $Path -IncludeRule $IncludeRule | Should -BeNullOrEmpty
    }
}
