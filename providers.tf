terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.3.0"
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