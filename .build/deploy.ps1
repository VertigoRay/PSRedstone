<#
    Deployed with PSDeploy
        - https://github.com/RamblingCookieMonster/PSDeploy
#>
$PSScriptRootParent = Split-Path $PSScriptRoot -Parent
Write-Host "[Deploy] APPVEYOR_PROJECT_NAME: ${env:APPVEYOR_PROJECT_NAME}" -Foregroundcolor 'Magenta'
Write-Host "[Deploy] PSScriptRootParent: ${PSScriptRootParent}" -Foregroundcolor 'Magenta'
Write-Host "[Deploy] Path Exists (${PSScriptRootParent}): $(Test-Path $PSScriptRootParent)" -Foregroundcolor 'Magenta'
Write-Host "[Deploy] Path Exists (${PSScriptRootParent}\dev): $(Test-Path "${PSScriptRootParent}\dev")" -Foregroundcolor 'Magenta'
Write-Host "[Deploy] Path Exists (${PSScriptRootParent}\dev\BuildOutput): $(Test-Path "${PSScriptRootParent}\dev\BuildOutput")" -Foregroundcolor 'Magenta'
Write-Host "[Deploy] Path Exists (${PSScriptRootParent}\dev\BuildOutput\QuserObject): $(Test-Path "${PSScriptRootParent}\dev\BuildOutput\QuserObject")" -Foregroundcolor 'Magenta'

[version] $version = (Import-PowerShellDataFile "${PSScriptRootParent}\dev\BuildOutput\PSBacon\PSBacon.psd1").ModuleVersion

Deploy Module {                        # Deployment name. This needs to be unique. Call it whatever you want
    By Filesystem {                              # Deployment type. See Get-PSDeploymentType
        FromSource 'dev\BuildOutput\PSBacon'
        To ('\\smb.utsarr.net\admin\ConfigMgmt\MECM\Applications\ESE\PSBacon\{0}' -f $version)          # One or more destinations to deploy the sources to
        Tagged Prod                              # One or more tags you can use to restrict deployments or queries
        WithOptions @{
            Mirror = $true                       # If the source is a folder, triggers robocopy purge. Danger
        }
    }
}