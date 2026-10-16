locals {
  address_space = cidrsubnet(
    "10.1.0.0/16",
    10,
    var.spoke_index
  )

  app_fqdn = azurerm_container_app.spoke.latest_revision_fqdn
}