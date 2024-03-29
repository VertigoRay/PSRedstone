#region DEVONLY
. ([IO.Path]::Combine(([IO.DirectoryInfo] $PSScriptRoot).Parent.FullName, 'Public', 'Assert-IsElevated.ps1'))
. ([IO.Path]::Combine(([IO.DirectoryInfo] $PSScriptRoot).Parent.FullName, 'Public', 'Get-RegistryValueOrDefault.ps1'))
# . ([IO.Path]::Combine(([IO.DirectoryInfo] $PSScriptRoot).Parent.FullName, 'Public', 'Get-RegistryValueDoNotExpandEnvironmentNames.ps1'))
#endregion

class Redstone {
    hidden  [string]                $_Action                = $null
    hidden  [hashtable]             $_CimInstance           = $null
    hidden  [hashtable]             $_Env                   = $null
    hidden  [hashtable]             $_OS                    = $null
    hidden  [hashtable]             $_Vars                  = $null
    hidden  [string]                $_Product               = $null
    hidden  [hashtable]             $_ProfileList           = $null
    hidden  [string]                $_Publisher             = $null
    hidden  [string]                $_Version               = 'None'
    [int]                           $ExitCode               = 0
    [System.Collections.ArrayList]  $Exiting                = @()
    [bool]                          $IsElevated             = $null
    [hashtable]                     $Settings               = @{}

    # Use the default settings, don't read any of the settings in from the registry. In production this is never set.
    [bool]                          $OnlyUseDefaultSettings = $false
    [hashtable]                     $Debug                  = @{}

    #region Instantiation
    static Redstone() {
        # Creating some custom setters that update other properties, like Log Paths, when related properties are changed.
        Update-TypeData -TypeName 'Redstone' -MemberName 'Action' -MemberType 'ScriptProperty' -Value {
            # Getter
            return $this._Action
        } -SecondValue {
            param($value)
            # Setter
            $this._Action = $value
            $this.SetUpLog()
        } -Force
        Update-TypeData -TypeName 'Redstone' -MemberName 'CimInstance' -MemberType 'ScriptProperty' -Value {
            # Getter
            $className = $MyInvocation.Line.Split('.')[2]
            return $this.GetCimInstance($className, $true)
        } -Force
        Update-TypeData -TypeName 'Redstone' -MemberName 'Env' -MemberType 'ScriptProperty' -Value {
            # Getter
            if (-not $this._Env) {
                # This is the Lazy Loading logic.
                $this.SetUpEnv()
            }
            return $this._Env
        } -Force
        Update-TypeData -TypeName 'Redstone' -MemberName 'OS' -MemberType 'ScriptProperty' -Value {
            # Getter
            if (-not $this._OS) {
                # This is the Lazy Loading logic.
                $this.SetUpOS()
            }
            return $this._OS
        } -Force
        Update-TypeData -TypeName 'Redstone' -MemberName 'Vars' -MemberType 'ScriptProperty' -Value {
            # Getter
            if (-not $this._Vars) {
                # This is the Lazy Loading logic.
                $this.SetUpVars()
            }
            return $this._Vars
        } -SecondValue {
            param($value)
            # Setter
            $this._Vars = $value
        } -Force
        Update-TypeData -TypeName 'Redstone' -MemberName 'Product' -MemberType 'ScriptProperty' -Value {
            # Getter
            return $this._Product
        } -SecondValue {
            param($value)
            # Setter
            $this._Product = $value
            $this.SetUpLog()
        } -Force
        Update-TypeData -TypeName 'Redstone' -MemberName 'ProfileList' -MemberType 'ScriptProperty' -Value {
            # Getter
            if (-not $this._ProfileList) {
                # This is the Lazy Loading logic.
                $this.SetUpProfileList()
            }
            return $this._ProfileList
        } -Force
        Update-TypeData -TypeName 'Redstone' -MemberName 'Publisher' -MemberType 'ScriptProperty' -Value {
            # Getter
            return $this._Publisher
        } -SecondValue {
            param($value)
            # Setter
            $this._Publisher = $value
            $this.SetUpLog()
        } -Force
        Update-TypeData -TypeName 'Redstone' -MemberName 'Version' -MemberType 'ScriptProperty' -Value {
            # Getter
            return $this._Version
        } -SecondValue {
            param($value)
            # Setter
            $this._Version = $value
            $this.SetUpLog()
        } -Force
    }

    Redstone() {
        $this.SetUpSettings()
        $this.Settings.JSON = @{}

        $settingsFiles = @(
            [IO.FileInfo] ([IO.Path]::Combine($PWD.ProviderPath, 'settings.json'))
            [IO.FileInfo] ([IO.Path]::Combine(([IO.FileInfo] $this.Debug.PSCallStack[2].ScriptName).Directory.FullName, 'settings.json'))
            [IO.FileInfo] ([IO.Path]::Combine(([IO.DirectoryInfo] $PWD.ProviderPath).Parent, 'settings.json'))
            [IO.FileInfo] ([IO.Path]::Combine(([IO.FileInfo] $this.Debug.PSCallStack[2].ScriptName).Directory.Parent.FullName, 'settings.json'))
        )

        foreach ($location in $settingsFiles) {
            if ($location.Exists) {
                $this.Settings.JSON.File = $location
                $this.Settings.JSON.Data = Get-Content $this.Settings.JSON.File.FullName | ConvertFrom-Json
                break
            }
        }

        if (-not $this.Settings.JSON.File.Exists) {
            if (Get-Variable 'settings' -Scope 'script' -ErrorAction 'Ignore') {
                if ($script:settings.Keys -notcontains 'Publisher') {
                    Throw [System.IO.FileNotFoundException] ('Settings must contain Publisher: {0}' -f ($script:settings | ConvertTo-Json))
                }
                if ($script:settings.Keys -notcontains 'Product') {
                    Throw [System.IO.FileNotFoundException] ('Settings must contain Product: {0}' -f ($script:settings | ConvertTo-Json))
                }
                if ($script:settings.Keys -notcontains 'Version') {
                    Throw [System.IO.FileNotFoundException] ('Settings must contain Version: {0}' -f ($script:settings | ConvertTo-Json))
                }
            } else {
                Throw [System.IO.FileNotFoundException] ('Could NEITHER find the settings variable nor a file at any of these locations: {0}' -f ($settingsFiles.FullName -join ', '))
            }
        }

        $this.SetDefaultSettingsFromRegistry($this.Settings.Registry.KeyRoot)
        $this.SetPSDefaultParameterValues($this.Settings.Functions)

        $this.set__Publisher($this.Settings.JSON.Data.Publisher)
        $this.set__Product($this.Settings.JSON.Data.Product)
        $this.set__Version($this.Settings.JSON.Data.Version)
        $this.set__Action($(
            if ($this.Settings.JSON.Data.Action) {
                $this.Settings.JSON.Data.Action
            } else {
                $scriptName = ($this.Debug.PSCallStack | Where-Object {
                    ([IO.FileInfo] $_.ScriptName).Name -ne ([IO.FileInfo] $this.Debug.PSCallStack[0].ScriptName).Name
                } | Select-Object -First 1).ScriptName
                ([IO.FileInfo] $scriptName).BaseName
            }
        ))

        $this.SetUpLog()
    }

    Redstone([IO.FileInfo] $Settings) {
        $this.SetUpSettings()

        $this.Settings.JSON = @{}
        $this.Settings.JSON.File = [IO.FileInfo] $Settings
        if ($this.Settings.JSON.File.Exists) {
            $this.Settings.JSON.Data = Get-Content $this.Settings.JSON.File.FullName | ConvertFrom-Json
        } else {
            Throw [System.IO.FileNotFoundException] $this.Settings.JSON.File.FullName
        }

        $this.SetDefaultSettingsFromRegistry($this.Settings.Registry.KeyRoot)
        $this.SetPSDefaultParameterValues($this.Settings.Functions)

        $this.set__Publisher($this.Settings.JSON.Data.Publisher)
        $this.set__Product($this.Settings.JSON.Data.Product)
        $this.set__Version($this.Settings.JSON.Data.Version)
        $this.set__Action($(
            if ($this.Settings.JSON.Data.Action) {
                $this.Settings.JSON.Data.Action
            } else {
                $scriptName = ($this.Debug.PSCallStack | Where-Object {
                    ([IO.FileInfo] $_.ScriptName).Name -ne ([IO.FileInfo] $this.Debug.PSCallStack[0].ScriptName).Name
                } | Select-Object -First 1).ScriptName
                ([IO.FileInfo] $scriptName).BaseName
            }
        ))

        $this.SetUpLog()
    }
    
    Redstone([PSObject] $Settings) {
        $this.SetUpSettings()

        $this.Settings.JSON = @{}
        $this.Settings.JSON.Data = $Settings

        $this.SetDefaultSettingsFromRegistry($this.Settings.Registry.KeyRoot)
        $this.SetPSDefaultParameterValues($this.Settings.Functions)

        $this.set__Publisher($this.Settings.JSON.Data.Publisher)
        $this.set__Product($this.Settings.JSON.Data.Product)
        $this.set__Version($this.Settings.JSON.Data.Version)
        $this.set__Action($(
            if ($this.Settings.JSON.Data.Action) {
                $this.Settings.JSON.Data.Action
            } else {
                $scriptName = ($this.Debug.PSCallStack | Where-Object {
                    ([IO.FileInfo] $_.ScriptName).Name -ne ([IO.FileInfo] $this.Debug.PSCallStack[0].ScriptName).Name
                } | Select-Object -First 1).ScriptName
                ([IO.FileInfo] $scriptName).BaseName
            }
        ))

        $this.SetUpLog()
    }

    Redstone([string] $Publisher, [string] $Product, [string] $Version, [string] $Action) {
        $this.SetUpSettings()

        $this.SetDefaultSettingsFromRegistry($this.Settings.Registry.KeyRoot)
        $this.SetPSDefaultParameterValues($this.Settings.Functions)

        $this.set__Publisher($Publisher)
        $this.set__Product($Product)
        $this.set__Version($Version)
        $this.set__Action($Action)

        $this.SetUpLog()
    }
    #endregion Instantiation

    #region Settings
    hidden [void] SetUpSettings() {
        <#
        This is the original Settings
        #>
        $this.Debug = @{
            MyInvocation = $MyInvocation
            PSCallStack = (Get-PSCallStack)
        }

        $this.IsElevated = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
        $this.Settings = @{}

        $regKeyPSRedstone = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\com.github.VertigoRay\PSRedstone'
        $this.Settings.Registry = @{
            KeyRoot = $this.GetSetting($regKeyPSRedstone, 'RegistryKeyRoot', $regKeyPSRedstone)
        }
    }

    hidden [string] GetSetting([string] $Key, [string] $Name, [string] $Default) {
        $item = Get-Item ('env:{0}' -f $Name) -ErrorAction 'Ignore'
        if ($item.Value) {
            return ($item.Value -as [string])
        } else {
            return ((Get-RegistryValueOrDefault $Key $Name $Default) -as [string])
        }
    }
    #endregion Settings

    #region CimInstance
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
    #endregion CimInstance

    #region Debug Overrides
    hidden [bool] Is64BitOperatingSystem() {
        if ('Is64BitOperatingSystem' -in $this.Debug.Keys) {
            return $this.Debug.Is64BitOperatingSystem
        } else {
            return ([System.Environment]::Is64BitOperatingSystem)
        }
    }

    hidden [System.Collections.DictionaryEntry] Is64BitOperatingSystem([bool] $Override) {
        # Used for Pester Testing
        $this.Debug.Is64BitOperatingSystem = $Override
        return ($this.Debug.GetEnumerator() | Where-Object{ $_.Name -eq 'Is64BitOperatingSystem' })
    }

    hidden [bool] Is64BitProcess() {
        if ('Is64BitProcess' -in $this.Debug.Keys) {
            return $this.Debug.Is64BitProcess
        } else {
            return ([System.Environment]::Is64BitProcess)
        }
    }

    hidden [System.Collections.DictionaryEntry] Is64BitProcess([bool] $Override) {
        # Used for Pester Testing
        $this.Debug.Is64BitProcess = $Override
        return ($this.Debug.GetEnumerator() | Where-Object{ $_.Name -eq 'Is64BitProcess' })
    }
    #endregion Debug Overrides

    #region Env
    hidden [void] SetUpEnv() {
        # This section

        $this._Env = @{}
        if ($this.Is64BitOperatingSystem()) {
            # x64 OS
            if ($this.Is64BitProcess()) {
                # x64 Process
                $this._Env.CommonProgramFiles = $env:CommonProgramFiles
                $this._Env.'CommonProgramFiles(x86)' = ${env:CommonProgramFiles(x86)}
                $this._Env.PROCESSOR_ARCHITECTURE = $env:PROCESSOR_ARCHITECTURE
                $this._Env.ProgramFiles = $env:ProgramFiles
                $this._Env.'ProgramFiles(x86)' = ${env:ProgramFiles(x86)}
                $this._Env.System32 = "${env:SystemRoot}\System32"
                $this._Env.SysWOW64 = "${env:SystemRoot}\SysWOW64"
            } else {
                # Running as x86 on x64 OS
                $this._Env.CommonProgramFiles = $env:CommonProgramW6432
                $this._Env.'CommonProgramFiles(x86)' = ${env:CommonProgramFiles(x86)}
                $this._Env.PROCESSOR_ARCHITECTURE = $env:PROCESSOR_ARCHITEW6432
                $this._Env.ProgramFiles = $env:ProgramW6432
                $this._Env.'ProgramFiles(x86)' = ${env:ProgramFiles(x86)}
                $this._Env.System32 = "${env:SystemRoot}\SysNative"
                $this._Env.SysWOW64 = "${env:SystemRoot}\SysWOW64"
            }
        } else {
            # x86 OS
            $this._Env.CommonProgramFiles = $env:CommonProgramFiles
            $this._Env.'CommonProgramFiles(x86)' = $env:CommonProgramFiles
            $this._Env.PROCESSOR_ARCHITECTURE = $env:PROCESSOR_ARCHITECTURE
            $this._Env.ProgramFiles = $env:ProgramFiles
            $this._Env.'ProgramFiles(x86)' = $env:ProgramFiles
            $this._Env.System32 = "${env:SystemRoot}\System32"
            $this._Env.SysWOW64 = "${env:SystemRoot}\System32"
        }
    }
    #endregion Env

    #region Log
    hidden [void] SetUpLog() {
        $this.Settings.Log = @{}

        if ($this.IsElevated) {
            $private:Directory = [IO.DirectoryInfo] "${env:SystemRoot}\Logs\Redstone"
        } else {
            $private:Directory = [IO.DirectoryInfo] "${env:Temp}\Logs\Redstone"
        }

        if (-not $private:Directory.Exists) {
            New-Item -ItemType 'Directory' -Path $private:Directory.FullName -Force | Out-Null
            $private:Directory.Refresh()
        }

        $this.Settings.Log.File = [IO.FileInfo] (Join-Path $private:Directory.FullName ('{0} {1} {2} {3}.log' -f $this.Publisher, $this.Product, $this.Version, $this.Action))
        $this.Settings.Log.FileF = (Join-Path $private:Directory.FullName ('{0} {1} {2} {3}.{{0}}.log' -f $this.Publisher, $this.Product, $this.Version, $this.Action)) -as [string]
        $this.PSDefaultParameterValuesSetUp()
    }
    #endregion Log

    #region OS
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
        [string]    $this._OS.MachineSid = ((Get-LocalUser | Select-Object -First 1).SID).AccountDomainSID.ToString()
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
        switch ($this._OS.ProductType) {
            1       { [string] $this._OS.ProductTypeName = 'Workstation' }
            2       { [string] $this._OS.ProductTypeName = 'Domain Controller' }
            3       { [string] $this._OS.ProductTypeName = 'Server' }
            default { [string] $this._OS.ProductTypeName = 'Unknown' }
        }
    }
    #endregion OS

    #region Profile List
    hidden [void] SetUpProfileList() {
        Write-Debug 'GETTER: ProfileList'
        if (-not $this._ProfileList) {
            Write-Debug 'GETTER: Setting up ProfileList'
            $this._ProfileList = @{}
            $regProfileListPath = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
            $regProfileList = Get-Item $regProfileListPath
            foreach ($property in $regProfileList.Property) {
                $value = if ($dirInfo = (Get-ItemProperty -Path $regProfileListPath).$property -as [IO.DirectoryInfo]) {
                    $dirInfo
                } else {
                    (Get-ItemProperty -Path $regProfileListPath).$property
                }
                $this._ProfileList.Add($property, $value)
            }

            [System.Collections.ArrayList] $this._ProfileList.Profiles = @()
            foreach ($userProfile in (Get-ChildItem $regProfileListPath)) {
                [hashtable] $user = @{}
                $user.Add('SID', $userProfile.PSChildName)
                $user.Add('Path', ((Get-ItemProperty "${regProfileListPath}\$($userProfile.PSChildName)").ProfileImagePath -as [IO.DirectoryInfo]))
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
    #endregion Profile List

    #region Vars
    hidden [void] SetUpVars() {
        $this.Settings.Registry.KeyOrg = $this.GetSetting($this.Settings.Registry.KeyRoot, 'RegistryKeyOrg', [IO.Path]::Combine($this.Settings.Registry.KeyRoot, 'Org'))
        $this.Settings.Registry.KeyOrgRecurse = $this.GetSetting($this.Settings.Registry.KeyRoot, 'RegistryKeyOrgRecurse', $false)
        $this.Settings.Registry.KeyPublisherParent = $this.GetSetting($this.Settings.Registry.KeyRoot, 'RegistryKeyPublisherParent', [IO.Path]::Combine($this.Settings.Registry.KeyRoot, 'Software'))
        $this.Settings.Registry.KeyPublisherRecurse = $this.GetSetting($this.Settings.Registry.KeyRoot, 'RegistryKeyPublisherRecurse', $false)
        $this.Settings.Registry.KeyProductParent = $this.GetSetting($this.Settings.Registry.KeyRoot, 'RegistryKeyProductParent', [IO.Path]::Combine($this.Settings.Registry.KeyPublisherParent, $this._Publisher))
        $this.Settings.Registry.KeyProductRecurse = $this.GetSetting($this.Settings.Registry.KeyRoot, 'RegistryKeyProductRecurse', $true)

        $this.Settings.Org = @{}
        $query = @{
            Key = $this.Settings.Registry.KeyOrg
            Recurse = $this.Settings.Registry.KeyOrgRecurse
        }
        $this.Settings.Org = Get-RegistryKeyAsHashTable @query
        $this.Vars = Get-RegistryKeyAsHashTable @query

        $this.Settings.Publisher = @{}
        $query = @{
            Key = [IO.Path]::Combine($this.Settings.Registry.KeyPublisherParent, $this._Publisher)
            Recurse = $this.Settings.Registry.KeyPublisherRecurse
        }
        $this.Settings.Publisher = Get-RegistryKeyAsHashTable @query
        $this.Vars = Get-RegistryKeyAsHashTable @query

        $this.Settings.Product = @{}
        $query = @{
            Key = [IO.Path]::Combine($this.Settings.Registry.KeyProductParent, $this._Product)
            Recurse = $this.Settings.Registry.KeyProductRecurse
        }
        $this.Settings.Product = Get-RegistryKeyAsHashTable @query
        $this.Vars = Get-RegistryKeyAsHashTable @query
    }

    [PSObject] GetVar([string] $Path) {
        return (Get-HashtableValue -Hashtable $this._Vars -Path $Path)
    }

    [PSObject] GetVar([string] $Path, [PSObject] $Default) {
        return (Get-HashtableValue -Hashtable $this._Vars -Path $Path -Default $Default)
    }
    #endregion Vars

    #region PSDefaultParameterValues
    hidden [void] PSDefaultParameterValuesSetUp() {
        $_prefix = (Get-Module 'PSRedstone').Prefix

        # $global:PSDefaultParameterValues.Set_Item(('*-{0}*:LogFileF' -f $_prefix), $this.Settings.Log.FileF)
        # $global:PSDefaultParameterValues.Set_Item(('*-{0}*:LogFileF' -f $_prefix), $this.Settings.Log.FileF)
        foreach ($_exportedCommand in (Get-Module 'PSRedstone').ExportedCommands.Keys) {
            if ((Get-Command $_exportedCommand).Parameters.Keys -contains 'LogFile') {
                $global:PSDefaultParameterValues.Set_Item(('{0}:LogFile' -f $_exportedCommand), $this.Settings.Log.File.FullName)
            }
            if ((Get-Command $_exportedCommand).Parameters.Keys -contains 'LogFileF') {
                $global:PSDefaultParameterValues.Set_Item(('{0}:LogFileF' -f $_exportedCommand), $this.Settings.Log.FileF)
            }
        }

        $_onlyUseDefaultSettings = $this.GetRegOrDefault('Settings\Functions\Get-RegistryValueOrDefault', 'OnlyUseDefaultSettings', $false)
        $global:PSDefaultParameterValues.Set_Item(('Get-{0}RegistryValueOrDefault:OnlyUseDefaultSettings' -f $_prefix), $_onlyUseDefaultSettings)

        # https://github.com/VertigoRay/PSWriteLog/wiki
        $global:PSDefaultParameterValues.Set_Item('Write-Log:FilePath', $this.Settings.Log.File.FullName)
    }

    hidden [void] SetPSDefaultParameterValues([hashtable] $FunctionParameters) {
        if ($FunctionParameters) {
            foreach ($function in $FunctionParameters.GetEnumerator()) {
                Write-Debug ('[Redstone::SetPSDefaultParameterValues] Function Type: [{0}]' -f $function.GetType().FullName)
                Write-Debug ('[Redstone::SetPSDefaultParameterValues] Function: {0}: {1}' -f $function.Name, ($function.Value | ConvertTo-Json))
                foreach ($parameter in $function.Value.GetEnumerator()) {
                    Write-Debug ('[Redstone::SetPSDefaultParameterValues] Parameter: {0}: {1}' -f $parameter.Name, ($parameter.Value | ConvertTo-Json))
                    Write-Debug ('[Redstone::SetPSDefaultParameterValues] PSDefaultParameterValues: {0}:{1} :: {2}' -f $function.Name, $parameter.Name, $parameter.Value)
                    $global:PSDefaultParameterValues.Set_Item(('{0}:{1}' -f $function.Name, $parameter.Name), $parameter.Value)
                }
            }
        }
    }
    #endregion PSDefaultParameterValues

    #region Registry
    hidden [psobject] GetRegOrDefault($RegistryKey, $RegistryValue, $DefaultValue) {
        Write-Verbose "[Redstone GetRegOrDefault] > $($MyInvocation.BoundParameters | ConvertTo-Json -Compress)"
        Write-Debug "[Redstone GetRegOrDefault] Function Invocation: $($MyInvocation | Out-String)"

        if ($this.OnlyUseDefaultSettings) {
            Write-Verbose "[Redstone GetRegOrDefault] OnlyUseDefaultSettings Set; Returning: ${DefaultValue}"
            return $DefaultValue
        }

        try {
            $ret = Get-ItemPropertyValue -Path ('Registry::{0}\{1}' -f $this.Settings.Registry.KeyRoot, $RegistryKey) -Name $RegistryValue -ErrorAction 'Stop'
            Write-Verbose "[Redstone GetRegOrDefault] Registry Set; Returning: ${ret}"
            return $ret
        } catch [System.Management.Automation.PSArgumentException] {
            Write-Verbose "[Redstone GetRegOrDefault] Registry Not Set; Returning Default: ${DefaultValue}"
            # This isn't a real error, so I don't want it in the error record.
            # This is a weird way to remove the record, but I've seen in testing where $Error length is 0, and
            # I don't understand it. However, this catches that error and ensure it doesn't end up on the $Error.
            #   Ref: https://ci.appveyor.com/project/VertigoRay/psredstone/builds/46036142
            if ($Error.Count -gt 0) {
                $Error.RemoveAt(0)
            }
            return $DefaultValue
        } catch [System.Management.Automation.ItemNotFoundException] {
            Write-Verbose "[Redstone GetRegOrDefault] Registry Not Set; Returning Default: ${DefaultValue}"
            # This isn't a real error, so I don't want it in the error record.
            # This is a weird way to remove the record, but I've seen in testing where $Error length is 0, and
            # I don't understand it. However, this catches that error and ensure it doesn't end up on the $Error.
            #   Ref: https://ci.appveyor.com/project/VertigoRay/psredstone/builds/46036142
            if ($Error.Count -gt 0) {
                $Error.RemoveAt(0)
            }
            return $DefaultValue
        }
    }

    hidden [void] SetDefaultSettingsFromRegistrySubKey([hashtable] $Hash, [string] $Key) {
        foreach ($regValue in (Get-Item $Key -ErrorAction 'Ignore').Property) {
            $Hash.Set_Item($regValue, (Get-ItemProperty -Path $Key -Name $regValue).$regValue)
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

    hidden [void] SetDefaultSettingsFromRegistry([string] $Key) {
        <#
        Dig through the Registry Key and import all the Keys and Values into the $global:Redstone objet.

        There's a fundamental flaw that I haven't addressed yet.
        - if there's a value and sub-key with the same name at the same key level, the sub-key won't be processed.
        #>
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
    #endregion Registry

    #region Special Folders
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
    #endregion Special Folders

    #region Quit
    [void] Quit() {
        Write-Debug ('[Redstone.Quit 0] > {0}' -f ($MyInvocation | Out-String))
        [void] $this.Quit(0, $true , 0)
    }

    [void] Quit($ExitCode = 0) {
        Write-Verbose ('[Redstone.Quit 1] > {0}' -f ($MyInvocation | Out-String))
        $this.ExitCode = if ($ExitCode -eq 'line_number') {
            (Get-PSCallStack)[1].Location.Split(':')[1].Replace('line', '') -as [int]
        } else {
            $ExitCode
        }
        [void] $this.Quit($this.ExitCode, $false , 55550000)
    }

    [void] Quit($ExitCode = 0, [boolean] $ExitCodeAdd = $false) {
        Write-Verbose ('[Redstone.Quit 1] > {0}' -f ($MyInvocation | Out-String))
        $this.ExitCode = if ($ExitCode -eq 'line_number') {
            (Get-PSCallStack)[1].Location.Split(':')[1].Replace('line', '') -as [int]
        } else {
            $ExitCode
        }
        [void] $this.Quit($this.ExitCode, $ExitCodeAdd , 55550000)
    }

    [void] Quit($ExitCode = 0, [boolean] $ExitCodeAdd = $false, [int] $ExitCodeErrorBase = 55550000) {
        Write-Debug ('[Redstone.Quit 3] > {0}' -f ($MyInvocation | Out-String))

        Write-Verbose ('[Redstone.Quit] ExitCode: {0}' -f $ExitCode)
        $this.ExitCode = if ($ExitCode -eq 'line_number') {
            (Get-PSCallStack)[1].Location.Split(':')[1].Replace('line', '') -as [int]
        } else {
            $ExitCode -as [int]
        }

        if ($ExitCodeAdd) {
            Write-Information ('[Redstone.Quit] ExitCodeErrorBase: {0}' -f $ExitCodeErrorBase)
            if (($this.ExitCode -lt 0) -and ($ExitCodeErrorBase -gt 0)) {
                # Always Exit positive
                Write-Verbose ('[Redstone.Quit] ExitCodeErrorBase: {0}' -f $ExitCodeErrorBase)
                $ExitCodeErrorBase = $ExitCodeErrorBase * -1
                Write-Verbose ('[Redstone.Quit] ExitCodeErrorBase: {0}' -f $ExitCodeErrorBase)
            }

            if (([string] $this.ExitCode).Length -gt 4) {
                Write-Warning "[Redstone.Quit] ExitCode should not be added to Base when more than 4 digits. Doing it anyway ..."
            }

            if ($this.ExitCode -eq 0) {
                Write-Warning "[Redstone.Quit] ExitCode 0 being added may cause failure; not sure if this is expected. Doing it anyway ..."
            }

            $this.ExitCode = $this.ExitCode + $ExitCodeErrorBase
        }

        Write-Information ('[Redstone.Quit] ExitCode: {0}' -f $this.ExitCode)

        # Debug.Quit.DoNotExit is used in Pester testing.
        if (-not $this.Debug.Quit.DoNotExit) {
            $global:Host.SetShouldExit($ExitCode)
            Exit $ExitCode
        }
    }
    #endregion Quit
}
#region DEVONLY
# $Redstone = [Redstone]::new('Mozilla', 'Firefox', '1.2.3', 'test')
# $Redstone
# $Redstone.Settings.Registry

# Class Sausage:Redstone {
#     Sausage([string] $Publisher, [string] $Product, [string] $Version, [string] $Action):base([string] $Publisher, [string] $Product, [string] $Version, [string] $Action) {
#     }
# }

# $sausage = [Sausage]::new('Mozilla', 'Firefox', '1.2.3', 'test')
# $sausage
#endregion
