# =============================================================================
# IAM. Kops creates and manages the cluster's own node/master roles when it
# builds the cluster, so we deliberately DON'T create those here (doing so would
# fight kops). What we own is the policy the CI server needs to push images to
# ECR, plus the policy the nodes need to pull them and read the Secrets Manager
# entry above.
# =============================================================================

data "aws_caller_identity" "current" {}

# ---- CI push policy (attach to your Jenkins/GitLab runner role or user) -----
resource "aws_iam_policy" "ci_ecr_push" {
  name        = "${local.name_prefix}-ci-ecr-push"
  description = "Allows the CI pipeline to authenticate and push images to the ${var.app_name} ECR repo"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrAuth"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*" # GetAuthorizationToken cannot be scoped to a repo (AWS limitation)
      },
      {
        Sid    = "EcrPushPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = aws_ecr_repository.app.arn
      }
    ]
  })
}

# ---- Node access to the DATABASE_URL secret --------------------------------
# Attach to the kops node instance role (name is predictable once the cluster
# exists) so pods/CSI drivers can read the app's connection string.
resource "aws_iam_policy" "app_read_db_secret" {
  name        = "${local.name_prefix}-read-db-secret"
  description = "Allows reading the ${var.app_name} DATABASE_URL secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.database_url.arn
      }
    ]
  })
}
