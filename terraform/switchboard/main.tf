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

module "eks" {
  source           = "../modules/eks"
  name             = "switchboard"
  env              = "dev"
  namespace        = "ops"
  external_dns     = true
  cloudflare_token = module.switchboard-cf-dns-token.value
}

### Cloudflare DNS integration

data "cloudflare_zone" "cf_dns" {
  name = "lele.rip"
}

module "switchboard-cf-dns-token" {
  source = "../modules/cloudflare-token"

  zone_id = data.cloudflare_zone.cf_dns.id
  env     = "dev"
}
