variable "region" {
  description = "The AWS region to create resources in"
  type        = string
}

provider "aws" {
  region = var.region
}

terraform {
  required_version = ">= 1.0"

  backend "s3" {
    # NOTE: populated by a .tfbackend file
  }
}
