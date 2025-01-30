provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      maintainer = "DevOps"
      owner      = "DevOps"
    }
  }
}
