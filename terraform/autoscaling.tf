## Frontend scaling
resource "aws_appautoscaling_target" "frontend_asg" {
  max_capacity       = 10
  min_capacity       = 2
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.frontend_svc.name}"
  scalable_dimension = "ecs:service:DesiredCount"
}

resource "aws_cloudwatch_metric_alarm" "frontend_latency_high" {
  alarm_name          = "frontend-latency-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 0.5
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Average"
  period              = 60
  alarm_description   = "Scale up if ALB latency > 0.5s"

  # The actual scale-out occurs by calling the scaling policy's ARN
  alarm_actions = [
    aws_appautoscaling_policy.frontend_scale_out.arn
  ]

  dimensions = {
    LoadBalancer = aws_lb.alb.name
    TargetGroup  = aws_lb_target_group.frontend_tg.name
  }
}

resource "aws_appautoscaling_policy" "frontend_scale_out" {
  name               = "frontend-latency-scale-out"
  policy_type        = "StepScaling"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.frontend_asg.resource_id
  scalable_dimension = aws_appautoscaling_target.frontend_asg.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}


# If latency is less than 0.3
# we assume we can safely scale in.
resource "aws_cloudwatch_metric_alarm" "frontend_latency_low" {
  alarm_name          = "frontend-latency-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  threshold           = 0.3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  statistic           = "Average"
  period              = 60
  alarm_description   = "Scale down if ALB latency < 0.3s"

  alarm_actions = [
    aws_appautoscaling_policy.frontend_scale_in.arn
  ]

  dimensions = {
    LoadBalancer = aws_lb.alb.name
    TargetGroup  = aws_lb_target_group.frontend_tg.name
  }
}

resource "aws_appautoscaling_policy" "frontend_scale_in" {
  name               = "frontend-latency-scale-in"
  policy_type        = "StepScaling"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.frontend_asg.resource_id
  scalable_dimension = aws_appautoscaling_target.frontend_asg.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

## Service B scaling
resource "aws_appautoscaling_target" "service_b_asg" {
  max_capacity       = 10
  min_capacity       = 2
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.service_b_svc.name}"
  scalable_dimension = "ecs:service:DesiredCount"
}

resource "aws_cloudwatch_metric_alarm" "service_b_queue_high" {
  alarm_name          = "service-b-queue-high"
  comparison_operator = "GreaterThanThreshold"
  threshold           = 20
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  statistic           = "Average"
  period              = 60
  alarm_description   = "Scale out Service B if queue length is high"

  alarm_actions = [
    aws_appautoscaling_policy.service_b_scale_out.arn
  ]

  dimensions = {
    QueueName = aws_sqs_queue.main_queue.name
  }
}

resource "aws_appautoscaling_policy" "service_b_scale_out" {
  name               = "service-b-queue-scale-out"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.service_b_asg.resource_id
  scalable_dimension = aws_appautoscaling_target.service_b_asg.scalable_dimension
  service_namespace  = aws_appautoscaling_target.service_b_asg.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

# If the queue not overflown (Average of 10 messages) for 2 consecutive periods (2 minutes),
# we assume we can safely scale in.
resource "aws_cloudwatch_metric_alarm" "service_b_queue_low" {
  alarm_name          = "service-b-queue-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = 10
  evaluation_periods  = 2
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  statistic           = "Average"
  period              = 60
  alarm_description   = "Scale in Service B if queue is empty"

  alarm_actions = [
    aws_appautoscaling_policy.service_b_scale_in.arn
  ]

  dimensions = {
    QueueName = aws_sqs_queue.main_queue.name
  }
}

resource "aws_appautoscaling_policy" "service_b_scale_in" {
  name               = "service-b-queue-scale-in"
  policy_type        = "StepScaling"
  service_namespace  = "ecs"
  resource_id        = aws_appautoscaling_target.service_b_asg.resource_id
  scalable_dimension = aws_appautoscaling_target.service_b_asg.scalable_dimension

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 120
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}
