# Define a variable to store the title-cased location
locals {
  title_cased_location = title(var.location)

  # Define a map to store service tags with their corresponding values
  service_tags = {
    "sql" : "Sql.${local.title_cased_location}",
    "storage" : "Storage.${local.title_cased_location}",
    "eventhub" : "EventHub.${local.title_cased_location}"
  }

  # Define a regular expression pattern to extract subscription ID and resource group from the resource group ID
  resource_regex  = "/subscriptions/(.+)/resourceGroups/(.+)"

  # Extract the subscription ID using the regular expression pattern
  subscription_id = regex(local.resource_regex, azurerm_resource_group.hub.id)[0]

  # Extract the resource group using the regular expression pattern
  resource_group  = regex(local.resource_regex, azurerm_resource_group.hub.id)[1]

  # Get the tenant ID from the current Azure client configuration
  tenant_id       = data.azurerm_client_config.current.tenant_id

  # Generate a prefix for naming resources by combining the hub resource group name and a random string
  prefix          = replace(replace(lower("${var.hub_resource_group_name}${random_string.naming.result}"), "rg", ""), "-", "")

  # Extract the CIDR prefix from the hub VNet CIDR
  hub_cidr_prefix = split("/", var.hub_vnet_cidr)[1]

  # Define a map to store subnets with their corresponding CIDR prefixes
  subnets = {
    "firewall" : cidrsubnet(var.hub_vnet_cidr, 26 - local.hub_cidr_prefix, 0)
    "webauth-host" : cidrsubnet(var.hub_vnet_cidr, 26 - local.hub_cidr_prefix, 1)
    "webauth-container" : cidrsubnet(var.hub_vnet_cidr, 26 - local.hub_cidr_prefix, 2)
    "privatelink" : cidrsubnet(var.hub_vnet_cidr, 24 - local.hub_cidr_prefix, 0)
  }
}

# Retrieve the current Azure client configuration
data "azurerm_client_config" "current" {}

# Generate a random string for naming resources
resource "random_string" "naming" {
  special = false
  upper   = false
  length  = 6
}

# Create the hub resource group
resource "azurerm_resource_group" "hub" {
  name     = var.hub_resource_group_name
  location = var.location
}

# Create the webauth resource group
resource "azurerm_resource_group" "webauth" {
  name     = "${var.location}-webauthrg"
  location = var.location
}

# Create the hub virtual network
resource "azurerm_virtual_network" "this" {
  name                = var.hub_vnet_name
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = [var.hub_vnet_cidr]
}

# Create the privatelink subnet
resource "azurerm_subnet" "privatelink" {
  name                 = "hub-privatelink"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.this.name

  address_prefixes = [local.subnets["privatelink"]]
}