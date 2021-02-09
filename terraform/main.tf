terraform {
  backend "azurerm" {
    storage_account_name  = "terraformstate"
    container_name        = "terraform-state"
    key                   = "stop-ec2-dev.tfstate"
  }
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

variable "lambda_function_name" {
  type = string
  default = "stop-ec2-daily"
}

variable "lambda_handler" {
  type = string
  default = "Stop-EC2Instance::Stop_EC2Instance.Bootstrap::ExecuteFunction"
}

variable "filename" {
  type = string
  default = "../Stop-EC2Instance/Stop-EC2Instance.zip"
}

provider "aws" {
   region = "eu-west-1"
}

resource "aws_iam_role" "lambda-stop-ec2" {
    name = "lambda-${var.lambda_function_name}-role"
    description = "Allows Lambda functions to stop EC2 instances."

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
          {
            "Action": "sts:AssumeRole",
            "Principal": {
              "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "lambda-stop-ec2" {
  name        = "lambda-${var.lambda_function_name}-policy"
  path        = "/"
  description = "Permissions for lambdas to stop EC2 instances"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:Stop*"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:CreateLogGroup",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda-attach" {
  role       = aws_iam_role.lambda-stop-ec2.name
  policy_arn = aws_iam_policy.lambda-stop-ec2.arn
}

resource "aws_cloudwatch_log_group" "stop_group" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 7
}

resource "aws_cloudwatch_event_rule" "daily_schedule" {
  name = var.lambda_function_name
  description = "Run lambda daily to stop up instances"
  schedule_expression = "cron(30 22 ? * Mon-Fri *)"

}

resource "aws_lambda_function" "stop_ec2_daily" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda-stop-ec2.arn
  handler       = var.lambda_handler
  description   = "Stop EC2 instances that do not have the LeaveOn True tag applied"
  memory_size = 512
  publish = false
  filename      = var.filename
  source_code_hash = filebase64sha256(var.filename)
  runtime = "dotnetcore3.1"
  timeout = 90
  depends_on = [
    aws_iam_role_policy_attachment.lambda-attach,
    aws_cloudwatch_log_group.stop_group,
  ]
}

resource "aws_cloudwatch_event_target" "daily_lambda" {
  rule = aws_cloudwatch_event_rule.daily_schedule.id
  arn = aws_lambda_function.stop_ec2_daily.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_schedule.arn
}
