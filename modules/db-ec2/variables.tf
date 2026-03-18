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
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}
variable "root_volume_size" {
  type    = number
  default = 30
}
