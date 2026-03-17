variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "target_group_port" {
  type    = number
  default = 80
}

variable "certificate_arn" {
  type = string
}

variable "environment" {
  type    = string
  default = "dev"
}
