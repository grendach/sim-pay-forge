# modules/db-ec2/main.tf

data "aws_ssm_parameter" "al2023" {
  name   = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "this" {
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.db_sg_id]
  monitoring             = true

  tags = {
    Name = "${var.name}-db"
  }

  user_data = base64encode(templatefile("${path.module}/user_data.tpl"))
}
