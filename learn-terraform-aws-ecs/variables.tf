variable "region" {
  type = string
  default = "ap-southeast-1"
}

variable "aws_security_group_http" {
  type = object({
    name        = string
    description = string
  })
  default = {
    name        = "http"
    description = "HTTP traffic"
  }
}

variable "aws_security_group_egress_all" {
  type = object({
    name        = string
    description = string
  })
  default = {
    name        = "egress-all"
    description = "Allow all outbound traffic"
  }
}

variable "alb" {
  type = object({
    name               = string
    internal           = bool
    load_balancer_type = string
  })
  default = {
    name               = "ghost-alb"
    internal           = false
    load_balancer_type = "application"
  }
}


variable "name" {
  type = string
  default = "ecs_farget_example"
}



variable "vpc_subnet_module" {
  type = object({
    name                 = string
    cidr_block           = string
    azs                  = list(string)
    private_subnets      = list(string)
    public_subnets       = list(string)
    enable_ipv6          = bool
    enable_nat_gateway   = bool
    enable_vpn_gateway   = bool
    enable_dns_hostnames = bool
    enable_dns_support   = bool
  })
  default = {
    name                 = "ecs-vpc-subnet-network"
    cidr_block           = "10.0.0.0/16"
    azs                  = ["ap-southeast-1a", "ap-southeast-1b", "ap-southeast-1c"]
    private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    public_subnets       = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
    enable_ipv6          = false
    enable_nat_gateway   = true
    enable_vpn_gateway   = false
    enable_dns_hostnames = true
    enable_dns_support   = true
  }
}

variable "tags" {
  type = map(any)
  default = {
    name = "nodeapp"
  }
}

variable "ecs_autoscale_role" {
  type = object({
    policy_document = object({
      actions = list(string)
      effect = string
      type = string
      identifiers = list(string)
    })
    iam_role_name = string
    iam_policy_arn = string
  })
  default = {
    policy_document = {
      actions     = ["sts:AssumeRole"]
      effect      = "Allow"
      type        = "Service"
      identifiers = ["application-autoscaling.amazonaws.com"]
    }
    iam_role_name = "ecs-scale-application"
    iam_policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
  }
}

variable "ecs_task_execution_role" {
  type = object({
    policy_document = object({
      actions = list(string)
      effect = string
      type = string
      identifiers = list(string)
    })
    iam_role_name = string
    iam_policy_arn = string
  })
  default = {
    policy_document = {
      actions     = ["sts:AssumeRole"]
      effect      = "Allow"
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    iam_role_name = "task-execution-role"
    iam_policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  }
}

variable "ecs_task" {
  type = object({
    family                   = string
    container_image_name     = string
    container_image          = string
    cpu                      = number
    memory                   = number
    requires_compatibilities = list(string)
    network_mode             = string
    container_image_port     = number
  })
  default = {
    family                   = "ecs-task-family"
    container_image_name     = "ghost"
    container_image          = "ghost:alpine"
    container_image_port     = 2368
    cpu                      = 256
    memory                   = 512
    requires_compatibilities = ["FARGATE"]
    network_mode             = "awsvpc"
  }
}

variable "ecs_service" {
  type = object({
    name            = string
    launch_type     = string
    desired_count   = number
  })
  default = {
    name            = "ecs_service"
    launch_type     = "FARGATE"
    desired_count   = 3
  }
}




