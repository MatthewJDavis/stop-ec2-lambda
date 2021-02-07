Task default -depends Analyse

$scriptPath = '../Stop-EC2Instance/Stop-EC2Instance.ps1'

Task Analyse -description 'Analyse script with PSScriptAnalyzer' {
  $saResults = Invoke-ScriptAnalyzer -Path $scriptPath -Severity @('Error', 'Warning')
  if ($saResults) {
    $saResults | Format-Table
    Write-Error -Message 'One or more Script Analyser errors/warnings were found'
  }
}

Task Build -description 'Build the lambda package' {
  Import-Module -Name 'AWSLambdaPSCore'
  New-AWSPowerShellLambdaPackage -ScriptPath $scriptPath -OutputPackage '/tmp/lambda.zip'
}
