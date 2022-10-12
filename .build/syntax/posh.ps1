[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent.Parent
Write-Debug ('[posh.ps1] PSProjectRoot: {0}' -f $psProjectRoot.FullName)
$poshFiles = Get-ChildItem $psProjectRoot.FullName -Filter '*.ps1' -Recurse -File | Where-Object {
    $_.Extension -eq '.ps1'
}

$errors_found = $false

<#
.SYNOPSIS
Return an Array of the PSSyntax Errors.
.DESCRIPTION
Took from Winstall: https://git.cas.unt.edu/winstall/winstall/blob/master/functions/Assert-PSSyntaxErrors.ps1
.EXAMPLE
# Using CodeBlock; Valid
> $PSSyntaxErrors = Assert-PSSyntaxErrors -CodeBlock (Get-Content .\test.ps1 | Out-String )
> $PSSyntaxErrors.Length
0
> $PSSyntaxErrors
#>
function Global:Assert-PSSyntaxErrors {
    param(
        [Parameter(
            Mandatory=$true,
            HelpMessage = "Powershell code to syntax check.",
            ParameterSetName='Code'
        )]
        [string] $CodeBlock,

        [Parameter(
            Mandatory=$true,
            Position=0,
            HelpMessage = "The path to the Powershell file to syntax check.",
            ParameterSetName='File'
        )]
        [string] $Path
    )
    if ($CodeBlock) {
        $ps_code = $CodeBlock
    } elseif ($Path) {
        $ps_code = Get-Content (Resolve-Path $Path -ErrorAction 'Stop') | Out-String
    } else {
        Throw [System.Management.Automation.ParameterBindingException] "Unexpected Error: No valid parameter found."
    }
    $syntax_errors = $null
    [System.Management.Automation.PSParser]::Tokenize($ps_code, [ref]$syntax_errors) | Out-Null

    [System.Collections.ArrayList] $error_list = @()
    foreach ($err in $syntax_errors) {
        $error_list.Add(":$($err.Token.StartLine).$($err.Token.StartColumn)-:$($err.Token.EndLine).$($err.Token.EndColumn) $($err.Message)") | Out-Null
    }
    return [array]$error_list
}

foreach ($file in $poshFiles) {
    Write-Debug ('[posh.ps1] JSON file: {0}' -f $file.FullName)
    $PSSyntaxErrors = Assert-PSSyntaxErrors $file.FullName

    if ($PSSyntaxErrors.Length -eq 0) {
        Write-Information "[posh.ps1] PowerShell syntax VALID in: $($posh_file.FullName)"
    } else {
        Write-Error "[posh.ps1] PowerShell syntax NOT VALID in: $($posh_file.Name); $($PSSyntaxErrors.Length) error$(if ($PSSyntaxErrors.Length -gt 1) { 's'}):`n$($PSSyntaxErrors | Out-String)" -ErrorAction 'continue'
        $errors_found = $true
    }
}

if ($errors_found) {
    Throw "PowerShell Syntax errors found!"
}