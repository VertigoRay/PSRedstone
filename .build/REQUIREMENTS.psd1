<#
    REQUIREMENTS installed with [PSDepend](https://github.com/RamblingCookieMonster/PSDepend):
    See `.appveyor.yml::install` for details on preparing the system to use PSDepend.
#>
@{
    Prep             = @{
        DependencyType = 'task'
        Target         = '$PWD\.scripts\requirements.prep.ps1'
        DependsOn      = @('powershell-yaml')
    }
    Pester             = '5.3.3'
    'powershell-yaml'  = '0.3.2'
    psake              = '4.9.0'
    PSDeploy           = '0.2.3'
    PSScriptAnalyzer   = '1.11.0'
    PSCodeCovIo        = '1.0.1'
    PSMinifier         = '1.1.3'
}