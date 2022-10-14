$psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
Write-Debug ('psProjectRoot: {0}' -f $psProjectRoot)

. ('{0}\PSBacon\Public\Mount-BaconWim.ps1' -f $psProjectRoot.FullName)

[bool] $isElevated = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

Describe 'Mount-BaconWim' {
    Context 'dev\PSBacon.wim' {
        It 'Should be elevated to create WIMs' {
            $isElevated | Should Be $true
        }

        if ($isElevated) {
            $imagePath = '{0}\dev\PSBacon.wim' -f $psProjectRoot.FullName
            $mountPath = '{0}\dev\Mount_PSBacon' -f $env:TEMP

            if (Test-Path $mountPath) {
                Remove-Item $mountPath -Recurse -Force
            }

            It ('Mount path does not already exist: {0}' -f $mountPath) {
                Test-Path $mountPath | Should Be $false
            }

            Mount-BaconWim -ImagePath $imagePath -MountPath $mountPath

            It ('WIM mounted: {0}' -f $mountPath) {
                Test-Path $mountPath | Should Be $true
            }
        }
    }
}
