
resource "azurerm_network_security_group" "main" {
  count = var.create_nsg ? 1 : 0

  name                = "${var.vnet_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_network_security_rule" "main" {
  for_each = { for rule in var.nsg_rules : rule.name => rule if var.create_nsg }

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = azurerm_network_security_group.main[0].resource_group_name
  network_security_group_name = azurerm_network_security_group.main[0].name
}

resource "azurerm_subnet_network_security_group_association" "main" {
  for_each = { for k, v in var.subnets : k => v if var.create_nsg && v.associate_nsg == true }

  subnet_id                 = azurerm_subnet.main[each.key].id
  network_security_group_id = azurerm_network_security_group.main[0].id
}
