class Log {

    [hashtable] $LogDirectory = $(Accessor $this {
        get {
            $this.LogDirectory
        }
        set {
            param($arg)
            if (Assert-BaconIsElevated) {
                $this.LogDirectory = "${env:SystemRoot}\Logs\Bacon"
            } else {
                $global:Bacon.LogDirectory = [IO.DirectoryInfo] "${env:Temp}\Logs\Bacon"
            }
        }
        
    })
}

