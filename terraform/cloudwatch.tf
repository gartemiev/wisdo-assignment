####################################### Logging #######################################
# For the frontend
resource "aws_cloudwatch_log_group" "frontend_logs" {
  name              = "/ecs/frontend"
  retention_in_days = 30
}

# For service A
resource "aws_cloudwatch_log_group" "service_a_logs" {
  name              = "/ecs/service-a"
  retention_in_days = 30
}

# For service B
resource "aws_cloudwatch_log_group" "service_b_logs" {
  name              = "/ecs/service-b"
  retention_in_days = 30
}

####################################### Alerts #######################################
resource "aws_sns_topic" "alarm_topic" {
  name              = "cloudwatch-alarms-topic"
  kms_master_key_id = aws_kms_key.custom_kms.id
}

resource "aws_chatbot_slack_channel_configuration" "alarms_slack" {
  configuration_name = "my-alarms-to-slack"
  slack_team_id      = aws_ssm_parameter.alerting_chatbot_secrets["slack-workspace-id"].value
  slack_channel_id   = aws_ssm_parameter.alerting_chatbot_secrets["slack-channel-id"].value
  iam_role_arn       = aws_iam_role.alerting_chatbot_role.arn
  sns_topic_arns     = [aws_sns_topic.alarm_topic.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  for_each = var.service_alerts

  alarm_name          = "${each.key}-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  statistic           = "Average"
  threshold           = each.value.cpu.threshold
  period              = each.value.cpu.period
  alarm_description   = "CPU usage > ${each.value.cpu.threshold}% on ${each.key} for ${each.value.cpu.period} seconds"
  alarm_actions       = [aws_sns_topic.alarm_topic.arn]
  ok_actions          = [aws_sns_topic.alarm_topic.arn]

  dimensions = {
    ServiceName = local.service_name_map[each.key]
    ClusterName = aws_ecs_cluster.main.name
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_alarm" {
  for_each = var.service_alerts

  alarm_name          = "${each.key}-memory-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  statistic           = "Average"
  threshold           = each.value.memory.threshold
  period              = each.value.memory.period
  alarm_description   = "Memory usage > ${each.value.memory.threshold}% on ${each.key} for ${each.value.memory.period} seconds"
  alarm_actions       = [aws_sns_topic.alarm_topic.arn]
  ok_actions          = [aws_sns_topic.alarm_topic.arn]

  dimensions = {
    ServiceName = local.service_name_map[each.key]
    ClusterName = aws_ecs_cluster.main.name
  }
}

