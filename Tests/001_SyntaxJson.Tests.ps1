Describe 'Syntax: JSON' {
    $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
    Write-Debug ('PSProjectRoot: {0}' -f $psProjectRoot.FullName)
    
    $jsonFiles = Get-ChildItem $psProjectRoot.FullName -Filter '*.json' -Recurse -File | Where-Object {
        # For some reason, this file ('json.ps1') is included with that filter.
        $_.Extension -eq '.json'
    }

    foreach ($file in $jsonFiles) {
        Context ('JSON file: {0}' -f $file.FullName) {
            It 'Is Valid JSON' {
                {
                    Get-Content $file.FullName | Where-Object {
                        # Remove Comments because PowerShell doesn't like them.
                        -not $_.Trim().StartsWith('//')
                    } | ConvertFrom-Json
                } | Should Not Throw
            }
        }
    }
}