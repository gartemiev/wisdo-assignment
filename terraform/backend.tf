terraform {
  required_version = "~> 1.6.6"
  backend "s3" {
    bucket = "terraform-state"
    key    = "terraform-state/infra"
    region = var.aws_region
  }
}
