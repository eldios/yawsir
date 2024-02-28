#------------------------------------------------------------------------------
# EKS SETUP
# https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
# https://github.com/terraform-aws-modules/terraform-aws-eks/
#------------------------------------------------------------------------------

################################################################################
# Supporting Resources for Temporal EKS and RDS
################################################################################

module "vpc" {
  #checkov:skip=CKV_TF_1: "Use commit instead when pinning modules"
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name

  cidr = var.cidr
  azs  = local.azs

  private_subnets  = [for k, v in local.azs : cidrsubnet(var.cidr, 4, k)]
  public_subnets   = [for k, v in local.azs : cidrsubnet(var.cidr, 8, k + 48)]
  intra_subnets    = [for k, v in local.azs : cidrsubnet(var.cidr, 8, k + 52)]
  database_subnets = [for k, v in local.azs : cidrsubnet(var.cidr, 8, k + 56)]

  create_database_subnet_group = false

  enable_dns_support   = true
  enable_dns_hostnames = true

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_vpn_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
    "karpenter.sh/discovery" = var.name
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery"          = var.name
  }

  tags = local.tags
}
