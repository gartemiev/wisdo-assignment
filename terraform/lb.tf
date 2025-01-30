resource "aws_lb" "alb" {
  name               = "app-alb"
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  internal           = false
  security_groups    = [aws_security_group.alb_sg.id]

  tags = {
    Name = "app-alb"
  }
}

# For Next.js (HTTP on port 3000)
resource "aws_lb_target_group" "frontend_tg" {
  name        = "frontend-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id
  health_check {
    path                = "/healthz"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
  tags = {
    Name = "frontend-tg"
  }
}

# For gRPC on port 50051
resource "aws_lb_target_group" "service_a_tg" {
  name             = "service-a-tg"
  port             = 50051
  protocol         = "HTTP"
  protocol_version = "GRPC"
  target_type      = "ip"
  vpc_id           = module.vpc.vpc_id

  health_check {
    path                = "/grpc/grpc.health.v1.Health/Check"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "0"
  }

  tags = {
    Name = "service-a-tg"
  }
}

# Single ALB listener on port 80
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_302"
    }
  }

  tags = {
    Name = "http-redirect-listener"
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.cloudfront_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }

  tags = {
    Name = "https-listener"
  }
}

# Rule to route /grpc/* to the gRPC service
resource "aws_lb_listener_rule" "grpc_rule" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service_a_tg.arn
  }

  condition {
    path_pattern {
      values = ["/grpc/*"]
    }
  }

  tags = {
    Name = "service-a-grpc-rule"
  }
}
