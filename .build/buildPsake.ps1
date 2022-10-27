properties {
    $script:thisModuleName = 'PSBacon'
    $script:PSScriptRootParent = ([IO.DirectoryInfo] $PSScriptRoot).Parent
    $script:ManifestJsonFile = [IO.Path]::Combine($script:PSScriptRootParent.FullName, $script:thisModuleName, 'Manifest.json')
    $Script:BuildOutput = [IO.Path]::Combine($script:PSScriptRootParent.FullName, 'dev', 'BuildOutput')

    $script:ParentDevModulePath = [IO.Path]::Combine($script:PSScriptRootParent.FullName, $script:thisModuleName)
    $script:ParentModulePath = [IO.Path]::Combine($Script:BuildOutput, $script:thisModuleName)

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
    $manifestJsonData = Get-Content $script:ManifestJsonFile | ConvertFrom-Json
    Write-Host "[PSAKE BuildManifest] manifestJsonData: $($manifestJsonData | ConvertTo-Json)" -ForegroundColor 'DarkMagenta'
    $manifestJsonData.PSObject.Properties | ForEach-Object {
        $Manifest.Set_Item($_.Name, $_.Value)
    }

    $Manifest.Copyright = $Manifest.Copyright -f [DateTime]::Now.Year
    Write-Verbose ('$script:ParentDevModulePath: {0}' -f $script:ParentDevModulePath)
    $Manifest.CmdletsToExport = (Get-ChildItem -Path ([IO.Path]::Combine($script:ParentDevModulePath, 'Public', '*.ps1')) -ErrorAction SilentlyContinue).BaseName

    $Manifest.Remove('ModuleName')

    $Manifest.Path = "${ParentModulePath}\${thisModuleName}.psd1"
    $Manifest.ModuleVersion = [version] $Version
    Write-Host "[PSAKE BuildManifest] New-ModuleManifest: $($Manifest | ConvertTo-Json)" -ForegroundColor 'DarkMagenta'
    New-ModuleManifest @Manifest
}

task Build -Depends BuildManifest {
    $copyItem = @{
        LiteralPath = [IO.Path]::Combine($script:ParentDevModulePath, ('{0}.psm1' -f $thisModuleName))
        Destination = $script:ParentModulePath
        Force       = $true
    }
    Write-Host "[PSAKE Build] Copy-Item: $($copyItem | ConvertTo-Json)" -ForegroundColor 'DarkMagenta'
    Copy-Item @copyItem

    foreach ($directory in (Get-ChildItem ([IO.Path]::Combine($script:PSScriptRootParent.FullName, $script:thisModuleName)) -Directory)) {
        $copyItem = @{
            LiteralPath = $directory.FullName
            Destination = $script:ParentModulePath
            Recurse     = $true
            Force       = $true
        }
        Write-Host "[PSAKE Build] Copy-Item: $($copyItem | ConvertTo-Json)" -ForegroundColor 'DarkMagenta'
        Copy-Item @copyItem
    }
}

task PostAnalyze {
    $saResults = Invoke-ScriptAnalyzer -Path ([IO.Path]::Combine($Script:BuildOutput, $script:thisModuleName)) -Severity @('Error', 'Warning') -Recurse -Verbose:$false
    if ($saResults) {
        $saResults | Format-Table
        Write-Error -Message 'One or more Script Analyzer errors/warnings where found. Build cannot continue!'
    }
}

task Test {
    $testResults = Invoke-Pester -Path $PSScriptRoot -PassThru
    if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message 'One or more Pester tests failed. Build cannot continue!'
    }
}

task Deploy -depends Analyze, Test {
    Invoke-PSDeploy -Path '.\ServerInfo.psdeploy.ps1' -Force -Verbose:$VerbosePreference
}