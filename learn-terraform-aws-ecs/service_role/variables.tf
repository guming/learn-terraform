variable "policy_document" {
  type = object({
    actions = list(string)
    effect = string
    type = string
    identifiers = list(string)
  })
  default =  {
      actions     = ["sts:AssumeRole"]
      effect      = "Allow"
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
}

variable "iam_role_name" {
  type = string
  default = "task-execution-role"
}

variable "iam_policy_arn" {
  type = string
  default = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

