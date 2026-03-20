data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "this" {
  ami                    = var.db_ami_id != "" ? var.db_ami_id : data.aws_ssm_parameter.al2023.value
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  associate_public_ip_address = var.associate_public_ip
  vpc_security_group_ids = [var.db_sg_id]

  user_data = templatefile("${path.module}/user_data.tpl", {
    mysql_root_password = var.mysql_root_password
  })

  tags = {
    Name = "${var.name}-db"
  }
}
