data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-lt-"
  image_id      = data.aws_ssm_parameter.al2023.value
  instance_type = var.instance_type
  vpc_security_group_ids = [var.app_sg_id]

  user_data = base64encode(templatefile("${path.module}/user_data.tpl", {
    app_port = var.app_port
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = var.name
    }
  }
}

resource "aws_autoscaling_group" "this" {
  name                = "${var.name}-asg"
  vpc_zone_identifier = var.private_subnet_ids

  target_group_arns = [var.alb_tg_arn]
  health_check_type = "ELB"

  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 1
  health_check_grace_period = 300
  force_delete              = true

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
    }

    triggers = ["launch_template"]
  }

  tag {
    key                 = "Name"
    value               = var.name
    propagate_at_launch = true
  }
}
