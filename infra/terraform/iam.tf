# IAM policy meant to be attached to the Kops-managed node instance role
# (via `additionalPolicies` in the kops cluster spec) so K8s nodes can pull
# from ECR and read/write the app storage bucket, without hardcoding any
# AWS keys into the app or the cluster.
data "aws_iam_policy_document" "node_permissions" {
  statement {
    sid    = "ECRPull"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AppStorageAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.app_storage.arn,
      "${aws_s3_bucket.app_storage.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "node_permissions" {
  name        = "${var.project_name}-node-permissions"
  description = "ECR pull + app S3 bucket access for Kops-managed K8s nodes"
  policy      = data.aws_iam_policy_document.node_permissions.json
}
