$invokePsake = @{
    BuildFile = [IO.Path]::Combine($env:APPVEYOR_BUILD_FOLDER, '.build', 'buildPsake.ps1')
    TaskList = 'CodeCov'
}
Invoke-psake @invokePsake
if (-not $psake.build_success) {
    $Host.SetShouldExit(1)
}