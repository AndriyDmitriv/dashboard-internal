variable "resource_group_name" {
  description = "Resource group"
  type        = string
}

variable "vnet_name" {
  description = "VNet name"
  type        = string
}

variable "vnet_address_space" {
  description = "VNet CIDRs"
  type        = list(string)
}

variable "subnets" {
  description = "Subnets"
  type = map(object({
    address_prefixes                          = list(string)
    default_outbound_access_enabled           = optional(bool) # We store your variable
    private_endpoint_network_policies_enabled = optional(bool, true)
    service_endpoints                         = optional(list(string), [])
    associate_nsg                             = optional(bool, false)
    service_delegation = optional(object({
      name    = string
      actions = list(string)
    }), null)

    associate_nat_gateway = optional(bool, false)
  }))
  default = {}
}

variable "route_table_name" {
  description = "Route table name, null = none"
  type        = string
  default     = null
}

variable "routes" {
  description = "Routes"
  type = map(object({
    address_prefix = string
    next_hop_type  = string
  }))
  default = {}
}

variable "route_associations" {
  description = "Subnets for the route table"
  type        = list(string)
  default     = []
}


variable "private_dns_zones" {
  description = "Private DNS zones"
  type = map(object({
    link_name = optional(string)
    enabled   = optional(bool)
  }))
  default = {}
}

variable "private_endpoints" {
  description = "Private endpoints"
  type = map(object({
    target_resource_id = string
    subnet_key         = string
    subresource_names  = list(string)
  }))
  default = {}
}

variable "tags" {
  description = "Tags"
  type        = map(string)
  default     = {}
}

variable "location" {
  description = "Region"
  type        = string
}

variable "nat_gateway_enabled" {
  description = "Create NAT Gateway"
  type        = bool
  default     = false
}

variable "nat_gateway_name" {
  type    = string
  default = null
}

variable "nat_gateway_public_ip_name" {
  type    = string
  default = null
}

variable "create_nsg" {
  description = "Create NSG"
  type        = bool
  default     = false
}

variable "nsg_rules" {
  description = "NSG rules"
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = []
}

variable "create_private_dns_zone_for_postgres" {
  description = "Create PostgreSQL private DNS zone"
  type        = bool
  default     = false
}

variable "private_endpoints_enabled" {
  description = "Create private endpoints subnet and zones"
  type        = bool
  default     = false
}

variable "private_endpoints_subnet_address_prefix" {
  description = "Private endpoints subnet CIDR"
  type        = string
  default     = "10.20.8.0/24"
}
