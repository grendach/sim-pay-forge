variable "name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "db_sg_id" {
  type = string
}

variable "db_ami_id" {
  type    = string
  default = ""
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "mysql_root_password" {
  type      = string
  sensitive = true
}
