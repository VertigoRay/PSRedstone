param(
    $FilePath
)

if (-not (Get-Module 'thing' -ListAvailable -ErrorAction 'Ignore')) {
    Install-Module 'thing' -Scope 'CurrentUser' -WhatIf
}

$buildOutput = [IO.Path]::Combine(([IO.DirectoryInfo] $PSScriptRoot).Parent.FullName, 'dev', 'BuildOutput')
if (-not $env:PSModulePath.StartsWith($buildOutput)) {
    $env:PSModulePath = $buildOutput +";${env:PSModulePath}"
}
. $FilePath
