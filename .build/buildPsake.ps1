#Requires -Modules Pester,psake,PowerShellGet,PSMinifier
$ErrorActionPreference = 'Stop'
trap {
    Write-Error ('( ͡° ͜ʖ ͡°) {0}' -f $_) -ErrorAction 'Continue'
    if ($env:CI) {
        $Host.SetShouldExit(1)
    }
}

$global:gitFormatters = @(
    $env:GITHUB_PERSONAL_ACCESS_TOKEN
    $env:APPVEYOR_REPO_NAME
    $env:APPVEYOR_REPO_TAG_NAME
)

function global:Invoke-Config {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Config
    )

    if ($Config.StartsWith('&')) {
        $cmd = $Config.Split(' ', 3)
        $process = @{
            FilePath = $cmd[1]
            ArgumentList = $cmd[2] -f $gitFormatters
            RedirectStandardOutput = [IO.Path]::Combine($env:Temp, 'stdout.txt')
            RedirectStandardError = [IO.Path]::Combine($env:Temp, 'stderr.txt')
            Wait = $true
            PassThru = $true
        }
        $result = Start-Process @process
        if ($stdout = (Get-Content ([IO.Path]::Combine($env:Temp, 'stdout.txt')) | Out-String).Trim()) {
            Write-Host $stdout
        }
        if ($stderr = (Get-Content ([IO.Path]::Combine($env:Temp, 'stderr.txt')) | Out-String).Trim()) {
            if ($result.ExitCode) {
                Write-Host ('# ExitCode: {0}' -f $result.ExitCode) -BackgroundColor 'DarkRed'
                Write-Error $stderr
            } else {
                Write-Host $stderr -BackgroundColor 'DarkYellow'
                Write-Host ('# ExitCode: {0}' -f $result.ExitCode)
            }
        }
    } else {
        $config -f $gitFormatters | Invoke-Expression
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
    [IO.DirectoryInfo] $script:dev = [IO.Path]::Combine($script:psScriptRootParent.FullName, 'dev')
    [IO.DirectoryInfo] $script:devDocs = [IO.Path]::Combine($script:dev, 'docs')
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
    Write-Host ('[PSAKE BuildManifest] $script:parentDevModulePath: {0}' -f $script:parentDevModulePath) -ForegroundColor 'DarkMagenta'
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

    $Manifest.Path = [IO.Path]::Combine($script:parentModulePath, ('{0}.psd1' -f $script:thisModuleName))
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

    $license = @{
        LiteralPath = [IO.Path]::Combine($script:psScriptRootParent.FullName, 'LICENSE.md')
        Destination = [IO.Path]::Combine($script:parentModulePath, 'LICENSE.md')
    }
    Write-Host ('[PSAKE Build] Copy License: {0}' -f ($license | ConvertTo-Json)) -ForegroundColor 'Black' -BackgroundColor 'Cyan'
    Copy-Item @license -Force


    # Sign Code
    # $pfxESE = [IO.Path]::Combine($env:Temp, 'ese.pfx')
    # Set-Content $pfxESE -Value ([System.Convert]::FromBase64String($env:ESE_CODE_SIGNING_CERT_PFXB64)) -Encoding 'Byte'
    # $certPass = ConvertTo-SecureString -String $env:ESE_CODE_SIGNING_CERT_PASS -AsPlainText -Force
    # $cert = (Get-PfxData -FilePath $pfxESE -Password $certPass).EndEntityCertificates[0]
    # foreach ($file in (Get-ChildItem $script:parentModulePath -File)) {
    #     $authenticodeSignature = @{
    #         FilePath = $file.FullName
    #         Certificate = $cert
    #         TimeStampServer = 'https://timestamp.digicert.com'
    #     }
    #     Write-Host "[PSAKE Build] Set-AuthenticodeSignature: $($authenticodeSignature | ConvertTo-Json -Depth 1)" -ForegroundColor 'DarkMagenta'
    #     Set-AuthenticodeSignature @authenticodeSignature
    # }

    if ($SkipCompression) {
        Write-Host '[PSAKE Build] Skipping compressions step; set via a Psake parameter.' -ForegroundColor 'Black' -BackgroundColor 'Cyan'
    } else {
        $compress = @{
            Path = [IO.Path]::Combine($script:psScriptRootParent.FullName, 'dev')
            Filter = '*'
            Format = 'SevenZip'
            CompressionLevel = 'Ultra'
            ArchiveFileName = [IO.Path]::Combine($script:psScriptRootParent.FullName, 'dev.7z')
        }
        Write-Host ('[PSAKE Build] Compress Archive: {0}' -f ($compress | ConvertTo-Json)) -ForegroundColor 'Black' -BackgroundColor 'Cyan'
        Compress-7Zip @compress

        Move-Item -LiteralPath $compress.ArchiveFileName -Destination ([IO.Path]::Combine($script:psScriptRootParent.FullName, 'dev', 'dev.7z')) -Force

        if ($env:CI -and $env:APPVEYOR) {
            Write-Host ('[PSAKE Build] Push-AppveyorArtifact FileName: {0}' -f ([IO.Path]::Combine($script:psScriptRootParent.FullName, 'dev', 'dev.7z'))) -ForegroundColor 'DarkMagenta'
            $newFileName = '{0}.{1}.7z' -f ([IO.FileInfo] ([IO.Path]::Combine($script:psScriptRootParent.FullName, 'dev', 'dev.7z'))).BaseName, $env:APPVEYOR_BUILD_VERSION
            Write-Host ('[PSAKE Build] Push-AppveyorArtifact NewFileName: {0}' -f $newFileName) -ForegroundColor 'DarkMagenta'
            Push-AppveyorArtifact ([IO.Path]::Combine($script:psScriptRootParent.FullName, 'dev', 'dev.7z')) -FileName $newFileName
        }

        $compress = @{
            Path = $script:parentModulePath
            Filter = '*'
            Format = 'Zip'
            CompressionLevel = 'Normal'
            ArchiveFileName = [IO.Path]::Combine($script:psScriptRootParent.FullName, 'dev', ('{0}.zip' -f $script:thisModuleName))
        }
        Write-Host ('[PSAKE Build] Compress Archive: {0}' -f ($compress | ConvertTo-Json)) -ForegroundColor 'Black' -BackgroundColor 'Cyan'
        Compress-7Zip @compress

        if ($env:CI -and $env:APPVEYOR) {
            Write-Host ('[PSAKE Build] Push-AppveyorArtifact FileName: {0}' -f $compress.ArchiveFileName) -ForegroundColor 'DarkMagenta'
            $newFileName = '{0}.{1}.zip' -f ([IO.FileInfo] $compress.ArchiveFileName).BaseName, $env:APPVEYOR_BUILD_VERSION
            Write-Host ('[PSAKE Build] Push-AppveyorArtifact NewFileName: {0}' -f $newFileName) -ForegroundColor 'DarkMagenta'
            Push-AppveyorArtifact $compress.ArchiveFileName -FileName $newFileName
        }
    }
}

# .\.build\env.ps1; Remove-Item .\dev\docs -Recurse -Force; Remove-Module PSRedstone
# Invoke-psake -buildFile .\.build\buildPsake.ps1 -TaskList Docs -Parameters @{FunctionsMD = [IO.Path]::Combine(([IO.DirectoryInfo] $PWD.Path).Parent.FullName, 'PSRedstone.wiki', 'Functions.md'); SkipCompression = $true}
task Docs {
    if (Get-Module $script:thisModuleName) { Remove-Module $script:thisModuleName }
    if ($FunctionsMD) {
        Write-Host ('[PSAKE Docs] FunctionsMD Passed in') -ForegroundColor 'Black' -BackgroundColor 'Cyan'
        [IO.FileInfo] $FunctionsMD = $FunctionsMD
    } else {
        Write-Host ('[PSAKE Docs] FunctionsMD generated') -ForegroundColor 'Black' -BackgroundColor 'Cyan'
        [IO.FileInfo] $FunctionsMD = [IO.Path]::Combine($script:dev, 'wiki', 'Functions.md')
        if ($FunctionsMD.Directory.Exists) {
            $FunctionsMD.Directory | Remove-Item -Recurse -Force
        }
        $configs = @(
            '& git clone "https://{{0}}:x-oauth-basic@github.com/{{1}}.wiki.git" "{0}"' -f $FunctionsMD.Directory.FullName
        )
        foreach ($config in $configs) {
            Write-Host ('PS > {0}' -f ($config -f $global:gitFormatters)).Replace($env:GITHUB_PERSONAL_ACCESS_TOKEN, '********')
            Invoke-Config -Config $config
        }
    }
    Write-Host ('[PSAKE Docs] FunctionsMD: {0}' -f ($FunctionsMD.FullName | ConvertTo-Json)) -ForegroundColor 'Black' -BackgroundColor 'Cyan'

    Import-Module ([IO.Path]::Combine($script:parentModulePath, ('{0}.psd1' -f $script:thisModuleName))) -Global -Force
    Get-Module $script:thisModuleName | Format-List

    $markdownHelp = @{
        Module = $script:thisModuleName
        OutputFolder = $script:devDocs.FullName
        UseFullTypeName = $true
        NoMetadata = $true
    }
    Write-Host ('[PSAKE Docs] Markdown Help: {0}' -f ($markdownHelp | ConvertTo-Json))

    $script:devDocs.Refresh()
    if (-not $script:devDocs.Exists) {
        New-MarkdownHelp @markdownHelp
    } else {
        Update-MarkdownHelp $markdownHelp.OutputFolder
    }
    $script:devDocs.Refresh()

    # Copy all of the generated MD files into a single Functions.ms and place it in the path provided.
    $mds = Get-ChildItem $script:devDocs -Filter '*.md' -File
    [Collections.ArrayList] $allLines = @(
        '{0} `{1}` functions are fully documented in this article.' -f $script:thisModuleName, $script:Version
        'This article has been made availble for your convenience and for easy searching.'
        'The same information is availble using the [`Get-Help`](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/get-help) function in PowerShell.'
        'The sections of this document have been automatically generated with [platyPS](https://github.com/PowerShell/platyPS) and glued together into a single document.'
        'To review documentation for a previous version of *{0}*, [review the history](Functions/_history).' -f $script:thisModuleName
        ''
        '**Table of Contents:**'
        ''
    )

    # Build TOC
    foreach ($md in $mds) {
        $line = '- [{0}](#{1})' -f $md.BaseName, $md.BaseName.ToLower()
        Write-Host ('[PSAKE Docs] TOC: {0}' -f $line) -ForegroundColor 'DarkMagenta'
        $allLines.Add($line) | Out-Null
    }

    # Create Header/Intro
    $allLines.Add('') | Out-Null
    $allLines | Out-File -LiteralPath $FunctionsMD.FullName -Encoding 'utf8' -Force

    # Add MDs
    foreach ($md in $mds) {
        @(
            ''
            '***'
            ''
        ) | Out-File -LiteralPath $FunctionsMD.FullName -Encoding 'utf8' -Append -Force

        Write-Host ('[PSAKE Docs] Adding: {0}' -f ($md.FullName | ConvertTo-Json)) -ForegroundColor 'DarkMagenta'
        $allLines = foreach ($line in (Get-Content $md.FullName)) {
            if ($line.Trim() -eq '## SYNOPSIS') {
                # Don't add "SYNOPSIS" header.
                # Ref: https://apastyle.apa.org/style-grammar-guidelines/paper-format/headings#:~:text=Headings%20in%20the%20introduction
                Write-Host ('[PSAKE Docs] Removing: {0}' -f $line) -ForegroundColor 'DarkMagenta'
            } elseif (($line.Trim() -eq '## OUTPUTS') -or $inOutputs) {
                if ($inOutputs) {
                    if ($line.Trim().StartsWith('## ')) {
                        $inOutputs = $false
                        Write-Output $line
                    } elseif ($line.Trim().StartsWith('### ')) {
                        Write-Host ('[PSAKE Docs] Editing:{1}{0}' -f $line, "`t") -ForegroundColor 'DarkMagenta'
                        $newline = '`{0}`' -f $line.Trim().Substring(4)
                        Write-Host ('{1}{1}>>{1}{0}' -f $newline, "`t") -ForegroundColor 'DarkMagenta'
                        Write-Output $newline
                    }
                } else {
                    $inOutputs = $true
                    Write-Output $line
                }
            } elseif (($line.Trim() -eq '### EXAMPLE') -or $inExample) {
                if ($inExample) {
                    if ($line.Trim().StartsWith('```')) {
                        Write-Host ('[PSAKE Docs] Editing:{1}{0}' -f $line, "`t") -ForegroundColor 'DarkMagenta'
                        $newline = '```powershell'
                        Write-Host ('{1}{1}>>{1}{0}' -f $newline, "`t") -ForegroundColor 'DarkMagenta'
                        Write-Output $newline
                        $inExample = $false
                    }
                } else {
                    $inExample = $true
                    Write-Output $line
                }
            } elseif ($line -match '\\([[\]`\>])') {
                # https://regex101.com/r/pBXaJE/3
                Write-Host ('[PSAKE Docs] Editing:{1}{0}' -f $line, "`t") -ForegroundColor 'DarkMagenta'
                $newline = $line -replace '\\([[\]`\>])', '$1'
                Write-Host ('{1}{1}>>{1}{0}' -f $newline, "`t") -ForegroundColor 'DarkMagenta'
                Write-Output $newline
            } else {
                Write-Output $line
            }
        }
        $allLines | Out-File -LiteralPath $FunctionsMD.FullName -Encoding 'utf8' -Append -Force
    }

    $configs = @(
        'Push-Location "{0}"' -f $FunctionsMD.Directory.FullName
        '& git commit -a -m "Functions.md v{0}"' -f $env:APPVEYOR_BUILD_VERSION
        '& git push'
        'Pop-Location'
    )
    foreach ($config in $configs) {
        Write-Host ('PS > {0}' -f ($config -f $global:gitFormatters)).Replace($env:GITHUB_PERSONAL_ACCESS_TOKEN, '********')
        if ($env:CI) {
            Invoke-Config -Config $config
        } else {
            Write-Warning '[PSAKE Docs] Previous command skipped; not in CI.'
        }
    }
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
                    OutputPath = [IO.Path]::Combine($script:psScriptRootParent.FullName, 'dev', 'testResults.xml')
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
    Push-Location $script:dev.FullName
    & ([IO.Path]::Combine($script:dev.FullName, 'codecov.exe'))
    Pop-Location
}

task GitHubTagDelete {
    Write-Host ('[PSAKE GitHubTagDelete] APPVEYOR_REPO_TAG: {0}' -f $env:APPVEYOR_REPO_TAG)

    if ($env:APPVEYOR_REPO_TAG -eq 'true') {
        Write-Host ('[PSAKE GitHubTagDelete] APPVEYOR_REPO_TAG_NAME: {0}' -f $env:APPVEYOR_REPO_TAG_NAME)

        # https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#get-a-release-by-tag-name
        $webRequest = @{
            Uri = 'https://api.github.com/repos/{0}/releases/tags/{1}' -f $env:APPVEYOR_REPO_NAME, $env:APPVEYOR_REPO_TAG_NAME
            Method = 'Get'
            Headers = @{
                Accept = 'application/vnd.github+json'
                Authorization = 'Bearer {0}' -f $env:GITHUB_PERSONAL_ACCESS_TOKEN
                'X-GitHub-Api-Version' = '2022-11-28'
            }
        }
        Write-Host ('[PSAKE GitHubTagDelete] Invoke-RestMethod: {0}' -f ($webRequest | ConvertTo-Json).Replace($env:GITHUB_PERSONAL_ACCESS_TOKEN, '********')) -ForegroundColor 'DarkMagenta'
        $release = Invoke-RestMethod @webRequest
        Write-Host ('[PSAKE GitHubTagDelete] Release ID: {0}; Commit: {1}' -f $release.id, $release.target_commitish) -ForegroundColor 'DarkMagenta'

        Write-Host 'Git Config' -ForegroundColor 'Black' -BackgroundColor 'DarkCyan'
        $configs = @(
            '& git remote rm origin'
            '& git remote add origin "https://{0}:x-oauth-basic@github.com/{1}.git"'
            '& git config --global user.name "VertigoBot"'
            '& git config --global user.email "VertigoBot@80.vertigion.com"'
        )
        foreach ($config in $configs) {
            Write-Host ('PS > {0}' -f ($config -f $global:gitFormatters)).Replace($env:GITHUB_PERSONAL_ACCESS_TOKEN, '********')
            Invoke-Config -Config $config
        }

        Write-Host ('Git Delete Tag: {0}' -f $env:APPVEYOR_REPO_TAG_NAME) -ForegroundColor 'Black' -BackgroundColor 'DarkCyan'
        $configs = @(
            '& git pull origin master'
            '& git push --set-upstream origin :refs/tags/{2}'
        )
        foreach ($config in $configs) {
            Write-Host ('PS > {0}' -f ($config -f $global:gitFormatters)).Replace($env:GITHUB_PERSONAL_ACCESS_TOKEN, '********')
            Invoke-Config -Config $config
        }

        # https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#delete-a-release
        $webRequest = @{
            Uri = 'https://api.github.com/repos/{0}/releases/{1}' -f $env:APPVEYOR_REPO_NAME, $release.id
            Method = 'Delete'
            Headers = @{
                Accept = 'application/vnd.github+json'
                Authorization = 'Bearer {0}' -f $env:GITHUB_PERSONAL_ACCESS_TOKEN
                'X-GitHub-Api-Version' = '2022-11-28'
            }
        }
        Write-Host ('[PSAKE GitHubTagDelete] Invoke-RestMethod: {0}' -f ($webRequest | ConvertTo-Json).Replace($env:GITHUB_PERSONAL_ACCESS_TOKEN, '********')) -ForegroundColor 'DarkMagenta'
        Invoke-RestMethod @webRequest
    }
}

task RegisterProGet {
    $registerPSRepo = @{
        Name = 'PowerShell-ESE'
        SourceLocation = $env:PROGET_POWERSHELL_ESE_URL
        PublishLocation = $env:PROGET_POWERSHELL_ESE_URL
    }
    if (-not (Get-PSRepository $registerPSRepo.Name -ErrorAction 'Ignore')) {
        Write-Host "[PSAKE DeployProGet] Register-PSRepository: $($registerPSRepo | ConvertTo-Json)" -ForegroundColor 'DarkMagenta'
        Register-PSRepository @registerPSRepo
    }
}

task DeployProGet -Depends RegisterProGet {
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
    Write-Host ('[PSAKE DeployPSGallery] Get-Module PowerShellGet,PowerShellManagement: {0}' -f (Get-Module PowerShellGet,PowerShellManagement))
    Write-Host ('[PSAKE DeployPSGallery] Get-Module PowerShellGet,PowerShellManagement -ListAvailable: {0}' -f (Get-Module PowerShellGet,PowerShellManagement -ListAvailable))

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
