Task default -depends Analyse

$scriptPath = $PSScriptRoot + '/Stop-EC2Instance/Stop-EC2Instance.ps1'

Task Analyse -description 'Analyse script with PSScriptAnalyzer' {
  $saResults = Invoke-ScriptAnalyzer -Path $scriptPath -Severity @('Error', 'Warning')
  if ($saResults) {
    $saResults | Format-Table
    Write-Error -Message 'One or more Script Analyser errors/warnings were found'
  }
}