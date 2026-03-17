resource "aws_instance" "this" {
  ami                    = var.db_ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.db_sg_id]
  monitoring             = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name = "${var.name}-db"
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y mysql-server
    systemctl enable mysqld
    systemctl start mysqld
    mysql_secure_installation <<SECURE
    y
    rootpass
    rootpass
    y
    y
    y
    y
    SECURE
  EOF
  )
}
