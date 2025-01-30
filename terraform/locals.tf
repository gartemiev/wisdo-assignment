locals {
  service_name_map = {
    "frontend"  = aws_ecs_service.frontend_svc.name
    "service_a" = aws_ecs_service.service_a_svc.name
    "service_b" = aws_ecs_service.service_b_svc.name
  }
}
