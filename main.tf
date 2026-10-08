resource "azurerm_resource_group" "spoke" {
  name     = "RG-Spoke-${var.team_name}-SBX"
  location = "North Europe"
  tags = {
    Team      = var.team_name
    keepalive = lower(var.keepAlive)
  }
}


resource "azurerm_virtual_network" "spoke_vnet" {
  name                = "vnet-${var.team_name}-sbx"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name

  address_space = [
    local.address_space
  ]
}

resource "azurerm_subnet" "spoke_subnet" {
  name                 = "spoke_subnet"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name

  address_prefixes = [
    local.address_space
  ]
}

data "azurerm_virtual_network" "vnet_hub" {
  name                = "vnet-hub-sbx"
  resource_group_name = "RG-Hub-SBX"
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name = "${var.team_name}-to-hub"

  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name

  remote_virtual_network_id = data.azurerm_virtual_network.vnet_hub.id

  allow_virtual_network_access = true
}


resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name = "hub-to-${var.team_name}"

  resource_group_name  = data.azurerm_virtual_network.vnet_hub.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet_hub.name

  remote_virtual_network_id = azurerm_virtual_network.spoke_vnet.id

  allow_virtual_network_access = true
}


data "azurerm_private_dns_zone" "sql" {
name = "privatelink.database.windows.net"
resource_group_name = "RG-Hub-SBX"
}


data "azurerm_private_dns_zone" "acr" {
name = "privatelink.azurecr.io"
resource_group_name = "RG-Hub-SBX"
}


data "azurerm_private_dns_zone" "keyvault" {
name = "privatelink.vaultcore.azure.net"
resource_group_name = "RG-Hub-SBX"
}


data "azurerm_private_dns_zone" "storage" {
name = "privatelink.blob.core.windows.net"
resource_group_name = "RG-Hub-SBX"
}


data "azurerm_private_dns_zone" "spokes" {
  name                = "dar.internal"
  resource_group_name = "RG-Hub-SBX"
}


resource "azurerm_private_dns_zone_virtual_network_link" "spoke_internal" {
  name                  = "${var.team_name}-dar-link"
  private_dns_zone_id = data.azurerm_private_dns_zone.spokes.id
  virtual_network_id    = azurerm_virtual_network.spoke_vnet.id

  registration_enabled  = false
}


resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                = "${var.team_name}-kv-link"
  private_dns_zone_id = data.azurerm_private_dns_zone.keyvault.id
  virtual_network_id  = azurerm_virtual_network.spoke_vnet.id

  registration_enabled = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  name                = "${var.team_name}-storage-link"
  private_dns_zone_id = data.azurerm_private_dns_zone.storage.id
  virtual_network_id  = azurerm_virtual_network.spoke_vnet.id

  registration_enabled = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  name                = "${var.team_name}-acr-link"
  private_dns_zone_id = data.azurerm_private_dns_zone.acr.id
  virtual_network_id  = azurerm_virtual_network.spoke_vnet.id

  registration_enabled = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                = "${var.team_name}-sql-link"
  private_dns_zone_id = data.azurerm_private_dns_zone.sql.id
  virtual_network_id  = azurerm_virtual_network.spoke_vnet.id

  registration_enabled = false
}
