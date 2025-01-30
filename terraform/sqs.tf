resource "aws_sqs_queue" "dlq" {
  name              = "my-dlq"
  kms_master_key_id = aws_kms_key.custom_kms.arn
  tags = {
    Name = "my-dlq"
  }
}

resource "aws_sqs_queue" "main_queue" {
  name                       = "my-main-queue"
  kms_master_key_id          = aws_kms_key.custom_kms.arn
  message_retention_seconds  = 1209600 # 14 days
  visibility_timeout_seconds = 60
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })
  tags = {
    Name = "my-main-queue"
  }
}
