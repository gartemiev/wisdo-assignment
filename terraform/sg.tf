resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "SG for ALB"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# https://docs.aws.amazon.com/vpc/latest/userguide/working-with-aws-managed-prefix-lists.html
# https://aws.amazon.com/about-aws/whats-new/2022/02/amazon-cloudfront-managed-prefix-list/?nc1=h_ls
resource "aws_security_group_rule" "alb_inbound_cloudfront" {
  for_each = var.cloudfront_ports

  type              = "ingress"
  description       = "Allow inbound from CloudFront on port ${each.value}"
  security_group_id = aws_security_group.alb_sg.id
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  from_port         = each.value
  to_port           = each.value
  protocol          = "tcp"
}

resource "aws_security_group" "ecs_tasks" {
  name        = "ecs-tasks-sg"
  description = "SG for ECS tasks"
  vpc_id      = module.vpc.vpc_id
  dynamic "ingress" {
    for_each = var.ecs_ingress_ports
    content {
      description     = "Allow inbound from ALB on port ${ingress.value}"
      from_port       = ingress.value
      to_port         = ingress.value
      protocol        = "tcp"
      security_groups = [aws_security_group.alb_sg.id]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-tasks-sg"
  }
}
