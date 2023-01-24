<#
    REQUIREMENTS installed with [PSDepend](https://github.com/RamblingCookieMonster/PSDepend):
    See `.appveyor.yml::install` for details on preparing the system to use PSDepend.
#>
@{
    '7Zip4Powershell'  = '2.2.0'
    Pester             = '5.3.3'
    'powershell-yaml'  = '0.3.2'
    psake              = '4.9.0'
    PSDeploy           = '0.2.3'
    PSScriptAnalyzer   = '1.11.0'
    PSCodeCovIo        = '1.0.1'
    PSMinifier         = '1.1.3'
    platyPS            = @{
        Parameters = @{
            Name = 'platyPS'
            RequiredVersion = '0.14.2'
            AllowClobber = $true
            Force = $true
            SkipPublisherCheck = $true
        }
    }
}