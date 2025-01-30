resource "aws_kms_key" "custom_kms" {
  description             = "KMS resource policy"
  enable_key_rotation     = true
  rotation_period_in_days = 90
}

resource "aws_kms_key_policy" "custom_kms_policy" {
  key_id = aws_kms_key.custom_kms.key_id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Id": "KMSKeyPolicy",
  "Statement": [
    {
      "Sid": "AllowSQSServiceUseOfKey",
      "Effect": "Allow",
      "Principal": {
        "Service": "sqs.amazonaws.com"
      },
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey*"
      ],
      "Resource": "${aws_kms_key.custom_kms.id}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sqs_queue.main_queue.arn}"
        }
      }
    },
    {
      "Sid": "AllowSNSServiceUseOfKey",
      "Effect": "Allow",
      "Principal": {
        "Service": "sqs.amazonaws.com"
      },
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey*"
      ],
      "Resource": "${aws_kms_key.custom_kms.id}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.alarm_topic.arn}"
        }
      }
    },
    {
      "Sid": "EnableKeyAdministrationForRoot",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
EOF
}
