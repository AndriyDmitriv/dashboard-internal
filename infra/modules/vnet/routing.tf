resource "azurerm_route_table" "main" {
  count                         = var.route_table_name != null ? 1 : 0
  name                          = var.route_table_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  bgp_route_propagation_enabled = false
  tags                          = var.tags
}

resource "azurerm_route" "main" {
  count               = var.route_table_name != null ? length(keys(var.routes)) : 0
  name                = keys(var.routes)[count.index]
  address_prefix      = values(var.routes)[count.index].address_prefix
  next_hop_type       = values(var.routes)[count.index].next_hop_type
  resource_group_name = var.resource_group_name
  route_table_name    = azurerm_route_table.main[0].name
}

resource "azurerm_subnet_route_table_association" "main" {
  count          = var.route_table_name != null ? length(var.route_associations) : 0
  subnet_id      = azurerm_subnet.main[var.route_associations[count.index]].id
  route_table_id = azurerm_route_table.main[0].id
}


