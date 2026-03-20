# ========================================
# Security Group for ALB
# ========================================
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "ALB security group"
  vpc_id      = var.vpc_id

  # Ingress from allowed clients
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_client_cidrs
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_client_cidrs
  }

  # Outbound traffic: default allow all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-alb-sg"
  }
}

# ========================================
# Security Group for App Instances
# ========================================
resource "aws_security_group" "app" {
  name        = "${var.name}-app-sg"
  description = "App instances security group"
  vpc_id      = var.vpc_id

  # Ingress: allow HTTP from ALB
  ingress {
    from_port       = var.app_port   # usually 80
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Egress: allow HTTPS to secureweb.com
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-app-sg"
  }
}

# ========================================
# Security Group for Database
# ========================================
resource "aws_security_group" "db" {
  name        = "${var.name}-db-sg"
  description = "Database security group"
  vpc_id      = var.vpc_id

  # Ingress: allow MySQL from App SG only
  ingress {
    from_port       = var.db_port   # usually 3306
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  # Egress: allow HTTPS for backups or other outgoing connections
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-db-sg"
  }
}
