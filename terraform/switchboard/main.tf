# no backend configuration since the state will live locally, considering it's
# a short-lived project. Otherwise here there would be a block like
# terraform {
#   backend "s3" {
#     encrypt = true
#     bucket  = "tf-state"
#     region  = "us-east-1"
#     key     = "switchboard.tfstate"
#   }
# }

# configure most stuff here
locals {
  cluster_name = "switchboard"
  env          = "dev"
  namespace    = "ops"
  domain       = "lele.rip"
}

# no touchy touchy below this line
# ---
module "eks" {
  source           = "../modules/eks"
  name             = local.cluster_name
  env              = local.env
  namespace        = local.namespace
  external_dns     = true
  cloudflare_token = module.switchboard-cf-dns-token.value
}

### Cloudflare DNS integration
data "cloudflare_zone" "cf_dns" {
  name = local.domain
}

module "switchboard-cf-dns-token" {
  source = "../modules/cloudflare-token"

  zone_id = data.cloudflare_zone.cf_dns.id
  env     = local.env
}

resource "helm_release" "argo-app-of-apps" {
  name      = "argo-app-of-apps"
  namespace = "argocd"
  chart     = "../../argo/app-of-apps/"
}
