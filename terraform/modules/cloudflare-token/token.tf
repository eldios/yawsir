data "cloudflare_api_token_permission_groups" "all" {}

# Token allowed to edit DNS entries and TLS certs for specific zone.
resource "cloudflare_api_token" "cf_token_dns_edit" {
  name = "TERRAFORM-${var.env}-dns-edit"

  policy {
    permission_groups = [
      data.cloudflare_api_token_permission_groups.all.zone["DNS Write"],
    ]
    resources = {
      "com.cloudflare.api.account.zone.${var.zone_id}" = "*"
    }
  }
}

output "value" {
  sensitive = true
  value     = cloudflare_api_token.cf_token_dns_edit.value
}
