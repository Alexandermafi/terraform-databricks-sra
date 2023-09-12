# Define a private endpoint resource for the backend
resource "azurerm_private_endpoint" "backend" {
  name                = "databricks-pe-backend"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.privatelink.id

# Configure the private service connection
  private_service_connection {
    name                           = "ple-${var.prefix}-backend"
    private_connection_resource_id = azurerm_databricks_workspace.this.id
    is_manual_connection           = false
    subresource_names              = ["databricks_ui_api"]
  }

# Configure the private DNS zone group
  private_dns_zone_group {
    name                 = "private-dns-zone-backend"
    private_dns_zone_ids = [azurerm_private_dns_zone.backend.id]
  }

  tags = var.tags
}

# Define a private DNS zone resource for the backend
resource "azurerm_private_dns_zone" "backend" {
  name                = "privatelink.azuredatabricks.net"
  resource_group_name = azurerm_resource_group.this.name

  tags = var.tags
}

# Define a virtual network link for the private DNS zone and the backend virtual network
resource "azurerm_private_dns_zone_virtual_network_link" "backend" {
  name                  = "databricks-vnetlink-backend"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.backend.name
  virtual_network_id    = azurerm_virtual_network.this.id

  tags = var.tags
}
