Describe 'Syntax: JSON' -Tag 'Syntax' {
    $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
    Write-Debug ('PSProjectRoot: {0}' -f $psProjectRoot.FullName)

    $jsonFiles = Get-ChildItem $psProjectRoot.FullName -Filter '*.json' -Recurse -File | Where-Object {
        # For some reason, this file ('json.ps1') is included with that filter.
        $_.Extension -eq '.json'
    }

    It 'Is Valid JSON: <Path>' -TestCases @(
        foreach ($file in $jsonFiles) {
            @{
                Path = $file.FullName
            }
        }
    ) {
        param($Path)
        {
            Get-Content $Path | Where-Object {
                # Remove Comments because PowerShell doesn't like them.
                -not $_.Trim().StartsWith('//')
            } | ConvertFrom-Json
        } | Should -Not -Throw
    }
}
