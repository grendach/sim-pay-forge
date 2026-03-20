variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "app_sg_id" {
  type = string
}


variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "alb_tg_arn" {
  type = string
}

variable "app_port" {
  type    = number
  default = 80
}

variable "required_package_repo_baseurl" {
  type = string
}

variable "required_package_name" {
  type = string
}
