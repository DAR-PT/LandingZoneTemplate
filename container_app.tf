data "azurerm_container_app_environment" "shared" {
  name                = "cae-shared-sbx"
  resource_group_name = "RG-Hub-SBX"
}

resource "azurerm_container_app" "spoke" {
  name                         = "${lower(var.spoke_name)}-app"
  resource_group_name          = azurerm_resource_group.spoke.name
  container_app_environment_id = data.azurerm_container_app_environment.shared.id
  revision_mode                = "Single"

  template {
    min_replicas = 1
    max_replicas = 1

    container {
      name   = "helloworld"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

resource "azurerm_private_dns_cname_record" "spoke_app" {
  name                = lower(var.spoke_name)
  private_dns_zone_id = data.azurerm_private_dns_zone.spokes.id
  ttl                 = 300
  record              = local.app_fqdn
}
