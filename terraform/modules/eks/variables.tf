#------------------------------------------------------------------------------
# variables definitions
#------------------------------------------------------------------------------

variable "eks_cluster_version" {
  type    = string
  default = "1.29"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "name" {
  type    = string
  default = "eks"
}

variable "namespace" {
  type    = string
  default = "ops"
}

locals {
  tags = {
    "name"       = var.name
    "namespace"  = var.namespace
    "terraform"  = true
    "GitHubRepo" = "https://github.com/eldios/yawsir"
  }

  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  exclude_image_list = "kube_namespace:kube-system kube_namespace:ingress kube_namespace:karpenter kube_namespace:local-path"
}

variable "install_datadog_agent" {
  type    = bool
  default = false
}

variable "install_openebs" {
  type    = bool
  default = false
}

variable "instance_disk_space" {
  type    = string
  default = "20Gi"
}

variable "external_dns" {
  type    = bool
  default = false
}
variable "cloudflare_token" {
  type    = string
  default = ""
}

variable "instance_cpu" {
  type = list(string)
  default = [
    "1",
    "2",
    "4",
    "8",
    "12",
    "16"
  ]
}

variable "instance_memory" {
  type = list(string)
  default = [
    "2048",
    "4096",
    "8192",
    "16384",
    "32768"
  ]
}

variable "instance_category" {
  type = list(string)
  default = [
    "c",
    "m",
    "r",
    "t",
    "x"
  ]
}

variable "cluster_cpu" {
  type    = string
  default = "32000"
}

variable "cluster_memory" {
  type    = string
  default = "64Gi"
}
