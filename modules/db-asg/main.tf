data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# ========================================
# LAUNCH TEMPLATE
# ========================================

resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-db-lt-"
  image_id      = data.aws_ssm_parameter.al2023.value
  instance_type = var.instance_type

  vpc_security_group_ids = [var.db_sg_id]

  user_data = base64encode(templatefile("${path.module}/user_data.tpl", {
    mysql_root_password = var.mysql_root_password
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name}-db"
    }
  }
}

# ========================================
# AUTOSCALING GROUP (DB = SINGLE INSTANCE)
# ========================================

resource "aws_autoscaling_group" "this" {
  name                = "${var.name}-db-asg"
  vpc_zone_identifier = [var.subnet_id] # single subnet is OK for POC

  min_size         = 1
  max_size         = 1
  desired_capacity = 1

  health_check_type         = "EC2"
  health_check_grace_period = 300
  force_delete              = true

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 0
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-db"
    propagate_at_launch = true
  }
}
