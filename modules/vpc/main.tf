data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = var.stack_name
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "public_subnets" {
  for_each          = toset(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, index(data.aws_availability_zones.available.names, each.value))
  availability_zone = each.value
}

resource "aws_route_table" "public_routetable" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
}

resource "aws_route_table_association" "public_rt_associations" {
  for_each       = toset(data.aws_availability_zones.available.names)
  subnet_id      = aws_subnet.public_subnets[each.key].id
  route_table_id = aws_route_table.public_routetable.id
}

# resource "aws_nat_gateway" "nat_gateway" {
#   count         = var.b_nat_gateway == true ? 1 : 0
#   allocation_id = aws_eip.eips[count.index].id
#   subnet_id     = aws_subnet.public_subnets[0].id

#   depends_on = [aws_internet_gateway.internet_gateway]
# }

# resource "aws_subnet" "private_subnets" {
#   for_each = data.aws_availability_zones.available.names
#   vpc_id            = aws_vpc.vpc.id
#   cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 8, each.key + length(data.aws_availability_zones.available.names))
#   availability_zone = each.value
# }

# resource "aws_route_table" "private_routetable" {
#   vpc_id = aws_vpc.vpc.id
# }

# resource "aws_route" "route" {
#   count                  = var.b_nat_gateway == true ? 1 : 0
#   route_table_id         = aws_route_table.private_routetable.id
#   destination_cidr_block = "0.0.0.0/0"
#   depends_on             = [aws_route_table.private_routetable]
#   nat_gateway_id         = aws_nat_gateway.nat_gateway[count.index].id
# }

# resource "aws_route_table_association" "private_rt_associations" {
#   for_each = data.aws_availability_zones.available.names
#   subnet_id      = aws_subnet.public_subnets[each.key].id
#   route_table_id = aws_route_table.private_routetable.id
# }

# // Gateway VPC endpoint
# data "aws_vpc_endpoint_service" "s3" {
#   service = "s3"
# }

# resource "aws_vpc_endpoint" "s3" {
#   vpc_id       = aws_vpc.vpc.id
#   service_name = data.aws_vpc_endpoint_service.s3[0].service_name
# }

# resource "aws_vpc_endpoint_route_table_association" "s3" {
#   vpc_endpoint_id = aws_vpc_endpoint.s3.id
#   route_table_id  = aws_route_table.private_routetable.id
# }

# // Interface VPC endpoints
# data "aws_vpc_endpoint_service" "ecs" {
#   service = "ecs"
# }

# data "aws_vpc_endpoint_service" "ecr" {
#   service = "ecr"
# }

# resource "aws_security_group" "vpc_endpoint" {
#   name   = "vpc-endpoint-${var.stack_name}"
#   vpc_id = aws_vpc.vpc.id

#   ingress {
#     protocol        = "tcp"
#     from_port       = 0
#     to_port         = 0
#     cidr_blocks = aws_subnet.private_subnets.*.cidr_blocks
#   }

#   egress {
#     protocol    = "-1"
#     from_port   = 0
#     to_port     = 0
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_vpc_endpoint" "ecs" {
#   count = length(data.aws_vpc_endpoint_service.ecs)

#   vpc_id       = aws_vpc.vpc.id
#   service_name = data.aws_vpc_endpoint_service.ecs.*.service_name[count.index]
#   vpc_endpoint_type = "Interface"
#   subnet_ids = aws_subnet.private_subnets.*.id
#   security_group_ids = [aws_security_group.vpc_endpoint.id]
#   private_dns_enabled = true
# }

# resource "aws_vpc_endpoint" "ecr" {
#   count = length(data.aws_vpc_endpoint_service.ecr)

#   vpc_id       = aws_vpc.vpc.id
#   service_name = data.aws_vpc_endpoint_service.ecr.*.service_name[count.index]
#   vpc_endpoint_type = "Interface"
#   subnet_ids = aws_subnet.private_subnets.*.id
#   security_group_ids = [aws_security_group.vpc_endpoint.id]
#   private_dns_enabled = true
# }

# resource "aws_lb" "nlb" {
#   name = var.stack_name

#   load_balancer_type = "network"

#   internal = true
#   subnets  = values(aws_subnet.public_subnets).*.id
# }

# resource "aws_api_gateway_vpc_link" "vpc_link" {
#   name        = var.stack_name
#   target_arns = [aws_lb.nlb.arn]
# }

# resource "aws_lb_target_group" "default_target_group" {
#   name     = var.stack_name
#   protocol = "TCP"
#   port     = 8529
#   vpc_id   = aws_vpc.vpc.id
# //  stickiness = []
# }

# resource "aws_lb_listener" "listener" {
#   load_balancer_arn = aws_lb.nlb.arn
#   port              = 8529
#   protocol          = "TCP"

#   default_action {
#     target_group_arn = aws_lb_target_group.default_target_group.arn
#     type             = "forward"
#   }
# }
