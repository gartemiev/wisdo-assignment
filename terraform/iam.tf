resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ecs-tasks.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags               = { Name = "ecsTaskExecutionRole" }
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# Frontend Task Role
resource "aws_iam_role" "ecs_task_role_frontend" {
  name               = "ecsTaskRole-frontend"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ecs-tasks.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags               = { Name = "ecsTaskRole-frontend" }
}

# Service A Task Role
resource "aws_iam_role" "ecs_task_role_service_a" {
  name               = "ecsTaskRole-serviceA"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ecs-tasks.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags               = { Name = "ecsTaskRole-serviceA" }
}

# Inline policy for SSM + KMS + SQS:SendMessage
resource "aws_iam_policy" "service_a_ssm_policy" {
  name   = "serviceA-ssm-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowGetMongoParameter",
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParameterHistory",
        "kms:Decrypt"
      ],
      "Resource": [
        "${aws_ssm_parameter.mongodb_uri.arn}",
        "${aws_ssm_parameter.mongodb_uri.arn}*"
      ]
    },
    {
      "Sid": "AllowSendMessages",
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage",
        "sqs:GetQueueUrl",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "${aws_sqs_queue.main_queue.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "service_a_ssm_attach" {
  role       = aws_iam_role.ecs_task_role_service_a.name
  policy_arn = aws_iam_policy.service_a_ssm_policy.arn
}


# Service B Task Role
resource "aws_iam_role" "ecs_task_role_service_b" {
  name               = "ecsTaskRole-serviceB"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ecs-tasks.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags               = { Name = "ecsTaskRole-serviceB" }
}

# Inline policy for SSM + KMS + SQS:Receive/Delete
resource "aws_iam_policy" "service_b_ssm_policy" {
  name   = "serviceB-ssm-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowGetMongoParameter",
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParameterHistory",
        "kms:Decrypt"
      ],
      "Resource": [
        "${aws_ssm_parameter.mongodb_uri.arn}",
        "${aws_ssm_parameter.mongodb_uri.arn}*"
      ]
    },
    {
      "Sid": "AllowConsumeMessages",
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueUrl",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "${aws_sqs_queue.main_queue.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "service_b_ssm_attach" {
  role       = aws_iam_role.ecs_task_role_service_b.name
  policy_arn = aws_iam_policy.service_b_ssm_policy.arn
}

# GITHUB OIDC PROVIDER
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  # The official thumbprint for token.actions.githubusercontent.com
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  # This allows the STS::AssumeRole call from GitHub
  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "github_actions_infra_role" {
  name               = "InfraTerraformRole"
  description        = "IAM role for GitHub Actions to run Terraform (plan/apply)."
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${aws_iam_openid_connect_provider.github.arn}"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:myorg/infra:ref:refs/heads/main"
          ]
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "github_actions_infra_admin" {
  role       = aws_iam_role.github_actions_infra_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Microservice deployment role
resource "aws_iam_role" "github_deploy_role" {
  name               = "GitHubActionsDeploymentRole"
  description        = "Role for GitHub Actions to deploy to ECS and push images to ECR"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${aws_iam_openid_connect_provider.github.arn}"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:myorg/frontend:ref:refs/heads/main",
            "repo:myorg/service-a:ref:refs/heads/main",
            "repo:myorg/service-b:ref:refs/heads/main"
          ]
        }
      }
    }
  ]
}
EOF
  tags = {
    Project = "GitHubActionsDeployment"
  }
}

resource "aws_iam_policy" "github_deploy_policy" {
  name   = "GitHubActionsDeploymentPolicy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [

    {
      "Sid": "ECRPermissions",
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:CompleteLayerUpload",
        "ecr:GetAuthorizationToken",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart",
        "ecr:DescribeRepositories",
        "ecr:CreateRepository",
        "ecr:DeleteRepository",
        "ecr:ListTagsForResource",
        "ecr:TagResource",
        "ecr:UntagResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECSPermissions",
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeClusters",
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeTasks",
        "ecs:RegisterTaskDefinition",
        "ecs:UpdateService",
        "ecs:ListTasks",
        "ecs:StopTask",
        "ecs:TagResource",
        "ecs:UntagResource",
        "ecs:CreateService",
        "ecs:DeleteService"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowIamPassRole",
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskRole*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "deploy_role_attach" {
  role       = aws_iam_role.github_deploy_role.name
  policy_arn = aws_iam_policy.github_deploy_policy.arn
}

# Alerting chatbot role
resource "aws_iam_role" "alerting_chatbot_role" {
  name               = "alerting-chatbot-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "chatbot.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "alerting_chatbot_sns" {
  name   = "alerting-chatbot-sns-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowSpecificTopicAccess",
      "Effect": "Allow",
      "Action": [
        "sns:Subscribe",
        "sns:Unsubscribe",
        "sns:Publish",
        "sns:ListSubscriptionsByTopic",
        "sns:GetTopicAttributes"
      ],
      "Resource": "${aws_sns_topic.alarm_topic.arn}"
    },
    {
      "Sid": "AllowKmsDecryptForSns",
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey*"
      ],
      "Resource": "${aws_kms_key.custom_kms.arn}",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "sns.${var.aws_region}.amazonaws.com"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "chatbot_sns" {
  role       = aws_iam_role.alerting_chatbot_role.name
  policy_arn = aws_iam_policy.alerting_chatbot_sns.arn
}

resource "aws_iam_role_policy_attachment" "alerting_chatbot_cloudwatch" {
  role       = aws_iam_role.alerting_chatbot_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}
