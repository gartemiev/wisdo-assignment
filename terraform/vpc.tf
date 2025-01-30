module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.18.1"

  name = "ecs-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["use1-az1", "use1-az2"]
  private_subnets = ["10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_tags = {
    type = "private"
  }
  public_subnets = ["10.0.0.0/24", "10.0.1.0/24"]
  public_subnet_tags = {
    type = "public"
  }
  enable_nat_gateway            = true
  single_nat_gateway            = false
  one_nat_gateway_per_az        = true
  enable_dns_hostnames          = true
  enable_dns_support            = true
  manage_default_security_group = false
  manage_default_network_acl    = false
  enable_vpn_gateway            = false
}

# See more details in https://aws.amazon.com/blogs/apn/connecting-applications-securely-to-a-mongodb-atlas-data-plane-with-aws-privatelink/
resource "aws_vpc_endpoint" "atlas_data_endpoint" {
  vpc_id              = module.vpc.vpc_id
  vpc_endpoint_type   = "Interface"
  service_name        = "Value from MongoDB atlas"
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.ecs_tasks.id]
  private_dns_enabled = false
}
