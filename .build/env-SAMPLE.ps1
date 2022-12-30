# Sample Dev Environment Setup
# Copy this to env.ps1 and setting it up with real values.

# Key: http://proget.inedo.com/administration/api-keys/edit?apiKeyId=2
$env:PROGET_POWERSHELL_ESE_URL = 'https://proget.inedo.com/nuget/powershell-ese/'
$env:PROGET_POWERSHELL_ESE = '526f353998bd402ba50d71c955053265'

# From: https://armory.it.utsa.edu/groups/endpoint/-/settings/ci_cd
$env:ESE_CODE_SIGNING_CERT_PASS = 'b80ea29bcb9e-4f89a05003a863dff4e7'
$env:ESE_CODE_SIGNING_CERT_PFXB64 = 'MIILogI...zu/k6hkgZg3eVN/U=='

# AppVeyor: https://ci.appveyor.com/project/VertigoRay/psredstone/settings/environment
$env:CODECOV_TOKEN = 'cd1e2eb5-933d-4c8a-8b83-15e82b255151'
$env:PSGALLERY_API_KEY = '2658072c-519a-4316-bd8d-3bcec284dab7'
$env:APPVEYOR_BUILD_FOLDER = ([IO.DirectoryInfo] $PSScriptRoot).Parent