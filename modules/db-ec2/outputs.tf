output "db_instance_id" {
  value = aws_instance.this.id
}

output "db_private_ip" {
  value = aws_instance.this.private_ip
}
