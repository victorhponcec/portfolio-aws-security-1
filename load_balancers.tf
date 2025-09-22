#LB - Internet Facing
resource "aws_lb" "lba" {
  name               = "lba-internet"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lba.id]
  subnets            = [aws_subnet.public_a_az1.id, aws_subnet.public_b_az2.id]
}

#Target Groups
resource "aws_lb_target_group" "tg_a" {
  name     = "tg-a"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

#Listener
resource "aws_lb_listener" "listner" {
  load_balancer_arn = aws_lb.lba.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "forward"
    forward {
      target_group {
        arn    = aws_lb_target_group.tg_a.arn
        weight = 100
      }
    }
  }
}

#associate ASG with LB's Target Group
resource "aws_autoscaling_attachment" "asg_lb" {
  autoscaling_group_name = aws_autoscaling_group.asg_1.id
  lb_target_group_arn    = aws_lb_target_group.tg_a.arn
}