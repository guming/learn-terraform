variable "child_iam_role_arn" {
  description = "The ARN of an IAM role to assume in the child AWS account"
  type        = string
  default = "arn:aws:iam::565289268108:role/OrganizationAccountAccessRole"
}