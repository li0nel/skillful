output "vpc" {
  value = aws_vpc.vpc
}

output "public_subnets" {
  value = aws_subnet.public_subnets
}

# output "internet_gateway" {
#   value = aws_internet_gateway.internet_gateway
# }

# output "aws_lb" {
#   value = aws_lb.nlb
# }

# output "aws_api_gateway_vpc_link" {
#   value = aws_api_gateway_vpc_link.vpc_link
# }

# output "aws_lb_target_group" {
#   value = aws_lb_target_group.default_target_group
# }