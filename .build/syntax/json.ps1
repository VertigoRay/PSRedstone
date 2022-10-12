[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent.Parent
Write-Debug ('[json.ps1] PSProjectRoot: {0}' -f $psProjectRoot.FullName)
$jsonFiles = Get-ChildItem $psProjectRoot.FullName -Filter '*.json' -Recurse -File | Where-Object {
    # For some reason, this file ('json.ps1') is included with that filter.
    $_.Extension -eq '.json'
}

$errors_found = $false

foreach ($file in $jsonFiles) {
    Write-Debug ('[json.ps1] JSON file: {0}' -f $file.FullName)
    try {
        $json = Get-Content $file.FullName | Where-Object {
            # Remove Comments because PowerShell doesn't like them.
            -not $_.Trim().StartsWith('//')
        } | ConvertFrom-Json
        Write-Debug ('[json.ps1] JSON: {0}' -f ($json | ConvertTo-Json))
        Write-Information "[json.ps1] JSON syntax VALID in: $($file.FullName)"
    } catch {
        Write-Warning "[json.ps1] JSON syntax NOT VALID in: $($file.FullName)"
        Write-Verbose ('{0}: {1}' -f $file.FullName, $_.Exception.Message)
        $errors_found = $true
    }
}

if ($errors_found) {
    Throw "JSON Syntax errors found!"
}