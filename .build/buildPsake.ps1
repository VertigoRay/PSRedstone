#Requires -Modules Pester,psake,PowerShellGet,PSMinifier
$ErrorActionPreference = 'Stop'
trap {
    Write-Error ('( ͡° ͜ʖ ͡°) {0}' -f $_) -ErrorAction 'Continue'
    if ($env:CI) {
        $Host.SetShouldExit(1)
    }
}

properties {
    # foreach ($item in (Get-ChildItem 'env:' | Where-Object { $_.Name.StartsWith('APPVEYOR') })) {
    #     Write-Host ('{0}: {1}' -f $item.Name, $item.Value) -ForegroundColor 'Black'
    # }

    $script:psScriptRootParent = ([IO.DirectoryInfo] $PSScriptRoot).Parent
    $script:thisModuleName = if ($mn = (Get-ChildItem $script:psScriptRootParent.FullName -Directory -Filter $script:psScriptRootParent.BaseName).BaseName) {
        # AppVeyor's project folder is changed to all lowercase (same as URL slug).
        # This attempts to grab the sub-folder with the same name to preserve the preferred case.
        # This *should be* consistent across *all* platforms, assuming good sub folder structure/case.
        $mn
    } elseif ($env:APPVEYOR_PROJECT_NAME) {
        # Alternatively, use what's set in AppVeyor
        #   More Info: https://www.appveyor.com/docs/environment-variables/
        $env:APPVEYOR_PROJECT_NAME
    } else {
        $script:psScriptRootParent.BaseName
    }

    $script:ManifestJsonFile = [IO.Path]::Combine($script:psScriptRootParent.FullName, $script:thisModuleName, 'Manifest.json')
    $script:BuildOutput = [IO.Path]::Combine($script:psScriptRootParent.FullName, 'dev', 'BuildOutput')

    $script:parentDevModulePath = [IO.Path]::Combine($script:psScriptRootParent.FullName, $script:thisModuleName)
    $script:parentModulePath = [IO.Path]::Combine($script:BuildOutput, $script:thisModuleName)

    $PSModulePath1 = $env:PSModulePath.Split(';')[1]
    $script:SystemModuleLocation = [IO.Path]::Combine($PSModulePath1, $thisModuleName)

    $script:Version = & ([IO.Path]::Combine($PSScriptRoot, 'version.ps1'))

    # https://www.appveyor.com/docs/environment-variables/
    $env:APPVEYOR_BUILD_VERSION = $script:Version
}

task default -Depends 'SyntaxAnal', 'Test', 'Build'
task Syntax -Depends 'SyntaxJson', 'SyntaxPoSh'
task SyntaxAnal -Depends 'Syntax', 'PreAnalyze'

task SyntaxJSON {
    $testResults = Invoke-Pester ([IO.Path]::Combine($script:psScriptRootParent.FullName, 'Tests')) -Tag 'SyntaxJSON' -PassThru
    if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message '[PSAKE SytaxJSON] One or more Pester tests failed. Build cannot continue!'
    }
}

task SyntaxPoSh {
    $testResults = Invoke-Pester ([IO.Path]::Combine($script:psScriptRootParent.FullName, 'Tests')) -Tag 'SyntaxPoSh' -PassThru
    if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message '[PSAKE SyntaxPoSh] One or more Pester tests failed. Build cannot continue!'
    }
}

task PreAnalyze {
    $testResults = Invoke-Pester ([IO.Path]::Combine($script:psScriptRootParent.FullName, 'Tests')) -Tag 'PSScriptAnalyzer' -PassThru
    if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message '[PSAKE PreAnalyze] One or more Script Analyzer errors/warnings where found. Build cannot continue!'
    }
}

task BuildManifest {
    if (-not (Test-Path $script:parentModulePath)) {
        New-Item -ItemType Directory -Path $script:parentModulePath -Force
    }

    $Manifest = @{}
    $manifestJsonData = Get-Content $script:ManifestJsonFile |  Where-Object { -not $_.StartsWith('//') } | ConvertFrom-Json
    Write-Host "[PSAKE BuildManifest] manifestJsonData: $($manifestJsonData | ConvertTo-Json)" -ForegroundColor 'DarkMagenta'
    $manifestJsonData.PSObject.Properties | ForEach-Object {
        $Manifest.Set_Item($_.Name, $_.Value)
    }

    $Manifest.Copyright = $Manifest.Copyright -f [DateTime]::Now.Year
    Write-Verbose ('[PSAKE BuildManifest] $script:parentDevModulePath: {0}' -f $script:parentDevModulePath)
    [System.Collections.ArrayList] $cmdletsToExport = @()
    [System.Collections.ArrayList] $functionsToExport = @()

    foreach ($public in (Get-ChildItem -Path ([IO.Path]::Combine($script:parentDevModulePath, 'Public', '*.ps1')) -ErrorAction SilentlyContinue)) {
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

    $Manifest.Path = "${script:parentModulePath}\${script:thisModuleName}.psd1"
    $Manifest.RootModule = "${script:thisModuleName}.psm1"
    $Manifest.ModuleVersion = [version] $Version

    $Manifest.Remove('ModuleName') # Not a parameter.

    Write-Host "[PSAKE BuildManifest] New-ModuleManifest: $($Manifest | ConvertTo-Json)" -ForegroundColor 'DarkMagenta'
    New-ModuleManifest @Manifest
}

task Build -Depends BuildManifest {
    # Create Compiled PSM1
    $modulePSM1 = [IO.Path]::Combine($script:parentModulePath, ('{0}.psm1' -f $script:thisModuleName))
    if (Test-Path $modulePSM1) {
        Remove-Item -LiteralPath $modulePSM1 -Confirm:$false -Force
    }
    Write-Host "[PSAKE Build] Adding to:`t$($modulePSM1 | ConvertTo-Json)" -ForegroundColor 'DarkMagenta'
    $ps1s = @(Get-ChildItem ([IO.Path]::Combine($script:psScriptRootParent.FullName, $script:thisModuleName)) -Recurse -Filter '*.ps1' -File)
    $psm1s = @(Get-ChildItem ([IO.Path]::Combine($script:psScriptRootParent.FullName, $script:thisModuleName)) -Filter '*.psm1' -File)
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

    [IO.Path]::Combine($script:parentDevModulePath, ('{0}.psm1' -f $script:thisModuleName))

    # Sign Code
    # $pfxESE = [IO.Path]::Combine($env:Temp, 'ese.pfx')
    # Set-Content $pfxESE -Value ([System.Convert]::FromBase64String($env:ESE_CODE_SIGNING_CERT_PFXB64)) -Encoding 'Byte'
    # $certPass = ConvertTo-SecureString -String $env:ESE_CODE_SIGNING_CERT_PASS -AsPlainText -Force
    # $cert = (Get-PfxData -FilePath $pfxESE -Password $certPass).EndEntityCertificates[0]
    # foreach ($file in (Get-ChildItem $script:parentModulePath -File)) {
    #     $authenticodeSignature = @{
    #         FilePath = $file.FullName
    #         Certificate = $cert
    #         TimeStampServer = 'http://timestamp.digicert.com'
    #     }
    #     Write-Host "[PSAKE Build] Set-AuthenticodeSignature: $($authenticodeSignature | ConvertTo-Json -Depth 1)" -ForegroundColor 'DarkMagenta'
    #     Set-AuthenticodeSignature @authenticodeSignature
    # }

    $compress = @{
        Path = (Get-ChildItem $script:parentModulePath -File -Recurse).FullName
        CompressionLevel = 'Optimal'
        DestinationPath = [IO.Path]::Combine($script:psScriptRootParent.FullName, 'dev', ('{0}.zip' -f $script:thisModuleName))
    }
    Compress-Archive @compress
}

task PostAnalyze {
    $saResults = Invoke-ScriptAnalyzer -Path ([IO.Path]::Combine($script:BuildOutput, $script:thisModuleName)) -Severity @('Error', 'Warning') -Recurse -Verbose:$false
    if ($saResults) {
        $saResults | Format-Table
        Write-Error -Message '[PSAKE PostAnalyze] One or more Script Analyzer errors/warnings where found. Build cannot continue!'
    }
}

<#
Invoke-psake -buildFile .\.build\buildPsake.ps1 -TaskList Test -Parameters @{Pester = @{
    Configuration = @{
        CodeCoverage = @{
            Enabled = $true
            Path = 'C:\Users\qhm067\Git\PSRedstone\PSRedstone\Public\*-RedstoneWim.ps1'
        }
    }
}}
#>
task Test {
    if ($Pester) {
        $pesterFrom = 'Param'
        # Pester would be passed in as a PSake Parameter:
        #    More Info: https://psake.readthedocs.io/en/latest/pass-parameters/
        #    Example: Invoke-psake -buildFile .\.build\buildPsake.ps1 -TaskList Test -Parameters @{Pester = @{ Output = 'Detailed' }}
        $invokePester = @{}
        foreach ($item in $Pester.GetEnumerator()) {
            $invokePester.Set_Item($item.Name, $item.Value)
        }
    } else {
        $pesterFrom = 'Default'
        $invokePester = @{
            Configuration = @{
                Run = @{
                    Path = [IO.Path]::Combine($script:psScriptRootParent.FullName, 'Tests')
                    PassThru = $true
                    Exit = if ($env:CI) { $true } else { $false }
                }
                TestResult = @{
                    Enabled = $true
                }
                CodeCoverage = @{
                    Enabled = $true
                    Path = [IO.Path]::Combine($script:parentDevModulePath, '*', '*.ps1')
                    OutputPath = [IO.Path]::Combine($script:psScriptRootParent.FullName, 'dev', 'coverage.xml')
                }
            }
        }
    }

    Write-Host ('[PSAKE Test] Invoke-Pester ({1}): {0}' -f ($invokePester | ConvertTo-Json), $pesterFrom) -ForegroundColor 'DarkMagenta'
    $testResults = Invoke-Pester @invokePester
    if ($testResults.FailedCount -gt 0) {
        $msg = '[PSAKE Test] {0} Pester test{1} failed. Build cannot continue!' -f $testResults.FailedCount, $(if ($testResults.FailedCount -gt 1) { 's' })
        Write-Warning $msg
        $testResults | Format-List
        Throw $msg
    }

    # EXEs all  downloaded in Prep task.
    # & 'C:\Program Files (x86)\GnuPG\bin\gpg.exe' --import verification.gpg
    # & 'C:\Program Files (x86)\GnuPG\bin\gpg.exe' --verify codecov.exe.SHA256SUM.sig codecov.exe.SHA256SUM
    # $ref = ($(certUtil -hashfile codecov.exe SHA256)[1], 'codecov.exe') -join '  '
    # $diff = Get-Content 'codecov.exe.SHA256SUM'
    # if (-not (Compare-Object -ReferenceObject $ref -DifferenceObject $diff)) {
    #     Write-Host ('[PSAKE Test] CodeCov.exe SHASUM verified') -ForegroundColor 'DarkMagenta'
    # } else {
    #     Write-Warning ('[PSAKE Test] CodeCov.exe SHASUM invalid')
    #     Throw ('CodeCov.exe SHASUM invalid')
    # }
}

task CodeCov {
    & ([IO.Path]::Combine($script:psScriptRootParent.FullName, 'dev', 'codecov.exe'))
}

task GitHubTagDelete {
    if ($env:APPVEYOR_REPO_TAG -eq 'true') {
        $gitFormatters = @(
            $env:GITHUB_PERSONAL_ACCESS_TOKEN
            $env:APPVEYOR_REPO_NAME
            $env:APPVEYOR_REPO_TAG_NAME
        )

        Write-Host 'Git Config' -ForegroundColor 'Black' -BackgroundColor 'DarkCyan'
        $configs = @(
            '& git remote rm origin'
            '& git remote add origin "https://{0}:x-oauth-basic@github.com/{1}.git"'
            '& git config --global user.name "VertigoBot"'
            '& git config --global user.email "VertigoBot@80.vertigion.com"'
        )
        foreach ($config in $configs) {
            Write-Host ('PS > {0}' -f ($config -f $gitFormatters)).Replace($env:GITHUB_PERSONAL_ACCESS_TOKEN, '********')
            if ($config.StartsWith('&')) {
                $cmd = $config.Split(' ', 3)
                $process = @{
                    FilePath = $cmd[1]
                    ArgumentList = $cmd[2]
                    RedirectStandardOutput = [IO.Path]::Combine($env:Temp, 'stdout.txt')
                    RedirectStandardError = [IO.Path]::Combine($env:Temp, 'stderr.txt')
                    Wait = $true
                    PassThru = $true
                }
                $result = Start-Process @process
                Write-Host ('StdOut: {0}' -f (Get-Content ([IO.Path]::Combine($env:Temp, 'stdout.txt')) | Out-String))
                Write-Host ('StdErr: {0}' -f (Get-Content ([IO.Path]::Combine($env:Temp, 'stderr.txt')) | Out-String)) -BackgroundColor 'Red'
                Write-Host ('# ExitCode: {0}' -f $result.ExitCode)
            } else {
                $config -f $gitFormatters | Invoke-Expression
            }
        }

        Write-Host ('Git Delete Tag: {0}' -f $env:APPVEYOR_REPO_TAG_NAME) -ForegroundColor 'Black' -BackgroundColor 'DarkCyan'
        $configs = @(
            '& git stash --all'
            '& git stash list'
            '& git pull origin master'
            '& git stash pop'
            '& git push --set-upstream origin :refs/tags/{2}'
        )
        foreach ($config in $configs) {
            Write-Host ('PS > {0}' -f ($config -f $gitFormatters)).Replace($env:GITHUB_PERSONAL_ACCESS_TOKEN, '********')
            if ($config.StartsWith('&')) {
                $cmd = $config.Split(' ', 3)
                $process = @{
                    FilePath = $cmd[1]
                    ArgumentList = $cmd[2]
                    RedirectStandardOutput = [IO.Path]::Combine($env:Temp, 'stdout.txt')
                    RedirectStandardError = [IO.Path]::Combine($env:Temp, 'stderr.txt')
                    Wait = $true
                    PassThru = $true
                }
                $result = Start-Process @process
                Write-Host ('StdOut: {0}' -f (Get-Content ([IO.Path]::Combine($env:Temp, 'stdout.txt')) | Out-String))
                Write-Host ('StdErr: {0}' -f (Get-Content ([IO.Path]::Combine($env:Temp, 'stderr.txt')) | Out-String)) -BackgroundColor 'Red'
                Write-Host ('# ExitCode: {0}' -f $result.ExitCode)
            } else {
                $config -f $gitFormatters | Invoke-Expression
            }
        }
    }
}

task DeployProGet {
    $registerPSRepo = @{
        Name = 'PowerShell-ESE'
        SourceLocation = $env:PROGET_POWERSHELL_ESE_URL
        PublishLocation = $env:PROGET_POWERSHELL_ESE_URL
    }
    if (-not (Get-PSRepository $registerPSRepo.Name -ErrorAction 'Ignore')) {
        Write-Host "[PSAKE DeployProGet] Register-PSRepository: $($registerPSRepo | ConvertTo-Json)" -ForegroundColor 'DarkMagenta'
        Register-PSRepository @registerPSRepo
    }

    $publishModule = @{
        Path = ([IO.Path]::Combine($script:BuildOutput, $script:thisModuleName))
        NuGetApiKey = $env:PROGET_POWERSHELL_ESE
        Repository = 'PowerShell-ESE'
        Force = $true
        Verbose = $true
    }
    Write-Host ('[PSAKE DeployPSGallery] Publish-Module: {0}' -f ($publishModule | ConvertTo-Json).Replace($env:PROGET_POWERSHELL_ESE, '********')) -ForegroundColor 'DarkMagenta'
    Publish-Module @publishModule
}

task DeployPSGallery {
    <#
        Deployed with PSDeploy
            - https://github.com/RamblingCookieMonster/PSDeploy
    #>
    [IO.DirectoryInfo] $buildOutputModule = [IO.Path]::Combine($script:BuildOutput, $script:thisModuleName)

    Write-Host ('[PSAKE DeployPSGallery] APPVEYOR_PROJECT_NAME: {0}' -f $env:APPVEYOR_PROJECT_NAME) -Foregroundcolor 'Magenta'
    Write-Host ('[PSAKE DeployPSGallery] buildOutputModule: {0}' -f $buildOutputModule) -Foregroundcolor 'Magenta'
    Write-Host ('[PSAKE DeployPSGallery] Path Exists ({0}): {1}' -f $buildOutputModule.Parent.Parent.Parent.Exists, $buildOutputModule.Parent.Parent.Parent.FullName) -Foregroundcolor 'Magenta'
    Write-Host ('[PSAKE DeployPSGallery] Path Exists ({0}): {1}' -f $buildOutputModule.Parent.Parent.Exists, $buildOutputModule.Parent.Parent.FullName) -Foregroundcolor 'Magenta'
    Write-Host ('[PSAKE DeployPSGallery] Path Exists ({0}): {1}' -f $buildOutputModule.Parent.Exists, $buildOutputModule.Parent.FullName) -Foregroundcolor 'Magenta'
    Write-Host ('[PSAKE DeployPSGallery] Path Exists ({0}): {1}' -f $buildOutputModule.Exists, $buildOutputModule.FullName) -Foregroundcolor 'Magenta'

    # Deploy Module {
    #     By PSGalleryModule $script:thisModuleName {
    #         FromSource $buildOutputModule.FullName
    #         To PSGallery
    #         # Tagged Testing
    #         WithOptions @{
    #             ApiKey = $env:PSGALLERY_API_KEY
    #         }
    #     }
    # }

    $publishModule = @{
        Path = $buildOutputModule.FullName
        NuGetApiKey = $env:PSGALLERY_API_KEY
        Repository = 'PSGallery'
        Force = $true
        Verbose = $true
    }
    Write-Host ('[PSAKE DeployPSGallery] Publish-Module: {0}' -f ($publishModule | ConvertTo-Json).Replace($env:PSGALLERY_API_KEY, '********')) -ForegroundColor 'DarkMagenta'
    Publish-Module @publishModule
}

task AppveyorArtifact {
    $fileName = [IO.Path]::Combine($env:APPVEYOR_BUILD_FOLDER, 'dev', 'PSRedstone.zip')
    Write-Host ('[PSAKE AppveyorArtifact] Push-AppveyorArtifact FileName: {0}' -f $fileName) -ForegroundColor 'DarkMagenta'
    $newFileName = 'PSRedstone.{0}.zip' -f $env:APPVEYOR_BUILD_VERSION
    Write-Host ('[PSAKE AppveyorArtifact] Push-AppveyorArtifact NewFileName: {0}' -f $newFileName) -ForegroundColor 'DarkMagenta'
    Push-AppveyorArtifact $fileName -FileName $newFileName
}
