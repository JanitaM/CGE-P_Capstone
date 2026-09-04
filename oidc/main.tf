terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}

provider "aws" { region = "us-east-1" }

variable "github_org"  { type = string }
variable "github_repo" { type = string }
variable "project_name" {
  type    = string
  default = "cgep-lab"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "vault_name" {
  type        = string
  description = "S3 bucket name of the GRC evidence vault (terraform/primitives/evidence-vault output vault_name)."
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "grc_gate" {
  name = "cgep-grc-gate"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github.arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = [
            "repo:${var.github_org}/${var.github_repo}:pull_request",
            "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"
          ]
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "grc_gate_scoped" {
  name = "cgep-grc-gate-s3-plan"
  role = aws_iam_role.grc_gate.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "S3BucketPlanRead"
      Effect = "Allow"
      Action = [
        "s3:GetBucketLocation",
        "s3:GetBucketAcl",
        "s3:GetBucketPolicy",
        "s3:GetBucketTagging",
        "s3:GetBucketVersioning",
        "s3:GetBucketLogging",
        "s3:GetBucketOwnershipControls",
        "s3:GetEncryptionConfiguration",
        "s3:GetBucketPublicAccessBlock",
        "s3:GetBucketRequestPayment",
        "s3:GetBucketWebsite",
        "s3:GetBucketCORS",
        "s3:GetLifecycleConfiguration",
        "s3:GetReplicationConfiguration",
        "s3:GetAccelerateConfiguration",
        "s3:GetBucketNotification",
        "s3:GetBucketObjectLockConfiguration",
        "s3:ListBucket"
      ]
      Resource = [
        "arn:aws:s3:::${var.project_name}-${var.environment}-data-*",
        "arn:aws:s3:::${var.project_name}-${var.environment}-logs-*"
      ]
    }]
  })
}

resource "aws_iam_role_policy" "grc_gate_evidence_vault" {
  name = "cgep-grc-gate-evidence-vault"
  role = aws_iam_role.grc_gate.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "EvidenceVaultWrite"
      Effect = "Allow"
      Action = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:GetObjectRetention"
      ]
      Resource = [
        "arn:aws:s3:::${var.vault_name}",
        "arn:aws:s3:::${var.vault_name}/*"
      ]
    }]
  })
}

output "role_arn" { value = aws_iam_role.grc_gate.arn }