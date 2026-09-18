output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "IPv4 CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets in availability-zone order."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets in availability-zone order."
  value       = aws_subnet.private[*].id
}

output "public_route_table_ids" {
  description = "IDs of public route tables."
  value       = [aws_route_table.public.id]
}

output "private_route_table_ids" {
  description = "IDs of private route tables in availability-zone order."
  value       = aws_route_table.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway."
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  description = "IDs of NAT gateways created by the selected NAT mode."
  value       = aws_nat_gateway.this[*].id
}

output "availability_zones" {
  description = "Availability zones used by the networking module."
  value       = var.availability_zones
}
