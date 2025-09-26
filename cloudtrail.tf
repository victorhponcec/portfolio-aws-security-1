#Create a trail
resource "aws_cloudtrail" "main_trail" {
  depends_on = [aws_s3_bucket_policy.main_trail]

  name                          = "main_trail"
  s3_bucket_name                = aws_s3_bucket.main_trail.id
  s3_key_prefix                 = "trails"
  include_global_service_events = false
  enable_log_file_validation    = true
}

resource "random_string" "bucket" {
  length  = 10
  upper   = false
  special = false
}

resource "aws_s3_bucket" "main_trail" {
  bucket        = "main-trail-${random_string.bucket.result}"
  force_destroy = true
}

data "aws_iam_policy_document" "main_trail" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.main_trail.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/main_trail"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.main_trail.arn}/trails/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/main_trail"]
    }
  }
}

resource "aws_s3_bucket_policy" "main_trail" {
  bucket = aws_s3_bucket.main_trail.id
  policy = data.aws_iam_policy_document.main_trail.json
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

/*
===========check trails===============
//check in console /to do
$ aws cloudtrail lookup-events --max-items 10
*/