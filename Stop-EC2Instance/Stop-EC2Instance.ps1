# PowerShell script file to be executed as a AWS Lambda function.
# Stops all running EC2 instances that do not have the tag LeaveOn with the value True attached.

#Requires -Modules @{ModuleName='AWS.Tools.Common';ModuleVersion='4.0.5.0'}
#Requires -Modules @{ModuleName='AWS.Tools.EC2';ModuleVersion='4.0.5.0'}

# Uncomment to send the input event to CloudWatch Logs
# Write-Host (ConvertTo-Json -InputObject $LambdaInput -Compress -Depth 5)

try {
    $ec2List = Get-EC2Instance -Filter  @{'name'='instance-state-name';'values'='running'}

    # Filter out instances that have the tag LeaveOn set to true so we only shut down the other instances.
    $shutdownList = $ec2List.Instances | Where-Object {($_ | Select-Object -ExpandProperty tags | Where-Object -Property Key -eq 'LeaveOn').value -ne "True"}
    
    foreach ($instance in $shutdownList) {
        Write-Host "Shutting down $($instance.InstanceId)"
        Stop-EC2Instance -InstanceId $instance.InstanceId
    }
} catch {
    Write-Host $_.Exception.Message
}
