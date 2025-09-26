resource "aws_flow_log" "vpc" {
  log_destination      = aws_s3_bucket.vpc_flow_logs.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
}

resource "random_string" "vpc_flow_logs" {
  length  = 10
  upper   = false
  special = false
}
resource "aws_s3_bucket" "vpc_flow_logs" {
  bucket        = "vpc-flow-logs-${random_string.vpc_flow_logs.result}"
  force_destroy = true
}
