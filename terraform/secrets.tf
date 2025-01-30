resource "aws_ssm_parameter" "mongodb_uri" {
  name  = "/microservice-shared-secrets/mongodb-uri"
  type  = "SecureString"
  value = "placeholder"
  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "alerting_chatbot_secrets" {
  for_each = var.alerting_chatbot_secrets
  name     = "/alerting-chatbot-secrets/${each.value}"
  type     = "SecureString"
  value    = "placeholder"
  lifecycle {
    ignore_changes = [value]
  }
}
