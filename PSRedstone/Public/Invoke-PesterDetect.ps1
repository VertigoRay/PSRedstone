<#
.SYNOPSIS
Run a scriptblock that contains Pester tests that can be used for MECM Application Detection.
.DESCRIPTION

```powershell
$ppv = 'VertigoRay Assert-IsElevated 1.2.3'
$sb = {
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
$params = @{
    FunctionName = 'Assert-IsElevated'
}
Invoke-PesterDetect -PesterScriptBlock $sb -PesterScriptBlockParam $params -PublisherProductVersion $ppv
```
.PARAMETER PesterScriptBlock
Pass in a ScriptBlock that contains a fully functional Pester  test.
Here's a simple example of creating the ScriptBlock:

```powershell
$sb = {
    Describe 'Assert-IsElevated' {
        It 'Return Boolean' {
            {
                Assert-IsElevated | Should -BeOfType 'System.Boolean'
            } | Should -Not -Throw
        }
    }
}
Invoke-PesterDetect -PesterScriptBlock $sb
```
.PARAMETER PesterScriptBlockParam
This allows you to pass parameters into your ScriptBlock.
Here's a simple example of creating the ScriptBlock with a parameter and passing a value into it.
This PowerShell code is functionally identical to the code in the `PesterScriptBlock` parameter.:

```powershell
$sb = {
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
$params = @{
    FunctionName = 'Assert-IsElevated'
}
Invoke-PesterDetect -PesterScriptBlock $sb -PesterScriptBlockParam $params
```
.PARAMETER PublisherProductVersion
This a string containing the Publisher, Product, and Version separated by spaces.

```powershell
$PublisherProductVersion = "$($settings.Publisher) $($settings.Product) $($settings.Version)"
```

Really, you can provide whatever you want here, whatever you provide will be put on the end of a successful detection message.
For example, if you set this to "Peanut Brittle" because you think it's amusing, your successful detection message will be:

> Detection SUCCESSFUL: Peanut Brittle
.PARAMETER DevMode
This script allows additional output when you're in you development environment.
This is important to address because detections scripts have [very strict StdOut requirements](https://learn.microsoft.com/en-us/previous-versions/system-center/system-center-2012-R2/gg682159(v=technet.10)#to-use-a-custom-script-to-determine-the-presence-of-a-deployment-type).

```powershell
$devMode = if ($MyInvocation.MyCommand.Name -eq 'detect.ps1') { $true } else { $false }
```

This example assumes that in your development environment, you've named your detections script `detect.ps1`.
This is the InvocationName when we running the dev version of the script, like in Windows Sandbox.
When SCCM calls detection, the detection script is put in a file named as a guid.
    i.e. fae94777-2c0d-4dd0-94f0-407f7cd07858.ps1
.EXAMPLE
Invoke-PesterDetect -PesterScriptBlock $sb -PesterScriptBlockParam $params -PublisherProductVersion $ppv

This will run the PowerShell code block below returning ONLY the `Detection SUCCESSFUL` message if the detection was successful.

```text
Detection SUCCESSFUL: VertigoRay Assert-IsElevated 1.2.3
```

It will return nothing if the detection failed.
If you want to see where detection is failing, add the `DevMode` parameter.

**Note**: if your want to see what the variables are set to, take a look at the *Description*.
.EXAMPLE
Invoke-PesterDetect -PesterScriptBlock $sb -PesterScriptBlockParam $params -PublisherProductVersion $ppv -DevMode

This will the pass with verbose output.

```text
Pester v5.3.3

Starting discovery in 1 files.
Discovery found 1 tests in 25ms.
Running tests.
Describing Assert-IsElevated
  [+] Return Boolean 26ms (15ms|11ms)
Tests completed in 174ms
Tests Passed: 1, Failed: 0, Skipped: 0 NotRun: 0
Detection SUCCESSFUL: VertigoRay Assert-IsElevated 1.2.3
```

**Note**: if your want to see what the variables are set to, take a look at the *Description*.
.EXAMPLE
Invoke-PesterDetect -PesterScriptBlock $sb -PesterScriptBlockParam @{ FunctionName = 'This-DoesNotExist' } -PublisherProductVersion $ppv -DevMode

This will fail with verbose output.
This is useful in development, but you wouldn't want to send this to production.
The reason is described in the `DevMode` parameter section.

```text
Pester v5.4.0

Starting discovery in 1 files.
Discovery found 1 tests in 48ms.
Running tests.
Describing This-DoesNotExist
  [-] Return Boolean 250ms (241ms|9ms)
   Expected no exception to be thrown, but an exception "The term 'This-DoesNotExist' is not recognized as the name of a cmdlet, function, script file, or operable program. Check the spelling of the name, or if a path was included, verify that the path is correct and try again." was thrown from line:12 char:19
       +                 & $FunctionName | Should -BeOfType 'System.Boolean'
       +                   ~~~~~~~~~~~~~.
   at } | Should -Not -Throw, :13
   at <ScriptBlock>, <No file>:11
Tests completed in 593ms
Tests Passed: 0, Failed: 1, Skipped: 0 NotRun: 0
WARNING: [DEV MODE] Detection FAILED: VertigoRay Assert-IsElevated 1.2.3
```

**Note**: if your want to see what the variables are set to, take a look at the *Description*.
#>
function Invoke-PesterDetect {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]
        $PesterScriptBlock,

        [Parameter()]
        [hashtable]
        $PesterScriptBlockParam = @{},

        [Parameter(HelpMessage = '"$($settings.Publisher) $($settings.Product) $($settings.Version)"')]
        [string]
        $PublisherProductVersion = ':)',

        [Parameter()]
        [switch]
        $DevMode
    )

    $PesterPreference = [PesterConfiguration] @{
        Output = @{
            Verbosity = if ($DevMode) { 'Detailed' } else { 'None' }
        }
    }
    $container = New-PesterContainer -ScriptBlock $PesterScriptBlock -Data $PesterScriptBlockParam
    $testResults = Invoke-Pester -Container $container -PassThru

    if ($DevMode) {
        Write-Debug ('[Invoke-PesterDetect][DEV MODE] testResults: {0}' -f ($testResults | Out-String))
    }

    if ($testResults.Result -eq 'Passed') {
        Write-Output ('Detection SUCCESSFUL: {0}' -f $PublisherProductVersion)
    } elseif ($DevMode) {
        Write-Warning ('[Invoke-PesterDetect][DEV MODE] Detection FAILED: {0}' -f $PublisherProductVersion)
    }
}