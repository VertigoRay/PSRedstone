#region DEVONLY
. "${PSScriptRoot}\..\Public\Assert-BaconIsElevated.ps1"
. "${PSScriptRoot}\..\Public\Get-BaconRegistryValueOrDefault.ps1"
# . "${PSScriptRoot}\..\Public\Get-BaconRegistryValueDoNotExpandEnvironmentNames.ps1"
#endregion


class Bacon {
    hidden [string] $_Publisher = $null
    hidden [string] $_Product = $null
    hidden [string] $_Version = $null
    hidden [string] $_Action = $null
    hidden [hashtable] $_CimInstance = $null
    hidden [hashtable] $_Env = $null
    hidden [hashtable] $_OS = $null
    hidden [hashtable] $_ProfileList = $null
    [string] $ExitCode = 0
    [System.Collections.ArrayList] $Exiting = @()
    [hashtable] $Settings = @{}
    [bool] $IsElevated = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    # Use the default settings, don't read any of the settings in from the registry. In production this is never set.
    [bool] $OnlyUseDefaultSettings = $false
    [hashtable] $Debug = @{
        MyInvocation = $MyInvocation
        PSCallStack = (Get-PSCallStack)
    }

    static Bacon() {
        # Creating some custom setters that update other properties, like Log Paths, when related properties are changed.
        Update-TypeData -TypeName 'Bacon' -MemberName 'Publisher' -MemberType 'ScriptProperty' -Value {
            # Getter
            return $this._Publisher
        } -SecondValue {
            param($value)
            # Setter
            $this._Publisher = $value
            $this.SetUpLog()
        } -Force
        Update-TypeData -TypeName 'Bacon' -MemberName 'Product' -MemberType 'ScriptProperty' -Value {
            # Getter
            return $this._Product
        } -SecondValue {
            param($value)
            # Setter
            $this._Product = $value
            $this.SetUpLog()
        } -Force
        Update-TypeData -TypeName 'Bacon' -MemberName 'Version' -MemberType 'ScriptProperty' -Value {
            # Getter
            return $this._Version
        } -SecondValue {
            param($value)
            # Setter
            $this._Version = $value
            $this.SetUpLog()
        } -Force
        Update-TypeData -TypeName 'Bacon' -MemberName 'Action' -MemberType 'ScriptProperty' -Value {
            # Getter
            return $this._Action
        } -SecondValue {
            param($value)
            # Setter
            $this._Action = $value
            $this.SetUpLog()
        } -Force
        Update-TypeData -TypeName 'Bacon' -MemberName 'CimInstance' -MemberType 'ScriptProperty' -Value {
            # Getter
            $className = $MyInvocation.Line.Split('.')[2]
            return $this.GetCimInstance($className, $true)
        } -Force
        Update-TypeData -TypeName 'Bacon' -MemberName 'Env' -MemberType 'ScriptProperty' -Value {
            # Getter
            if (-not $this._Env) {
                # This is the Lazy Loading logic.
                $this.SetUpEnv()
            }
            return $this._Env
        } -Force
        Update-TypeData -TypeName 'Bacon' -MemberName 'OS' -MemberType 'ScriptProperty' -Value {
            # Getter
            if (-not $this._OS) {
                # This is the Lazy Loading logic.
                $this.SetUpOS()
            }
            return $this._OS
        } -Force
        Update-TypeData -TypeName 'Bacon' -MemberName 'ProfileList' -MemberType 'ScriptProperty' -Value {
            # Getter
            if (-not $this._ProfileList) {
                # This is the Lazy Loading logic.
                $this.SetUpProfileList()
            }
            return $this._ProfileList
        } -Force
    }

    Bacon() {
        $this.SetUpSettings()

        $this.Settings.JSON = @{}
        $this.Settings.JSON.File = [IO.FileInfo] ([IO.Path]::Combine($PWD, 'settings.json'))
        if ($this.Settings.JSON.File.Exists) {
            $this.Settings.JSON.Data = Get-Content $this.Settings.JSON.File.FullName | ConvertFrom-Json
        } else {
            $this.Settings.JSON.File = [IO.FileInfo] ([IO.Path]::Combine(([IO.FileInfo] $this.Debug.PSCallStack[1].ScriptName).Directory.FullName, 'settings.json'))
            if ($this.Settings.JSON.File.Exists) {
                $this.Settings.JSON.Data = Get-Content $this.Settings.JSON.File.FullName | ConvertFrom-Json
            } else {
                Throw [System.IO.FileNotFoundException] $this.Settings.JSON.File.FullName
            }
        }
        $_settings = $this.Settings.JSON.Data

        $this.SetDefaultSettingsFromRegistry($this.Settings.Registry.Key)
        $this.SetPSDefaultParameterValues($this.Settings.Functions)

        $this.set__Publisher($_settings.Publisher)
        $this.set__Product($_settings.Product)
        $this.set__Version($_settings.Version)
        $this.set__Action(([IO.FileInfo] $this.Debug.PSCallStack[1].ScriptName).BaseName)

        $this.SetUpLog()
    }

    Bacon([string] $Publisher, [string] $Product, [string] $Version, [string] $Action) {
        $this.SetUpSettings()
        $this.SetDefaultSettingsFromRegistry($this.Settings.Registry.Key)
        $this.SetPSDefaultParameterValues($this.Settings.Functions)

        $this.set__Publisher($Publisher)
        $this.set__Product($Product)
        $this.set__Version($Version)
        $this.set__Action($Action)

        $this.SetUpLog()
    }

    hidden [object] GetCimInstance($ClassName) {
        return $this.GetCimInstance($ClassName, $false, $false)
    }

    hidden [object] GetCimInstance($ClassName, $ReturnCimInstanceNotClass) {
        return $this.GetCimInstance($ClassName, $ReturnCimInstanceNotClass, $false)
    }

    hidden [object] GetCimInstance($ClassName, $ReturnCimInstanceNotClass, $Refresh) {
        # This is the Lazy Loading logic.
        if (-not $this._CimInstance) {
            $this._CimInstance = @{}
        }
        if ($Refresh -or ($ClassName -and -not $this._CimInstance.$ClassName)) {
            $this._CimInstance.Set_Item($ClassName, (Get-CimInstance -ClassName $ClassName -ErrorAction 'Ignore'))
        }
        if ($ReturnCimInstanceNotClass) {
            return $this._CimInstance
        } else {
            return $this._CimInstance.$ClassName
        }
    }

    [object] CimInstanceRefreshed($ClassName) {
        return $this.GetCimInstance($ClassName, $false, $true)
    }

    hidden [void] SetUpEnv() {
        # This section

        $this._Env = @{}
        if ([System.Environment]::Is64BitOperatingSystem) {
            # x64 OS
            if ([System.Environment]::Is64BitProcess) {
                # x64 Process
                $this._Env.CommonProgramFiles = $env:CommonProgramFiles
                $this._Env.'CommonProgramFiles(x86)' = ${env:CommonProgramFiles(x86)}
                $this._Env.ProgramFiles = $env:ProgramFiles
                $this._Env.'ProgramFiles(x86)' = ${env:ProgramFiles(x86)}
                $this._Env.System32 = "${env:SystemRoot}\System32"
                $this._Env.SysWOW64 = "${env:SystemRoot}\SysWOW64"
            } else {
                # Running as x86 on x64 OS
                $this._Env.CommonProgramFiles = $env:CommonProgramW6432
                $this._Env.'CommonProgramFiles(x86)' = ${env:CommonProgramFiles(x86)}
                $this._Env.ProgramFiles = $env:ProgramW6432
                $this._Env.'ProgramFiles(x86)' = ${env:ProgramFiles(x86)}
                $this._Env.System32 = "${env:SystemRoot}\SysNative"
                $this._Env.SysWOW64 = "${env:SystemRoot}\SysWOW64"
            }
        } else {
            # x86 OS
            $this._Env.CommonProgramFiles = $env:CommonProgramFiles
            $this._Env.'CommonProgramFiles(x86)' = $env:CommonProgramFiles
            $this._Env.ProgramFiles = $env:ProgramFiles
            $this._Env.'ProgramFiles(x86)' = $env:ProgramFiles
            $this._Env.System32 = "${env:SystemRoot}\System32"
            $this._Env.SysWOW64 = "${env:SystemRoot}\System32"
        }

        if ($env:PROCESSOR_ARCHITEW6432) {
            # Running as x86 on x64 OS
            $this._Env.PROCESSOR_ARCHITECTURE = $env:PROCESSOR_ARCHITEW6432
        } else {
            # x86 or x64
            $this._Env.PROCESSOR_ARCHITECTURE = $env:PROCESSOR_ARCHITECTURE
        }
    }

    hidden [void] SetUpLog() {
        $this.Settings.Log = @{}

        if (Assert-BaconIsElevated) {
            $private:Directory = [IO.DirectoryInfo] "${env:SystemRoot}\Logs\Bacon"
        } else {
            $private:Directory = [IO.DirectoryInfo] "${env:Temp}\Logs\Bacon"
        }

        if (-not $private:Directory.Exists) {
            New-Item -ItemType 'Directory' -Path $private:Directory.FullName -Force | Out-Null
            $private:Directory.Refresh()
        }

        $this.Settings.Log.File = [IO.FileInfo] (Join-Path $private:Directory.FullName ('{0} {1} {2} {3}.log' -f $this.Publisher, $this.Product, $this.Version, $this.Action))
        $this.Settings.Log.FileF = (Join-Path $private:Directory.FullName ('{0} {1} {2} {3}{{0}}.log' -f $this.Publisher, $this.Product, $this.Version, $this.Action)) -as [string]
        $this.PSDefaultParameterValuesSetUp()
    }

    hidden [void] SetUpSettings() {
        $this.Settings = @{}
        $this.Settings.Registry = @{
            Key = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\PSBacon'
        }
    }

    hidden [void] SetUpOS() {
        $this._OS = @{}
        [bool]   $this._OS.Is64BitOperatingSystem = [System.Environment]::Is64BitOperatingSystem
        [bool]   $this._OS.Is64BitProcess = [System.Environment]::Is64BitProcess

        [bool] $this._OS.Is64BitProcessor = ($this.GetCimInstance('Win32_Processor')| Where-Object { $_.DeviceID -eq 'CPU0' }).AddressWidth -eq '64'
        [bool]      $this._OS.IsMachinePartOfDomain = $this.GetCimInstance('Win32_ComputerSystem').PartOfDomain

        [string]    $this._OS.MachineWorkgroup = $null
        [string]    $this._OS.MachineADDomain = $null
        [string]    $this._OS.LogonServer = $null
        [string]    $this._OS.MachineDomainController = $null
        if ($this._OS.IsMachinePartOfDomain) {
            [string] $this._OS.MachineADDomain = $this.GetCimInstance('Win32_ComputerSystem').Domain | Where-Object { $_ } | ForEach-Object { $_.ToLower() }
            try {
                [string] $this._OS.LogonServer = $env:LOGONSERVER | Where-Object { (($_) -and (-not $_.Contains('\\MicrosoftAccount'))) } | ForEach-Object { $_.TrimStart('\') } | ForEach-Object { ([System.Net.Dns]::GetHostEntry($_)).HostName }
                [string] $this._OS.MachineDomainController = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().FindDomainController().Name
            } catch {
                Write-Verbose 'Not in AD'
            }
        } else {
            [string] $this._OS.MachineWorkgroup = $this.GetCimInstance('Win32_ComputerSystem').Domain | Where-Object { $_ } | ForEach-Object { $_.ToUpper() }
        }
        [string]    $this._OS.MachineDNSDomain = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().DomainName | Where-Object { $_ } | ForEach-Object { $_.ToLower() }
        [string]    $this._OS.UserDNSDomain = $env:USERDNSDOMAIN | Where-Object { $_ } | ForEach-Object { $_.ToLower() }
        [string]    $this._OS.UserDomain = $env:USERDOMAIN | Where-Object { $_ } | ForEach-Object { $_.ToUpper() }
        [string]    $this._OS.Name = $this.GetCimInstance('Win32_OperatingSystem').Name.Trim()
        [string]    $this._OS.ShortName = (($this._OS.Name).Split('|')[0] -replace '\w+\s+(Windows [\d\.]+\s+\w+)', '$1').Trim()
        [string]    $this._OS.ShorterName = (($this._OS.Name).Split('|')[0] -replace '\w+\s+(Windows [\d\.]+)\s+\w+', '$1').Trim()
        [string]    $this._OS.ServicePack = $this.GetCimInstance('Win32_OperatingSystem').CSDVersion
        [version]   $this._OS.Version = [System.Environment]::OSVersion.Version
        #  Get the operating system type
        [int32]     $this._OS.ProductType = $this.GetCimInstance('Win32_OperatingSystem').ProductType
        [bool]      $this._OS.IsServerOS = [bool]($this._OS.ProductType -eq 3)
        [bool]      $this._OS.IsDomainControllerOS = [bool]($this._OS.ProductType -eq 2)
        [bool]      $this._OS.IsWorkStationOS = [bool]($this._OS.ProductType -eq 1)
        Switch ($this._OS.ProductType) {
            1       { [string] $this._OS.ProductTypeName = 'Workstation' }
            2       { [string] $this._OS.ProductTypeName = 'Domain Controller' }
            3       { [string] $this._OS.ProductTypeName = 'Server' }
            Default { [string] $this._OS.ProductTypeName = 'Unknown' }
        }
    }

    hidden [void] SetUpProfileList() {
        Write-Debug 'GETTER: ProfileList'
        if (-not $this._ProfileList) {
            Write-Debug 'GETTER: Setting up ProfileList'
            $this._ProfileList = @{}
            $regProfileListPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
            $regProfileList = Get-Item $regProfileListPath
            foreach ($property in $regProfileList.Property) {
                $this._ProfileList.Add($property, (Get-ItemProperty -Path $regProfileListPath).$property)
            }

            [System.Collections.ArrayList] $this._ProfileList.Profiles = @()
            foreach ($userProfile in (Get-ChildItem $regProfileListPath)) {
                [hashtable] $user = @{}
                $user.Add('SID', $userProfile.PSChildName)
                $user.Add('Path', (Get-ItemProperty "${regProfileListPath}\$($userProfile.PSChildName)").ProfileImagePath)
                $objSID = New-Object System.Security.Principal.SecurityIdentifier($user.SID)
                try {
                    $objUser = $objSID.Translate([System.Security.Principal.NTAccount])
                    $domainUsername = $objUser.Value
                } catch [System.Management.Automation.MethodInvocationException] {
                    Write-Warning "Unable to translate the SID ($($user.SID)) to a Username."
                    $domainUsername = $null
                }

                $domain, $username = $domainUsername.Split('\')
                try {
                    $user.Add('Domain', $domain.Trim())
                } catch {
                    $user.Add('Domain', $null)
                }
                try {
                    $user.Add('Username', $username.Trim())
                } catch {
                    $user.Add('Username', $domainUsername)
                }
                ($this._ProfileList.Profiles).Add($user) | Out-Null
            }
        }
    }

    hidden [void] SetUpVars() {
        $this.SetUpOS()
        $this.SetUpEnv()
    }

    hidden [void] PSDefaultParameterValuesSetUp() {
        $global:PSDefaultParameterValues.Set_Item('*-Bacon*:LogFile', $this.Settings.Log.File.FullName)
        $global:PSDefaultParameterValues.Set_Item('*-Bacon*:LogFileF', $this.Settings.Log.FileF)
        $global:PSDefaultParameterValues.Set_Item('*-Bacon*:LogFileF', $this.Settings.Log.FileF)
        $global:PSDefaultParameterValues.Set_Item('Get-BaconRegistryValueOrDefault:OnlyUseDefaultSettings', (Get-BaconRegistryValueOrDefault 'Settings\Functions\Get-BaconRegistryValueOrDefault' 'OnlyUseDefaultSettings' $false -RegistryKeyRoot $this.Settings.Registry.Key))
        $global:PSDefaultParameterValues.Set_Item('Get-BaconRegistryValueOrDefault:RegistryKeyRoot', $this.Settings.Registry.Key)
        $global:PSDefaultParameterValues.Set_Item('Write-Log:FilePath', $this.Settings.Log.File.FullName)
    }

    hidden [psobject] GetRegOrDefault($RegistryKey, $RegistryValue, $DefaultValue) {
        Write-Verbose "[Bacon GetRegOrDefault] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
        Write-Debug "[Bacon GetRegOrDefault] Function Invocation: $($MyInvocation | Out-String)"

        if ($this.OnlyUseDefaultSettings) {
            Write-Verbose "[Bacon GetRegOrDefault] OnlyUseDefaultSettings Set; Returning: ${DefaultValue}"
            return $DefaultValue
        }

        try {
            $ret = Get-ItemPropertyValue -Path ('{0}\{1}' -f $this.RegistryKeyRoot, $RegistryKey) -Name $RegistryValue -ErrorAction 'Stop'
            Write-Verbose "[Bacon GetRegOrDefault] Registry Set; Returning: ${ret}"
            return $ret
        } catch [System.Management.Automation.PSArgumentException] {
            Write-Verbose "[Bacon GetRegOrDefault] Registry Not Set; Returning Default: ${DefaultValue}"
            $Error.RemoveAt(0) # This isn't a real error, so I don't want it in the error record.
            return $DefaultValue
        } catch [System.Management.Automation.ItemNotFoundException] {
            Write-Verbose "[Bacon GetRegOrDefault] Registry Not Set; Returning Default: ${DefaultValue}"
            $Error.RemoveAt(0) # This isn't a real error, so I don't want it in the error record.
            return $DefaultValue
        }
    }

    [string] GetRegValueDoNotExpandEnvironmentNames($Key, $Value) {
        $item = Get-Item $Key
        if ($item) {
            return $item.GetValue($Value, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        } else {
            return $null
        }
    }

    [void] Quit($ExitCode = 0, [boolean] $ExitCodeAdd = $true , [int] $ExitCodeErrorBase = 55550000) {

        Write-Verbose "[Bacon.Exit] ExitCode Orig : ${ExitCode}"
        if ($ExitCode -eq 'line_number') {
            [int] $this.ExitCode = $MyInvocation.ScriptLineNumber
        }

        try {
            [int] $this.ExitCode = $ExitCode
        } catch {
            Write-Error "[Bacon.Exit] Cannot convert ExitCode to INT.`n`tExitCode: ${ExitCode}`n`tFrom: $($MyInvocation.ScriptName):$($MyInvocation.ScriptLineNumber)"
        }

        if ($ExitCodeAdd -and ($ExitCode -lt 0) -and ($ExitCodeErrorBase -gt 0)) {
            $ExitCodeErrorBase = $ExitCodeErrorBase * -1
        }

        if ($ExitCodeAdd -and (([string] $ExitCode).Length -gt 4)) {
            Write-Warning "[Bacon.Exit] ExitCode should not be added to Base when more than 4 digits. Doing it anyway ..."
        }

        if ($ExitCodeAdd -and ($ExitCode -eq 0)) {
            Write-Warning "[Bacon.Exit] ExitCode 0 being added may cause failure; not sure if this is expected. Doing it anyway ..."
        }

        $this.ExitCode = if ($ExitCodeAdd) { $ExitCode + $ExitCodeErrorBase } else { $ExitCode }
        Write-Verbose "[Bacon.Exit] ExitCode Final: ${ExitCode}"
        $this.Bacon.ExitCode = $ExitCode
        $global:Host.SetShouldExit($ExitCode)
        Exit $ExitCode
    }

    <#
    Dig through the Registry Key and import all the Keys and Values into the $global:Bacon objet.

    There's a fundamental flaw that I haven't addressed yet.
    - if there's a value and sub-key with the same name at the same key level, the sub-key won't be processed.
    #>
    hidden [void] SetDefaultSettingsFromRegistry([string] $Key) {
        if (Test-Path $Key) {
            $this.SetDefaultSettingsFromRegistrySubKey($this.Settings, $Key)

            foreach ($item in (Get-ChildItem $Key -Recurse -ErrorAction 'Ignore')) {
                $private:psPath = $item.PSPath.Split(':')[-1].Replace($Key.Split(':')[-1], $null)
                $private:node = $this.Settings
                foreach ($child in ($private:psPath.Trim('\').Split('\'))) {
                    if (-not $node.$child) {
                        [hashtable] $node.$child = @{}
                    }
                    $node = $node.$child
                }

                $this.SetDefaultSettingsFromRegistrySubKey($node, $item.PSPath)
            }
        }
    }

    hidden [void] SetDefaultSettingsFromRegistrySubKey([hashtable] $Hash, [string] $Key) {
        foreach ($regValue in (Get-Item $Key -ErrorAction 'Ignore').Property) {
            $Hash.Set_Item($regValue, (Get-ItemProperty -Path $Key -Name $regValue).$regValue)
        }


    }

    hidden [void] SetPSDefaultParameterValues([hashtable] $FunctionParameters) {
        if ($FunctionParameters) {
            foreach ($function in $FunctionParameters.GetEnumerator()) {
                Write-Debug ('[Bacon::SetPSDefaultParameterValues] Function Type: [{0}]' -f $function.GetType().FullName)
                Write-Debug ('[Bacon::SetPSDefaultParameterValues] Function: {0}: {1}' -f $function.Name, ($function.Value | ConvertTo-Json))
                foreach ($parameter in $function.Value.GetEnumerator()) {
                    Write-Debug ('[Bacon::SetPSDefaultParameterValues] Parameter: {0}: {1}' -f $parameter.Name, ($parameter.Value | ConvertTo-Json))
                    Write-Debug ('[Bacon::SetPSDefaultParameterValues] PSDefaultParameterValues: {0}:{1} :: {2}' -f $function.Name, $parameter.Name, $parameter.Value)
                    $global:PSDefaultParameterValues.Set_Item(('{0}:{1}' -f $function.Name, $parameter.Name), $parameter.Value)
                }
            }
        }
    }

    [psobject] GetSpecialFolders() {
        $specialFolders = [ordered] @{}
        foreach ($folder in ([Environment+SpecialFolder]::GetNames([Environment+SpecialFolder]) | Sort-Object)) {
            $specialFolders.Add($folder, $this.GetSpecialFolder($folder))
        }
        return ([psobject] $specialFolders)
    }

    [IO.DirectoryInfo] GetSpecialFolder([string] $Name) {
        return ([Environment]::GetFolderPath($Name) -as [IO.DirectoryInfo])
    }
}

# $bacon = [Bacon]::new('Mozilla', 'Firefox', '1.2.3', 'test')
# $bacon

# Class Sausage:Bacon {
#     Sausage([string] $Publisher, [string] $Product, [string] $Version, [string] $Action):base([string] $Publisher, [string] $Product, [string] $Version, [string] $Action) {
#     }
# }

# $sausage = [Sausage]::new('Mozilla', 'Firefox', '1.2.3', 'test')
# $sausage
