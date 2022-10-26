Describe 'Syntax: PowerShell' -Tag 'Syntax' {
    $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
    Write-Debug ('[posh.ps1] PSProjectRoot: {0}' -f $psProjectRoot.FullName)
    $poshFiles = Get-ChildItem $psProjectRoot.FullName -Filter '*.ps1' -Recurse -File | Where-Object {
        # I don't trust the filter; see the SyntaxJson.Tests.ps1
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
        [System.Management.Automation.PSParser]::Tokenize($ps_code, [ref] $syntax_errors) | Out-Null

        [System.Collections.ArrayList] $error_list = @()
        foreach ($err in $syntax_errors) {
            $error_list.Add(":$($err.Token.StartLine).$($err.Token.StartColumn)-:$($err.Token.EndLine).$($err.Token.EndColumn) $($err.Message)") | Out-Null
        }
        return ([array] $error_list)
    }

    $psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
    Write-Debug ('PSProjectRoot: {0}' -f $psProjectRoot.FullName)

    It 'Is Valid PowerShell: <Path>' -TestCases @(
        foreach ($file in $poshFiles) {
            @{
                Path = $file.FullName
            }
        }
    ) {
        param($Path)
        {
            (Assert-PSSyntaxErrors $Path).Length | Should -Be 0
        } | Should -Not -Throw
    }
}
