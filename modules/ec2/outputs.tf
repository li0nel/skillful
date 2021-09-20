output "ec2" {
  value = aws_instance.ec2
}

output "public_key_filename" {
    value = local.public_key_filename
}

output "private_key_filename" {
    value = local.private_key_filename
}