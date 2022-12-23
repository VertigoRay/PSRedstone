#Requires -Modules Pester,psake,PowerShellGet,PSMinifier
$ErrorActionPreference = 'Stop'
trap {
    Write-Error ('( ͡° ͜ʖ ͡°) {0}' -f $_) -ErrorAction 'Continue'
    if ($env:CI) {
        $Host.SetShouldExit(1)
    }
}

properties {
    $script:PSScriptRootParent = ([IO.DirectoryInfo] $PSScriptRoot).Parent
    $script:thisModuleName = $script:PSScriptRootParent.BaseName
    $script:ManifestJsonFile = [IO.Path]::Combine($script:PSScriptRootParent.FullName, $script:thisModuleName, 'Manifest.json')
    $script:BuildOutput = [IO.Path]::Combine($script:PSScriptRootParent.FullName, 'dev', 'BuildOutput')

    $script:ParentDevModulePath = [IO.Path]::Combine($script:PSScriptRootParent.FullName, $script:thisModuleName)
    $script:ParentModulePath = [IO.Path]::Combine($script:BuildOutput, $script:thisModuleName)

    $PSModulePath1 = $env:PSModulePath.Split(';')[1]
    $script:SystemModuleLocation = [IO.Path]::Combine($PSModulePath1, $thisModuleName)

    $script:Version = & ([IO.Path]::Combine($PSScriptRoot, 'version.ps1'))
}

task default -Depends 'SyntaxAnal', 'Build'
task Syntax -Depends 'SyntaxJson', 'SyntaxPoSh'
task SyntaxAnal -Depends 'Syntax', 'PreAnalyze'

task SyntaxJSON {
    $testResults = Invoke-Pester ([IO.Path]::Combine($script:PSScriptRootParent.FullName, 'Tests')) -Tag 'SyntaxJSON' -PassThru
    if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message 'One or more Pester tests failed. Build cannot continue!'
    }
}

task SyntaxPoSh {
    $testResults = Invoke-Pester ([IO.Path]::Combine($script:PSScriptRootParent.FullName, 'Tests')) -Tag 'SyntaxPoSh' -PassThru
    if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message 'One or more Pester tests failed. Build cannot continue!'
    }
}

task PreAnalyze {
    $testResults = Invoke-Pester ([IO.Path]::Combine($script:PSScriptRootParent.FullName, 'Tests')) -Tag 'PSScriptAnalyzer' -PassThru
    if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message 'One or more Script Analyzer errors/warnings where found. Build cannot continue!'
    }
}

task BuildManifest {
    if (-not (Test-Path $script:ParentModulePath)) {
        New-Item -ItemType Directory -Path $script:ParentModulePath -Force
    }

    $Manifest = @{}
    $manifestJsonData = Get-Content $script:ManifestJsonFile |  Where-Object { -not $_.StartsWith('//') } | ConvertFrom-Json
    Write-Host "[PSAKE BuildManifest] manifestJsonData: $($manifestJsonData | ConvertTo-Json)" -ForegroundColor 'DarkMagenta'
    $manifestJsonData.PSObject.Properties | ForEach-Object {
        $Manifest.Set_Item($_.Name, $_.Value)
    }

    $Manifest.Copyright = $Manifest.Copyright -f [DateTime]::Now.Year
    Write-Verbose ('$script:ParentDevModulePath: {0}' -f $script:ParentDevModulePath)
    [System.Collections.ArrayList] $cmdletsToExport = @()
    [System.Collections.ArrayList] $functionsToExport = @()

    foreach ($public in (Get-ChildItem -Path ([IO.Path]::Combine($script:ParentDevModulePath, 'Public', '*.ps1')) -ErrorAction SilentlyContinue)) {
        $fullName = $public.FullName
        $baseName = $public.BaseName
        $cmdletBinding = Invoke-Command -ScriptBlock {
            . "${fullName}"
            (Get-Command "$baseName").CmdletBinding
        }
        if ($cmdletBinding) {
            $cmdletsToExport.Add($baseName) | Out-Null
        } else {
            $functionsToExport.Add($baseName) | Out-Null
        }
    }

    if (-not $manifestJsonData.AliasesToExport) {
        $Manifest.AliasesToExport = @()
    }
    $Manifest.CmdletsToExport = $cmdletsToExport
    $Manifest.FunctionsToExport = $cmdletsToExport + $functionsToExport
    if (-not $manifestJsonData.VariablesToExport) {
        $Manifest.VariablesToExport = @()
    }

    $Manifest.Path = "${script:ParentModulePath}\${script:thisModuleName}.psd1"
    $Manifest.RootModule = "${script:thisModuleName}.psm1"
    $Manifest.ModuleVersion = [version] $Version

    $Manifest.Remove('ModuleName') # Not a parameter.

    Write-Host "[PSAKE BuildManifest] New-ModuleManifest: $($Manifest | ConvertTo-Json)" -ForegroundColor 'DarkMagenta'
    New-ModuleManifest @Manifest
}

task Build -Depends BuildManifest {
    # Create Compiled PSM1
    $modulePSM1 = [IO.Path]::Combine($script:ParentModulePath, ('{0}.psm1' -f $script:thisModuleName))
    if (Test-Path $modulePSM1) {
        Remove-Item -LiteralPath $modulePSM1 -Confirm:$false -Force
    }
    Write-Host "[PSAKE Build] Adding to:`t$($modulePSM1 | ConvertTo-Json)" -ForegroundColor 'DarkMagenta'
    $ps1s = @(Get-ChildItem ([IO.Path]::Combine($script:PSScriptRootParent.FullName, $script:thisModuleName)) -Recurse -Filter '*.ps1' -File)
    $psm1s = @(Get-ChildItem ([IO.Path]::Combine($script:PSScriptRootParent.FullName, $script:thisModuleName)) -Filter '*.psm1' -File)
    foreach ($file in ($ps1s + $psm1s)) {
        Write-Host "[PSAKE Build] `tAdding:`t`t$($file.FullName | ConvertTo-Json)" -ForegroundColor 'DarkMagenta'
        $regionDevOnly = $false
        $allLines = foreach ($line in (Get-Content $file.FullName)) {
            if ($regionDevOnly) {
                if ($line.StartsWith('#endregion')) {
                    $regionDevOnly = $false
                }
                Write-Host "[PSAKE Build] `tRemoving Line:`t`t`t$(($line | Out-String).Trim())" -ForegroundColor 'DarkMagenta'
                continue
            } else {
                if ($line.StartsWith('#region DEVONLY')) {
                    $regionDevOnly = $true
                    Write-Host "[PSAKE Build] `tRemoving Line:`t`t`t$(($line | Out-String).Trim())" -ForegroundColor 'DarkMagenta'
                    continue
                }
                Write-Output $line
            }
        }
        $allLines | Out-File -LiteralPath $modulePSM1 -Encoding 'utf8' -Append -Force
    }

    [IO.Path]::Combine($script:ParentDevModulePath, ('{0}.psm1' -f $script:thisModuleName))

    # Sign Code
    # $pfxESE = [IO.Path]::Combine($env:Temp, 'ese.pfx')
    # Set-Content $pfxESE -Value ([System.Convert]::FromBase64String($env:ESE_CODE_SIGNING_CERT_PFXB64)) -Encoding 'Byte'
    # $certPass = ConvertTo-SecureString -String $env:ESE_CODE_SIGNING_CERT_PASS -AsPlainText -Force
    # $cert = (Get-PfxData -FilePath $pfxESE -Password $certPass).EndEntityCertificates[0]
    # foreach ($file in (Get-ChildItem $script:ParentModulePath -File)) {
    #     $authenticodeSignature = @{
    #         FilePath = $file.FullName
    #         Certificate = $cert
    #         TimeStampServer = 'http://timestamp.digicert.com'
    #     }
    #     Write-Host "[PSAKE Build] Set-AuthenticodeSignature: $($authenticodeSignature | ConvertTo-Json -Depth 1)" -ForegroundColor 'DarkMagenta'
    #     Set-AuthenticodeSignature @authenticodeSignature
    # }
}

task PostAnalyze {
    $saResults = Invoke-ScriptAnalyzer -Path ([IO.Path]::Combine($script:BuildOutput, $script:thisModuleName)) -Severity @('Error', 'Warning') -Recurse -Verbose:$false
    if ($saResults) {
        $saResults | Format-Table
        Write-Error -Message 'One or more Script Analyzer errors/warnings where found. Build cannot continue!'
    }
}

task Test {
    $testResults = Invoke-Pester -Path ([IO.Path]::Combine($script:PSScriptRootParent, 'Tests')) -PassThru
    if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message 'One or more Pester tests failed. Build cannot continue!'
    }
}

# task Deploy -depends PostAnalyze,Test {
task Deploy {
    $registerPSRepo = @{
        Name = 'PowerShell-ESE'
        SourceLocation = 'http://ese-inedo.utsarr.net:8624/nuget/powershell-ese/'
        PublishLocation = 'http://ese-inedo.utsarr.net:8624/nuget/powershell-ese/'
    }
    if (-not (Get-PSRepository $registerPSRepo.Name -ErrorAction 'Ignore')) {
        Write-Host "[PSAKE Deploy] Register-PSRepository: $($registerPSRepo | ConvertTo-Json)" -ForegroundColor 'DarkMagenta'
        Register-PSRepository @registerPSRepo
    }

    $publishModule = @{
        Path = ([IO.Path]::Combine($script:BuildOutput, $script:thisModuleName))
        NuGetApiKey = $env:PROGET_POWERSHELL_ESE
        Repository = 'PowerShell-ESE'
        Force = $true
        Verbose = $true
    }
    Write-Host "[PSAKE Deploy] Publish-Module: $($publishModule | ConvertTo-Json)" -ForegroundColor 'DarkMagenta'
    Publish-Module @publishModule
}
