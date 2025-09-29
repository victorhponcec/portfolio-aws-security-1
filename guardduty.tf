resource "aws_guardduty_detector" "guardduty" {
  enable = true
}

resource "aws_sns_topic" "sns_guardduty_finding" {
  name = "guardduty_finding"
}

resource "aws_sns_topic_subscription" "sns_guardduty_finding_email" {
  topic_arn = aws_sns_topic.sns_guardduty_finding.arn
  protocol  = "email"
  endpoint  = var.email
}

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "guardduty-findings"
  description = "Trigger on GuardDuty findings"
  event_pattern = jsonencode({
    source      = ["aws.guardduty"],
    detail-type = ["GuardDuty Finding"]
    detail : {
    severity : [9, 10] }
  })
}

resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.sns_guardduty_finding.arn
  role_arn  = aws_iam_role.eventbridge_to_sns.arn
}