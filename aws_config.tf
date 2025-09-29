
resource "random_string" "bucket_config" {
  length  = 10
  upper   = false
  special = false
}
resource "aws_s3_bucket" "aws_config" {
  bucket        = "main-config-${random_string.bucket_config.result}"
  force_destroy = true
}

resource "aws_s3_bucket_policy" "allow_aws_config" {
  bucket = aws_s3_bucket.aws_config.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.aws_config.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "config.amazonaws.com"
        },
        Action   = "s3:GetBucketAcl",
        Resource = aws_s3_bucket.aws_config.arn
      }
    ]
  })
}

resource "aws_iam_service_linked_role" "aws_config" {
  aws_service_name = "config.amazonaws.com"
}

resource "aws_config_configuration_recorder" "aws_config" {
  name     = "aws-config"
  role_arn = aws_iam_service_linked_role.aws_config.arn
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "aws_config" {
  name           = "config-bucket"
  s3_bucket_name = aws_s3_bucket.aws_config.bucket
  depends_on     = [aws_config_configuration_recorder.aws_config]
}

resource "aws_config_configuration_recorder_status" "aws_config" {
  name       = aws_config_configuration_recorder.aws_config.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.aws_config]
}