terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "random_string" "rand4" {
  length  = 4
  special = false
  upper   = false
}

# create repo of ecr
# module "ecr_example_complete" {
#   source  = "terraform-module/ecr/aws"
#   version = "1.0.3"
#   ecrs = {
#     api = {
#       tags = { Service = "api" }
#       lifecycle_policy = {
#         rules = [{
#           rulePriority = 1
#           description  = "keep last 50 images"
#           action = {
#             type = "expire"
#           }
#           selection = {
#             tagStatus   = "any"
#             countType   = "imageCountMoreThan"
#             countNumber = 10
#           }
#         }]
#       }
#     }
#   }
# }

# vpc created
module "vpc_subnet_module" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "=3.14.0"

  name                 = var.vpc_subnet_module.name
  cidr                 = var.vpc_subnet_module.cidr_block

  azs                  = var.vpc_subnet_module.azs
  private_subnets      = var.vpc_subnet_module.private_subnets
  public_subnets       = var.vpc_subnet_module.public_subnets

  enable_ipv6          = var.vpc_subnet_module.enable_ipv6
  enable_nat_gateway   = var.vpc_subnet_module.enable_nat_gateway
  enable_vpn_gateway   = var.vpc_subnet_module.enable_vpn_gateway
  enable_dns_hostnames = var.vpc_subnet_module.enable_dns_hostnames
  enable_dns_support   = var.vpc_subnet_module.enable_dns_support

  tags = var.tags
}

# ecs cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.name
  tags = var.tags
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# security group for lb
resource "aws_security_group" "http" {
  name        = var.aws_security_group_http.name
  description = var.aws_security_group_http.description
  vpc_id      = module.vpc_subnet_module.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "egress_all" {
  name        = var.aws_security_group_egress_all.name
  description = var.aws_security_group_egress_all.description
  vpc_id      = module.vpc_subnet_module.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# alb
resource "aws_alb" "application_load_balancer" {
  name               = var.alb.name
  internal           = var.alb.internal
  load_balancer_type = var.alb.load_balancer_type

  subnets = module.vpc_subnet_module.public_subnets

  security_groups = [
    aws_security_group.http.id,
    aws_security_group.egress_all.id,
  ]
}

# service_role
module "ecs_task_execution_role" {
  source = "./service_role"
  policy_document = {
    actions = var.ecs_task_execution_role.policy_document.actions
    effect = var.ecs_task_execution_role.policy_document.effect
    type = var.ecs_task_execution_role.policy_document.type
    identifiers = var.ecs_task_execution_role.policy_document.identifiers
  }
  iam_role_name = var.ecs_task_execution_role.iam_role_name
  iam_policy_arn = var.ecs_task_execution_role.iam_policy_arn
}

module "ecs_autoscale_role" {
  source = "./service_role"
  policy_document = {
    actions = var.ecs_autoscale_role.policy_document.actions
    effect = var.ecs_autoscale_role.policy_document.effect
    type = var.ecs_autoscale_role.policy_document.type
    identifiers = var.ecs_autoscale_role.policy_document.identifiers
  }
  iam_role_name = var.ecs_autoscale_role.iam_role_name
  iam_policy_arn = var.ecs_autoscale_role.iam_policy_arn
}

resource "aws_ecs_task_definition" "ecs_task" {
  family                = var.ecs_task.family
  cpu                 = var.ecs_task.cpu
  memory              = var.ecs_task.memory
  container_definitions = jsonencode([{
    name                = var.ecs_task.container_image_name
    image               = var.ecs_task.container_image
    essential           = true
    portMappings = [{
      containerPort     = var.ecs_task.container_image_port
    }]
  }])
  requires_compatibilities = var.ecs_task.requires_compatibilities
  network_mode             = var.ecs_task.network_mode
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
}

resource "aws_ecs_service" "ecs_service" {
  name            = var.ecs_service.name
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task.arn
  launch_type     = var.ecs_service.launch_type
  desired_count   = var.ecs_service.desired_count

  load_balancer {
    target_group_arn = aws_lb_target_group.ghost_api.arn
    container_name   = var.ecs_task.container_image_name
    container_port   = var.ecs_task.container_image_port
  }

  network_configuration {
    assign_public_ip = false

    security_groups = [
      aws_security_group.egress_all.id,
      aws_security_group.ingress_api.id,
    ]

    subnets = module.vpc_subnet_module.private_subnets
  }
}

resource "aws_lb_target_group" "ghost_api" {
  name        = "ghost-api"
  port        = var.ecs_task.container_image_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc_subnet_module.vpc_id

  health_check {
    enabled = true
    path    = "/"
  }
}

resource "aws_alb_listener" "http_listener" {
  load_balancer_arn = aws_alb.application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ghost_api.arn
  }
}

resource "aws_security_group" "ingress_api" {
  name        = "ingress-api"
  description = "Allow ingress to API"
  vpc_id      = module.vpc_subnet_module.vpc_id

  ingress {
    from_port   = var.ecs_task.container_image_port
    to_port     = var.ecs_task.container_image_port
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  min_capacity       = 1
  max_capacity       = 3
  resource_id        = "service/${aws_ecs_cluster.ecs_cluster.id}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  role_arn           = module.ecs_autoscale_role.iam_role_arn
}

resource "aws_appautoscaling_policy" "appautoscaling_policy_cpu" {
  name               = "application-scale-policy-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 80
  }
}

resource "aws_appautoscaling_policy" "appautoscaling_policy_memory" {
  name               = "application-scale-policy-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = 80
  }
}
