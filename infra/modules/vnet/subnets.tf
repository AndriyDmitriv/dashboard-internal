resource "azurerm_subnet" "main" {
  for_each                        = var.subnets
  name                            = each.key
  resource_group_name             = var.resource_group_name
  virtual_network_name            = azurerm_virtual_network.main.name
  address_prefixes                = each.value.address_prefixes
  default_outbound_access_enabled = each.value.default_outbound_access_enabled
  service_endpoints               = try(coalesce(each.value.service_endpoints, []), [])
  dynamic "delegation" {
    for_each = each.value.service_delegation != null ? [each.value.service_delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.name
        actions = delegation.value.actions
      }
    }
  }
}


resource "azurerm_public_ip" "nat_gateway" {
  count               = var.nat_gateway_enabled ? 1 : 0
  name                = var.nat_gateway_public_ip_name #"${var.vnet_name}-nat-gw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "main" {
  count               = var.nat_gateway_enabled ? 1 : 0
  name                = var.nat_gateway_name #"${var.vnet_name}-nat-gw"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "Standard"
  tags                = var.tags

}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  count                = var.nat_gateway_enabled ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.main[0].id
  public_ip_address_id = azurerm_public_ip.nat_gateway[0].id
}


resource "azurerm_subnet_nat_gateway_association" "main" {
  for_each = var.nat_gateway_enabled ? {
    for k, v in var.subnets : k => v if v.associate_nat_gateway == true
  } : {}
  subnet_id      = azurerm_subnet.main[each.key].id
  nat_gateway_id = azurerm_nat_gateway.main[0].id
}

resource "azurerm_subnet" "private_endpoints" {
  count                             = var.private_endpoints_enabled ? 1 : 0
  name                              = "private-endpoints-subnet"
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.main.name
  address_prefixes                  = [var.private_endpoints_subnet_address_prefix]
  private_endpoint_network_policies = "Disabled"
}

