<#
.SYNOPSIS
Executes msiexec.exe to perform the following actions for MSI & MSP files and MSI product codes: install, uninstall, patch, repair, active setup.
.DESCRIPTION
Executes msiexec.exe to perform the following actions for MSI & MSP files and MSI product codes: install, uninstall, patch, repair, active setup.
If the -Action parameter is set to "Install" and the MSI is already installed, the function will exit.
Sets default switches to be passed to msiexec based on the preferences in the XML configuration file.
Automatically generates a log file name and creates a verbose log file for all msiexec operations.
Expects the MSI or MSP file to be located in the "Files" sub directory of the App Deploy Toolkit. Expects transform files to be in the same directory as the MSI file.
.PARAMETER Action
The action to perform. Options: Install, Uninstall, Patch, Repair, ActiveSetup.
.PARAMETER Path
The path to the MSI/MSP file or the product code of the installed MSI.
.PARAMETER Transforms
The name of the transform file(s) to be applied to the MSI. Relational paths from the working dir, then the MSI are looked for ... in that order.
Multiple transforms can be specified; separated by a comma.
.PARAMETER Patches
The name of the patch (msp) file(s) to be applied to the MSI for use with the "Install" action. The patch file is expected to be in the same directory as the MSI file.
.PARAMETER MsiDisplay
Overrides the default MSI Display Settings.
Default: $global:Winstall.Settings.Functions.InvokeMSI.Display
.PARAMETER Parameters
Overrides the default parameters specified in the XML configuration file. Install default is: "REBOOT=ReallySuppress /QB!". Uninstall default is: "REBOOT=ReallySuppress /QN".
.PARAMETER SecureParameters
Hides all parameters passed to the MSI or MSP file from the toolkit Log file.
.PARAMETER LoggingOptions
Overrides the default logging options specified in the XML configuration file. Default options are: "/log" (aka: "/L*v")
.PARAMETER WorkingDirectory
Overrides the working directory. The working directory is set to the location of the MSI file.
.PARAMETER SkipMSIAlreadyInstalledCheck
Skips the check to determine if the MSI is already installed on the system. Default is: $false.
.PARAMETER PassThru
Returns ExitCode, StdOut, and StdErr output from the process.
.PARAMETER LogFileF
When using [Redstone], this will be overridden via $PSDefaultParameters.
Default: $global:Winstall.Settings.Logs.PathF
.EXAMPLE
# Installs an MSI
Invoke-RedstoneMSI -Action 'Install' -Path 'Adobe_FlashPlayer_11.2.202.233_x64_EN.msi'
.EXAMPLE
# Installs an MSI, applying a transform and overriding the default MSI toolkit parameters
Invoke-RedstoneMSI -Action 'Install' -Path 'Adobe_FlashPlayer_11.2.202.233_x64_EN.msi' -Transform 'Adobe_FlashPlayer_11.2.202.233_x64_EN_01.mst' -Parameters '/QN'
.EXAMPLE
# Installs an MSI and stores the result of the execution into a variable by using the -PassThru option
[psobject] $ExecuteMSIResult = Invoke-RedstoneMSI -Action 'Install' -Path 'Adobe_FlashPlayer_11.2.202.233_x64_EN.msi' -PassThru
.EXAMPLE
# Uninstalls an MSI using a product code
Invoke-RedstoneMSI -Action 'Uninstall' -Path '{26923b43-4d38-484f-9b9e-de460746276c}'
.EXAMPLE
# Installs an MSP
Invoke-RedstoneMSI -Action 'Patch' -Path 'Adobe_Reader_11.0.3_EN.msp'
.EXAMPLE
$msi = @{
    Action = 'Install'
    Parameters = @(
        'USERNAME="{0}"' -f $settings.Installer.UserName
        'COMPANYNAME="{0}"' -f $settings.Installer.CompanyName
        'SERIALNUMBER="{0}"' -f $settings.Installer.SerialNumber
    )
}

if ([Environment]::Is64BitOperatingSystem) {
    Invoke-RedstoneMSI @msi -Path 'Origin2016Sr2Setup32and64Bit.msi'
} else {
    Invoke-RedstoneMSI @msi -Path 'Origin2016Sr2Setup32Bit.msi'
}
.NOTES
.LINK
http://psappdeploytoolkit.com
#>
function Invoke-RedstoneMSI {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false)]
        [ValidateSet('Install','Uninstall','Patch','Repair','ActiveSetup')]
        [string]
        $Action = 'Install',

        [Parameter(Position=0, Mandatory=$true, HelpMessage='Please enter either the path to the MSI/MSP file or the ProductCode')]
        [ValidateNotNullorEmpty()]
        [Alias('FilePath')]
        [string]
        $Path,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string[]]
        $Transforms,

        [Parameter(Mandatory=$false)]
        [Alias('Arguments')]
        [ValidateNotNullorEmpty()]
        [string[]]
        $Parameters = @('REBOOT=ReallySuppress'),

        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [switch]
        $SecureParameters = $false,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string[]]
        $Patches,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string]
        $LoggingOptions = '/log',

        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string]
        $WorkingDirectory,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [switch]
        $SkipMSIAlreadyInstalledCheck = $false,

        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string]
        $MsiDisplay = '/qn',

        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [string]
        $WindowStyle = 'Hidden',

        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [switch]
        $PassThru,

        [Parameter(Mandatory=$false, HelpMessage='When using [Redstone], this will be overridden via $PSDefaultParameters.')]
        [ValidateNotNullorEmpty()]
        [string]
        $LogFileF = "${env:Temp}\{Invoke-RedstoneMsi_{1}_{0}.log"
    )

    Write-Verbose "[Invoke-RedstoneMsi] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
    Write-Debug "[Invoke-RedstoneMsi] Function Invocation: $($MyInvocation | Out-String)"


    ## Initialize variable indicating whether $Path variable is a Product Code or not
    $PathIsProductCode = ($Path -as [guid]) -as [bool]

    ## Build the MSI Parameters
    switch ($Action) {
        'Install' {
            $option = '/i'
            $msiDefaultParams = $MsiDisplay
        }
        'Uninstall' {
            $option = '/x'
            $msiDefaultParams = $MsiDisplay
        }
        'Patch' {
            $option = '/update'
            $msiDefaultParams = $MsiDisplay
        }
        'Repair' {
            $option = '/f'
            $msiDefaultParams = $MsiDisplay
        }
        'ActiveSetup' {
            $option = '/fups'
        }
    }

    ## If the MSI is in the Files directory, set the full path to the MSI
    if ($PathIsProductCode) {
        [string] $msiFile = $Path
        [string] $msiLogFile = $LogsPathF -f ".msi.${Action}", ($Path -as [guid]).Guid
    } else {
        [string] $msiFile = (Resolve-Path $Path -ErrorAction 'Stop').Path
        [string] $msiLogFile = $LogsPathF -f ".msi.${Action}", ($Path -as [IO.FileInfo]).BaseName
    }

    ## Set the working directory of the MSI
    if ((-not $PathIsProductCode) -and (-not $workingDirectory)) {
        [string] $workingDirectory = Split-Path -Path $msiFile -Parent
    }

    ## Enumerate all transforms specified, qualify the full path if possible and enclose in quotes
    [System.Collections.ArrayList] $mst = @()
    foreach ($transform in $Transforms) {
        try {
            $mst = Resolve-Path $transform -ErrorAction 'Stop'
        } catch [System.Management.Automation.ItemNotFoundException] {
            if ($workingDirectory) {
                $mst.Add((Join-Path "${workingDirectory}\${transform}" -Resolve -ErrorAction 'Stop')) | Out-Null
            } else {
                $mst.Add($transform) | Out-Null
            }
        }
    }
    [string] $mstFile = "`"$($mst -join ';')`""

    ## Enumerate all patches specified, qualify the full path if possible and enclose in quotes
    [System.Collections.ArrayList] $msp = @()
    foreach ($patch in $Patches) {
        try {
            $msp = Resolve-Path $patch -ErrorAction 'Stop'
        } catch [System.Management.Automation.ItemNotFoundException] {
            if ($workingDirectory) {
                $msp.Add((Join-Path "${workingDirectory}\${patch}" -Resolve -ErrorAction 'Stop')) | Out-Null
            } else {
                $msp.Add($patch) | Out-Null
            }
        }
    }
    [string] $mspFile = "`"$($msp -join ';')`""

    ## Get the ProductCode of the MSI
    if ($PathIsProductCode) {
        [string] $MSIProductCode = $Path
    } elseif ([IO.Path]::GetExtension($msiFile) -eq '.msi') {
        try {
            [hashtable] $Get_MsiTablePropertySplat = @{
                'Path'              = $msiFile;
                'Table'             = 'Property';
                'ContinueOnError'   = $false;
            }
            if ($mst) {
                $Get_MsiTablePropertySplat.Add('TransformPath', $mst)
            }

            [string] $MSIProductCode = Get-MsiTableProperty @Get_MsiTablePropertySplat | Select-Object -ExpandProperty 'ProductCode' -ErrorAction 'Stop'
            Write-Information "[Invoke-RedstoneMsi] Got the ProductCode from the MSI file: ${MSIProductCode}"
        } catch {
            Write-Information "[Invoke-RedstoneMsi] Failed to get the ProductCode from the MSI file. Continuing with requested action [${Action}].$([Environment]::NewLine)$([Environment]::NewLine)$_"
        }
    }

    ## Start building the MsiExec command line starting with the base action and file
    [System.Collections.ArrayList] $argsMSI = @()
    if ($msiDefaultParams) {
        $argsMSI.Add($msiDefaultParams) | Out-Null
    }
    $argsMSI.Add($option) | Out-Null
    ## Enclose the MSI file in quotes to avoid issues with spaces when running msiexec
    $argsMSI.Add("`"${msiFile}`"") | Out-Null
    if ($Transforms) {
        $argsMSI.Add("TRANSFORMS=${mstFile}") | Out-Null
        $argsMSI.Add("TRANSFORMSSECURE=1") | Out-Null
    }
    if ($Patches) {
        $argsMSI.Add("PATCH=${mspFile}") | Out-Null
    }
    if ($Parameters) {
        foreach ($param in $Parameters) {
            $argsMSI.Add($param) | Out-Null
        }
    }
    $argsMSI.Add($LoggingOptions) | Out-Null
    $argsMSI.Add("`"$msiLogFile`"") | Out-Null

    ## Check if the MSI is already installed. If no valid ProductCode to check, then continue with requested MSI action.
    [boolean] $IsMsiInstalled = $false
    if ($MSIProductCode -and (-not $SkipMSIAlreadyInstalledCheck)) {
        [psobject] $MsiInstalled = Get-InstalledApplication -ProductCode $MSIProductCode
        if ($MsiInstalled) {
            [boolean] $IsMsiInstalled = $true
        }
    } else {
        if ($Action -ine 'Install') {
            [boolean] $IsMsiInstalled = $true
        }
    }

    if ($IsMsiInstalled -and ($Action -ieq 'Install')) {
        Write-Information "[Invoke-RedstoneMsi] The MSI is already installed on this system. Skipping action [${Action}]..."
    } elseif ($IsMsiInstalled -or ((-not $IsMsiInstalled) -and ($Action -eq 'Install'))) {
        Write-Information "[Invoke-RedstoneMsi] Executing MSI action [${Action}]..."

        #  Build the hashtable with the options that will be passed to Invoke-Run using splatting
        [hashtable] $invokeRun =  @{
            'FilePath' = (Get-Command 'msiexec' -ErrorAction 'Stop').Source;
            'ArgumentList' = $argsMSI;
            'PassThru' = $PassThru;
        }
        if ($WorkingDirectory) {
            $invokeRun.Add( 'WorkingDirectory', $WorkingDirectory)
        }


        ## If MSI install, check to see if the MSI installer service is available or if another MSI install is already underway.
        ## Please note that a race condition is possible after this check where another process waiting for the MSI installer
        ##  to become available grabs the MSI Installer mutex before we do. Not too concerned about this possible race condition.
        [boolean] $msiExecAvailable = Assert-RedstoneIsMutexAvailable -MutexName 'Global\_MSIExecute'
        Start-Sleep -Seconds 1
        if (-not $msiExecAvailable) {
            #  Default MSI exit code for install already in progress
            Write-Warning '[Invoke-RedstoneMsi] Please complete in progress MSI installation before proceeding with this install.'
            $msg = Get-RedstoneMsiExitCodeMessage 1618
            Write-Error "[Invoke-RedstoneMsi] 1618: ${msg}"
            & $Redstone.Quit 1618 $false
        }


        #  Call the Invoke-Run function
        if ($PassThru) {
            $result = Invoke-RedstoneRun @invokeRun
            if ($result.Process.ExitCode -ne 0) {
                $Redstone.ExitCode = $result.Process.ExitCode
                $msg = Get-RedstoneMsiExitCodeMessage $Redstone.ExitCode -MsiLog $msiLogFile
                Write-Warning "[Invoke-RedstoneMsi] $($result.Process.ExitCode): ${msg}"
            }
            Write-Information "[Invoke-RedstoneMsi] Return: $($result | Out-String)"
            return $result
        } else {
            Invoke-RedstoneRun @invokeRun
        }
    } else {
        Write-Warning "[Invoke-RedstoneMsi] The MSI is not installed on this system. Skipping action [${Action}]..."
    }
}
