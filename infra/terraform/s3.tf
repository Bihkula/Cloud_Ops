# =============================================================================
# S3 buckets used by the project (the Terraform *state* bucket itself lives in
# ./bootstrap, since it must exist before this config can use an S3 backend).
#
#   1. kops state store  -> KOPS_STATE_STORE for the cluster
#   2. artifacts         -> general object storage for the project
# Both are private, versioned, and encrypted.
# =============================================================================

# random suffix keeps bucket names globally unique without hand-editing.
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ---- Kops state store -------------------------------------------------------
resource "aws_s3_bucket" "kops_state" {
  bucket = "${local.name_prefix}-kops-state-${random_id.bucket_suffix.hex}"

  tags = { Name = "${local.name_prefix}-kops-state" }
}

resource "aws_s3_bucket_versioning" "kops_state" {
  bucket = aws_s3_bucket.kops_state.id
  versioning_configuration {
    status = "Enabled" # kops relies on versioning to protect cluster state
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "kops_state" {
  bucket = aws_s3_bucket.kops_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "kops_state" {
  bucket                  = aws_s3_bucket.kops_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---- Artifacts / general storage -------------------------------------------
resource "aws_s3_bucket" "artifacts" {
  bucket = "${local.name_prefix}-artifacts-${random_id.bucket_suffix.hex}"

  tags = { Name = "${local.name_prefix}-artifacts" }
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---- Lifecycle hygiene (free): tidy old versions + abandoned uploads --------
resource "aws_s3_bucket_lifecycle_configuration" "kops_state" {
  bucket = aws_s3_bucket.kops_state.id
  rule {
    id     = "expire-noncurrent-and-cleanup"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  rule {
    id     = "expire-noncurrent-and-cleanup"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
