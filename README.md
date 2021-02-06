# stop-ec2-lambda
Lamdba to stop ec2 instances on a schedule

## Getting started

Clone this repository to your local machine. Make sure you have terraform version v0.14.5 or greater installed (if there are major changes in terraform then the main.tf file may need updating - this was written with v0.14.5).

Currently you will need to build the lambda to create the zip file a per below instructions until this is moved to a build system that will output the build to an artifact repository.

## Lambda

Written in PowerShell: Stop-EC2Instance\Stop-EC2Instance.ps1

Requires the module *AWSLambdaPSCore* to build. ```Install-Module AWSLambdaPSCore -Scope CurrentUser``` (Version used was 2.0.0.0)

To build the lamdba from the root of the project run:

```powershell
New-AWSPowerShellLambdaPackage -ScriptPath .\Stop-EC2Instance\Stop-EC2Instance.ps1 -OutputPackage .\Stop-EC2Instance\Stop-EC2Instance.zip
```

## Terraform

The lambda and other AWS resources are created and managed with Terraform. To update / change the resources or to deploy and updated lambda package once it has been built via the above command run the following from the *terraform* directory.

### Terraform state

Azure blob storage is used to store the state file with the Terraform Azure remote backend.

To access the storage file a SAS token is required. You can create a new one however you like, the portal now has this functionality. It needs access to container, object and Read, Write, Delete, List, Add, Create permissions.

### Steps

Copy the SAS token.

Add it to the environment variable in the shell, in bash this would be done:

```bash
 export ARM_SAS_TOKEN="?sv...3D"
```

To initialise the directory to connect to the remote state and install the AWS provider.

```bash
terraform init
```

To view the changes.

```bash
terraform plan
```

To apply the changes.

```bash
terraform apply
```