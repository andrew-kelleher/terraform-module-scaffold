# Create core resource group
resource "azurerm_resource_group" "core" {
   name         = "core"
   location     = "${var.loc}"
   tags         = "${var.tags}"
}

resource "azurerm_public_ip" "vpnGatewayPublicIp" {
  name                = "vpnGatewayPublicIp"
  location            = "${var.loc}"
  resource_group_name = "${azurerm_resource_group.core.name}"
  allocation_method   = "Dynamic"
  tags                = "${var.tags}"
}

resource "azurerm_virtual_network" "core-vnet" {
  name                = "core-vnet"
  location            = "${azurerm_resource_group.core.location}"
  resource_group_name = "${azurerm_resource_group.core.name}"
  tags                = "${var.tags}"
  address_space       = ["10.0.0.0/16"]
  dns_servers         = ["1.1.1.1", "1.0.0.1"]
}
# recreate subnets as separate resources
  resource "azurerm_subnet" "GatewaySubnet" {
    name           = "GatewaySubnet"
    resource_group_name = "${azurerm_resource_group.core.name}"
    virtual_network_name = "${azurerm_virtual_network.core-vnet.name}"

    address_prefix = "10.0.0.0/24"
  }

  resource "azurerm_subnet" "training" {
    name           = "training"
    resource_group_name = "${azurerm_resource_group.core.name}"
    virtual_network_name = "${azurerm_virtual_network.core-vnet.name}"

    address_prefix = "10.0.1.0/24"
  }

  resource "azurerm_subnet" "dev" {
    name           = "dev"
    resource_group_name = "${azurerm_resource_group.core.name}"
    virtual_network_name = "${azurerm_virtual_network.core-vnet.name}"

    address_prefix = "10.0.2.0/24"
  }

/*
resource "azurerm_virtual_network_gateway" "vpnGateway" {
  name                = "vpnGateway"
  location            = "${azurerm_resource_group.core.location}"
  resource_group_name = "${azurerm_resource_group.core.name}"
  tags                = "${var.tags}"

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = "${azurerm_public_ip.vpnGatewayPublicIp.id}"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${azurerm_subnet.GatewaySubnet.id}"
  }
}
*/

# Create NSG resource group
resource "azurerm_resource_group" "nsgs" {
   name         = "NSGs"
   location     = "${var.loc}"
   tags         = "${var.tags}"
}

# Create ResourceGroupDefault NSG
resource "azurerm_network_security_group" "resource_group_default" {
   name = "ResourceGroupDefault"
   resource_group_name  = "${azurerm_resource_group.nsgs.name}"
   location             = "${azurerm_resource_group.nsgs.location}"
   tags                 = "${azurerm_resource_group.nsgs.tags}"
}

# Separate security rules linked to ResourceGroupDefault
resource "azurerm_network_security_rule" "AllowSSH" {
    name = "AllowSSH"
    resource_group_name         = "${azurerm_resource_group.nsgs.name}"
    network_security_group_name = "${azurerm_network_security_group.resource_group_default.name}"

    priority                    = 1010
    access                      = "Allow"
    direction                   = "Inbound"
    protocol                    = "Tcp"
    destination_port_range      = 22
    destination_address_prefix  = "*"
    source_port_range           = "*"
    source_address_prefix       = "*"
}

resource "azurerm_network_security_rule" "AllowHTTP" {
    name = "AllowHTTP"
    resource_group_name         = "${azurerm_resource_group.nsgs.name}"
    network_security_group_name = "${azurerm_network_security_group.resource_group_default.name}"

    priority                    = 1020
    access                      = "Allow"
    direction                   = "Inbound"
    protocol                    = "Tcp"
    destination_port_range      = 80
    destination_address_prefix  = "*"
    source_port_range           = "*"
    source_address_prefix       = "*"
}

resource "azurerm_network_security_rule" "AllowHTTPS" {
    name = "AllowHTTPS"
    resource_group_name         = "${azurerm_resource_group.nsgs.name}"
    network_security_group_name = "${azurerm_network_security_group.resource_group_default.name}"

    priority                    = 1021
    access                      = "Allow"
    direction                   = "Inbound"
    protocol                    = "Tcp"
    destination_port_range      = 443
    destination_address_prefix  = "*"
    source_port_range           = "*"
    source_address_prefix       = "*"
}

resource "azurerm_network_security_rule" "AllowSQLServer" {
    name = "AllowSQLServer"
    resource_group_name         = "${azurerm_resource_group.nsgs.name}"
    network_security_group_name = "${azurerm_network_security_group.resource_group_default.name}"

    priority                    = 1030
    access                      = "Allow"
    direction                   = "Inbound"
    protocol                    = "Tcp"
    destination_port_range      = 1443
    destination_address_prefix  = "*"
    source_port_range           = "*"
    source_address_prefix       = "*"
}

resource "azurerm_network_security_rule" "AllowRDP" {
    name = "AllowRDP"
    resource_group_name         = "${azurerm_resource_group.nsgs.name}"
    network_security_group_name = "${azurerm_network_security_group.resource_group_default.name}"

    priority                    = 1040
    access                      = "Allow"
    direction                   = "Inbound"
    protocol                    = "Tcp"
    destination_port_range      = 3389
    destination_address_prefix  = "*"
    source_port_range           = "*"
    source_address_prefix       = "*"
}

# Ubuntu NSG (with embedded rule)
resource "azurerm_network_security_group" "nic_ubuntu" {
   name = "NIC_Ubuntu"
   resource_group_name  = "${azurerm_resource_group.nsgs.name}"
   location             = "${azurerm_resource_group.nsgs.location}"
   tags                 = "${azurerm_resource_group.nsgs.tags}"

    security_rule {
        name                       = "SSH"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = 22
        source_address_prefix      = "*"
        destination_address_prefix = "*"
  }
}

# Windows NSG (with embedded rule)
resource "azurerm_network_security_group" "nic_windows" {
   name = "NIC_Windows"
   resource_group_name  = "${azurerm_resource_group.nsgs.name}"
   location             = "${azurerm_resource_group.nsgs.location}"
   tags                 = "${azurerm_resource_group.nsgs.tags}"

    security_rule {
        name                       = "AllowRDP"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = 3389
        source_address_prefix      = "*"
        destination_address_prefix = "*"
  }
}