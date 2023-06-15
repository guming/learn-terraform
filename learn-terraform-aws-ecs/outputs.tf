output "aws_alb_arn" {
  value = aws_alb.application_load_balancer.arn
}

output "aws_sg_egress_all_id" {
  value = aws_security_group.egress_all.id
}

output "alb_url" {
  value = "http://${aws_alb.application_load_balancer.dns_name}"
}

output "aws_ecs_cluster_id" {
  value = aws_ecs_cluster.ecs_cluster.id
}

output "vpc_id" {
  value = module.vpc_subnet_module.vpc_id
}

output "vpc_arn" {
  value = module.vpc_subnet_module.vpc_arn
}

output "vpc_public_subnets_ids" {
  value = module.vpc_subnet_module.public_subnets
}

output "vpc_private_subnets_ids" {
  value = module.vpc_subnet_module.private_subnets
}




