variable "myregion" {
type = string
default = "us-east-1"
}

variable "accesskey" {
type = string
description = "Add your IAM access key"
sensitive = true
}


variable "secretkey" {
type = string
description = "Add your IAM secret key"
sensitive = true
}

variable "awstoken" {
type = string
description = "Add your IAM token"
sensitive = true
}