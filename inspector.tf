
resource "aws_inspector2_enabler" "enable_ec2" {
  resource_types = ["EC2"]
  account_ids    = [data.aws_caller_identity.current.account_id]
}

resource "aws_inspector2_filter" "tagged_instances" {
  name   = "asg-inspector-filter"
  action = "SUPPRESS" //SUPPRESS / NONE
  filter_criteria {
    resource_tags {
      comparison = "EQUALS"
      key        = "aws:autoscaling:groupName"
      value      = "ASG1"
    }
  }
}
