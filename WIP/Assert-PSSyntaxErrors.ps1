<#
.SYNOPSIS
Return an Array of the PSSyntax Errors.
.DESCRIPTION
Return an Array of the PSSyntax Errors. If there are no errors, the array will be empty.

Each Item in the array is a string with a sumary of the error:

```powershell
":${StartLine}.${StartColumn}-:${EndLine}.${EndColumn} ${Description}"
```
.PARAMETER CodeBlock
Powershell code to syntax check.
.PARAMETER Path
The path to the Powershell file to syntax check.
.INPUTS
# Does not work with the pipeline.
.OUTPUTS
# Does not work with the pipeline.
.EXAMPLE
# Using CodeBlock; Valid
> $PSSyntaxErrors = Assert-PSSyntaxErrors -CodeBlock (Get-Content .\test.ps1 | Out-String )
> $PSSyntaxErrors.Length
0
> $PSSyntaxErrors
.EXAMPLE
# Using CodeBlock; 6 Syntax Errors
> $PSSyntaxErrors = Assert-PSSyntaxErrors -CodeBlock (Get-Content .\test_6err.ps1 | Out-String )
> $PSSyntaxErrors.Length
6
> $PSSyntaxErrors
:2.1-:2.5 The 'from' keyword is not supported in this version of the language.
:7.290-:7.290 You must provide a value expression following the '%' operator.
:7.291-:7.299 Unexpected token '__file__' in expression or statement.
:7.290-:7.290 Missing closing ')' in expression.
:7.299-:7.300 Unexpected token ')' in expression or statement.
:10.3-:10.3 Missing '(' after 'if' in if statement.
.EXAMPLE
# Using Path; Valid
> $PSSyntaxErrors = Assert-PSSyntaxErrors '.\test.ps1'
> $PSSyntaxErrors.Length
0
> $PSSyntaxErrors
.EXAMPLE
# Using Path; 6 Syntax Errors
> $PSSyntaxErrors = Assert-PSSyntaxErrors '.\test_6err.ps1'
> $PSSyntaxErrors.Length
6
> $PSSyntaxErrors
:2.1-:2.5 The 'from' keyword is not supported in this version of the language.
:7.290-:7.290 You must provide a value expression following the '%' operator.
:7.291-:7.299 Unexpected token '__file__' in expression or statement.
:7.290-:7.290 Missing closing ')' in expression.
:7.299-:7.300 Unexpected token ')' in expression or statement.
:10.3-:10.3 Missing '(' after 'if' in if statement.
#>
function Global:Assert-PSSyntaxErrors {
    param(
        [Parameter(
            Mandatory=$true,
            HelpMessage = "Powershell code to syntax check.",
            ParameterSetName='Code'
        )]
        [string] $CodeBlock
        ,
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