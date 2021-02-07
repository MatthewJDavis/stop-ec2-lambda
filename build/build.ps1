# Script to configure build agent and set up requirements if they are missing.
# Calls the psake build script which then does the analysis and building and will return correct exit code to build system.

[cmdletbinding()]
param(
  [Validateset('Default', 'Analyse', 'Test')]
  [string[]]
  $Task = 'default'
)

# Install required version of AWSLamdaPSCore, used to build the lamdba
$lambdaCoreVersion = '2.0.0.0'
if ((Get-Module -Name AWSLambdaPSCore -ListAvailable).Version -ne $AWSLambdaPSCore) { 
  Install-Module -Name 'AWSLambdaPSCore' -RequiredVersion $lambdaCoreVersion -Scope CurrentUser -Force
  Remove-Module -Name 'AWSLambdaPSCore' -Force
  Import-Module -Name 'AWSLambdaPSCore' -RequiredVersion $lambdaCoreVersion -Force
}

if (!(Get-Module -Name psake -ListAvailable)) { Install-Module -Name psake -Scope CurrentUser -Force }
if (!(Get-Module -Name PSScriptAnalyzer -ListAvailable)) { Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force }

Invoke-psake -buildFile "$PSScriptRoot\psakeBuild.ps1" -taskList $Task -Verbose:$VerbosePreference
if ($psake.build_success -eq $false) { exit 1 } else { exit 0 }