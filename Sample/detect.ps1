#Requires -Modules PSRedstone,PSWriteLog,@{ModuleName = 'Pester'; RequiredVersion = '5.4.0'}
# $settings is injected above during build.
$redstone, $settings = New-Redstone
$redstone.Action = 'detect'

$env:PSWriteLogFilePath = $redstone.Settings.Log.File.FullName
$env:PSWriteLogIncludeInvocationHeader = $true
$InformationPreference = 'Continue'
$VerbosePreference = 'Continue'

if ($MyInvocation.MyCommand.Name -eq 'detect.ps1') {
    # This is the InvocationName when we running the dev version of the script, like in Windows Sandbox.
    # When SCCM calls detection, the detection script is put in a file named as a guid.
    #   i.e. fae94777-2c0d-4dd0-94f0-407f7cd07858.ps1
    Write-Warning '[DEV MODE] The Invocation looks like DEV; showing detailed output ...'
    $env:PSWriteLogInformationSilent = $null
    $env:PSWriteLogVerboseSilent = $null
    $devMode = $true
} else {
    $env:PSWriteLogInformationSilent = $true
    $env:PSWriteLogVerboseSilent = $true
    $devMode = $false
}

$pesterDetect = @{
    PublisherProductVersion = @($redstone.Publisher, $redstone.Product, $redstone.Version) -join ' '
    PesterScriptBlock = {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]
            $FunctionName
        )

        Describe $FunctionName {
            It 'Return Boolean' {
                {
                    & $FunctionName | Should -BeOfType 'System.Boolean'
                } | Should -Not -Throw
            }
        }
    }
    PesterScriptBlockParam = @{
        FunctionName = 'Assert-IsElevated'
    }
}
Invoke-PesterDetect @pesterDetect
