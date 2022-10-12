$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"



$powershell_samples = @(
    @{
        'Title' = "Simple Valid";
        'Path' = "${env:Temp}\File-$(New-Guid).ps1";
        'Content' = @(
            'if ($true) {',
            '  Write-Host "True!"',
            '}'
        );
        'Valid' = $true;
    },
    @{
        'Title' = "Simple Invalid";
        'Path' = "${env:Temp}\File-$(New-Guid).ps1";
        'Content' = @(
            'if (($true) {',
            '  Write-Host "True!"',
            '}'
        );
        'Valid' = $false;
    }
)



Describe $sut {
    Context 'Files' {
        foreach ($sample in $powershell_samples) {
            foreach ($test in $sample) {
                It $test.Title {
                    $test.Content | Out-String | Out-File $test.Path
                    $PSSyntaxErrors = Assert-PSSyntaxErrors -Path $test.Path
                    
                    if ($test.Valid) {
                        $PSSyntaxErrors.Length | Should Be 0
                    } else {
                        $PSSyntaxErrors.Length | Should BeGreaterThan 0
                    }
                }
            }
        }
    }

    Context 'CodeBlocks' {
        foreach ($sample in $powershell_samples) {
            foreach ($test in $sample) {
                It $test.Title {
                    $PSSyntaxErrors = Assert-PSSyntaxErrors -CodeBlock ($test.Content | Out-String)

                    if ($test.Valid) {
                        $PSSyntaxErrors.Length | Should Be 0
                    } else {
                        $PSSyntaxErrors.Length | Should BeGreaterThan 0
                    }
                }
            }
        }
    }
}
