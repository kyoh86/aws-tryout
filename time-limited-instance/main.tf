provider "aws" {
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

data "aws_caller_identity" "self" {}

data "aws_ami" "arch" {
  owners = ["647457786197"]
  filter {
    name   = "name"
    values = ["arch-linux-ec2-hvm-????.??.??.x86_64-ebs"]
  }
}

variable "instance_lifespan" {
  type    = string
  default = "3h"
}

resource "aws_instance" "workspace" {
  ami           = data.aws_ami.arch.id
  instance_type = "t3.micro"
}

resource "aws_scheduler_schedule" "timeout_instance" {
  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:terminateInstances"
    role_arn = "arn:aws:iam::${data.aws_caller_identity.self.account_id}:role/instance_killer"
    input = jsonencode({
      "InstanceIds" : [aws_instance.workspace.id]
    })
  }
  flexible_time_window {
    mode = "OFF"
  }
  schedule_expression = "at(${formatdate("YYYY-MM-DD'T'hh:mm:ss", timeadd(timestamp(), var.instance_lifespan))})"
}
