terraform {
  required_version = "1.12.2"

  backend "gcs" {
    bucket = "weatherscanner-tf-state-aws"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.95.0"
    }
    dns = {
      source = "hashicorp/dns"
      version = "3.4.3"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  profile = "default"
}

provider "aws" {
  region = "eu-west-1"
  profile = "anto11200"
  alias = "anto11200"
}
