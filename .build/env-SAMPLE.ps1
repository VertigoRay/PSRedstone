# Sample Dev Environment Setup
# Copy this to env.ps1 and setting it up with real values.

# AppVeyor: https://ci.appveyor.com/project/VertigoRay/psredstone/settings/environment
$env:CODECOV_TOKEN = 'cd1e2eb5...15e82b255151'
$env:PSGALLERY_API_KEY = '2658072c...3bcec284dab7'
$env:APPVEYOR_BUILD_FOLDER = ([IO.DirectoryInfo] $PSScriptRoot).Parent
$env:GITHUB_PERSONAL_ACCESS_TOKEN = 'b63ff855...b713fd5f9e90'
$env:APPVEYOR_REPO_NAME = 'VertigoRay/PSRedstone'
