# Sample Dev Environment Setup
# I suggest copying this to env.ps1 and setting it up with real values.

# Key: http://ese-inedo.utsarr.net:8624/administration/api-keys/edit?apiKeyId=2
$env:PROGET_POWERSHELL_ESE = '526f353998bd402ba50d71c955053265'

# From: https://armory.it.utsa.edu/groups/endpoint/-/settings/ci_cd
$env:ESE_CODE_SIGNING_CERT_PASS = 'b80ea29bcb9e-4f89a05003a863dff4e7'
$env:ESE_CODE_SIGNING_CERT_PFXB64 = 'MIILogI...zu/k6hkgZg3eVN/U=='