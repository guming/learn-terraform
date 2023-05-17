terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# We need to authenticate to the EKS cluster, but only after it has been created. We accomplish this by using the
# aws_eks_cluster_auth data source and having it depend on an output of the eks-cluster module.

provider "kubernetes" {
  host = module.eks_cluster.cluster_endpoint
  cluster_ca_certificate = base64decode(
    module.eks_cluster.cluster_certificate_authority[0].data
  )
  token = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.cluster_name
}

module "eks_cluster" {
  source = "../../modules/services/eks-farget"

  name = var.cluster_name

}



# Deploy a simple web app into the EKS cluster

# module "simple_webapp" {
#   source = "../../modules/services/k8s-app"

#   name = var.app_name

#   image          = "training/webapp"
#   replicas       = 2
#   container_port = 5000

#   environment_variables = {
#     PROVIDER = "Terraform"
#   }

#   # Only deploy the app after the cluster has been deployed
#   depends_on = [module.eks_cluster]
# }