#ASG WEB
resource "aws_launch_template" "web" {
  name_prefix   = "web"
  image_id      = "ami-05576a079321f21f8"
  instance_type = "t2.micro"
  #vpc_security_group_ids = [aws_security_group.web.id] #conficts with: network_interfaces.security_group
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web.id] #When a network interface is provided, the security groups must be a part of it
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_profile.name
  }
  user_data = filebase64("user_data.sh")
}

resource "aws_autoscaling_group" "asg_1" {
  name                 = "ASG1"
  desired_capacity     = 2
  max_size             = 4
  min_size             = 2
  health_check_type    = "EC2"
  termination_policies = ["OldestInstance"]
  vpc_zone_identifier  = [aws_subnet.public_a_az1.id, aws_subnet.public_b_az2.id]

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale_out"
  autoscaling_group_name = aws_autoscaling_group.asg_1.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 10
}

resource "aws_cloudwatch_metric_alarm" "scale_out" {
  alarm_name          = "scale_out"
  alarm_description   = "CPU Utilization"
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "AWS/EC2"        #for cloudwatch to monitor EC2 https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/aws-services-cloudwatch-metrics.html
  metric_name         = "CPUUtilization" # metrics for EC2: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/viewing_metrics_with_cloudwatch.html 
  threshold           = "70"
  evaluation_periods  = "2"
  period              = "30"
  statistic           = "Average"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg_1.name
  }
}

#ASG APP
resource "aws_launch_template" "app" {
  name_prefix   = "app"
  image_id      = "ami-05576a079321f21f8"
  instance_type = "t2.micro"
  #vpc_security_group_ids = [aws_security_group.web.id] #conficts with: network_interfaces.security_group
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app.id]
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_secrets_manager_profile.name
  }
  user_data = filebase64("user_data.sh")
}

resource "aws_autoscaling_group" "asg_2" {
  name                 = "ASG2"
  desired_capacity     = 2
  max_size             = 4
  min_size             = 2
  health_check_type    = "EC2"
  termination_policies = ["OldestInstance"]
  vpc_zone_identifier  = [aws_subnet.private_a_az1.id, aws_subnet.private_b_az2.id]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

resource "aws_autoscaling_policy" "asg2_scale_out" {
  name                   = "asg2_scale_out"
  autoscaling_group_name = aws_autoscaling_group.asg_2.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 10
}

resource "aws_cloudwatch_metric_alarm" "asg2_scale_out" {
  alarm_name          = "asg2_scale_out"
  alarm_description   = "CPU Utilization"
  alarm_actions       = [aws_autoscaling_policy.asg2_scale_out.arn]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = "70"
  evaluation_periods  = "2"
  period              = "30"
  statistic           = "Average"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg_2.name
  }
}

/*
 Stress Test EC2 instances:
  sudo amazon-linux-extras install epel -y
  sudo yum install stress -y
  sudo stress --cpu 8 --timeout 5800 &
  sudo killall stress
*/
