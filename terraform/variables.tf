variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "cloudfront_ports" {
  type        = set(number)
  description = "List of allowed ports for CloudFront"
  default     = [80, 443]
}

variable "ecs_ingress_ports" {
  type        = set(number)
  description = "Ingress ports for ECS microservices"
  default     = [3000, 50051]
}

variable "domain_name" {
  type    = string
  default = "example.com"
}

variable "subdomain" {
  type    = string
  default = "app"
}

variable "service_alerts" {
  type = map(object({
    cpu = object({
      threshold = number
      period    = number
    })
    memory = object({
      threshold = number
      period    = number
    })
  }))

  default = {
    "frontend" = {
      cpu = {
        threshold = 60
        period    = 60
      }
      memory = {
        threshold = 60
        period    = 120
      }
    },
    "service_a" = {
      cpu = {
        threshold = 70
        period    = 60
      }
      memory = {
        threshold = 75
        period    = 120
      }
    },
    "service_b" = {
      cpu = {
        threshold = 80
        period    = 60
      }
      memory = {
        threshold = 80
        period    = 120
      }
    }
  }
}

variable "alerting_chatbot_secrets" {
  type        = set(string)
  description = "Secrets for Chatbot"
  default     = ["slack-workspace-id", "slack-channel-id"]
}
