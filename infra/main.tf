provider "azurerm" {
  version = "~> 1.37"
}

# Resource Group
resource "azurerm_resource_group" "tenporesourcegroup" {
  name     = "tenpoResourceGroup"
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "tenpovirtualnetwork" {
  name                = "tenpoVirtualNetwork"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.tenporesourcegroup.name
  tags                = var.tags
}

# Public Subnet
resource "azurerm_subnet" "tenposubnet" {
  name                 = "tenpoSubnet"
  resource_group_name  = azurerm_resource_group.tenporesourcegroup.name
  virtual_network_name = azurerm_virtual_network.tenpovirtualnetwork.name
  address_prefix       = "10.0.1.0/24"
}

# Load Balancer

## LB Public IP
resource "azurerm_public_ip" "tenpolbpublicip" {
  name                = "tenpoLBPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.tenporesourcegroup.name
  allocation_method   = "Dynamic"
  domain_name_label   = "lb-dns-name"
  tags                = var.tags
}

## LB resource
resource "azurerm_lb" "tenpolb" {
  name                = "tenpoLB"
  location            = var.location
  resource_group_name = azurerm_resource_group.tenporesourcegroup.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.tenpolbpublicip.id
  }
}

## LB backend address pool
resource "azurerm_lb_backend_address_pool" "tenpobackendap" {
 resource_group_name = azurerm_resource_group.tenporesourcegroup.name
 loadbalancer_id     = azurerm_lb.tenpolb.id
 name                = "BackendPool1"
}

# LB Rule 80:80
resource "azurerm_lb_rule" "tenpolbrule" {
  resource_group_name            = azurerm_resource_group.tenporesourcegroup.name
  loadbalancer_id                = azurerm_lb.tenpolb.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  backend_address_pool_id        = azurerm_lb_backend_address_pool.tenpobackendap.id
  probe_id                       = azurerm_lb_probe.lb_probe.id
  frontend_ip_configuration_name = "PublicIPAddress"
}

## LB probe
resource "azurerm_lb_probe" "lb_probe" {
  resource_group_name = azurerm_resource_group.tenporesourcegroup.name
  loadbalancer_id     = azurerm_lb.tenpolb.id
  name                = "SSHRunningProbe"
  port                = 22
}

## API SG
resource "azurerm_network_security_group" "tenpoapisg" {
  name                = "tenpoAPISecurityGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.tenporesourcegroup.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

## API NIC
resource "azurerm_network_interface" "tenpoapinic" {
  name                      = "tenpoAPINIC"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.tenporesourcegroup.name
  network_security_group_id = azurerm_network_security_group.tenpoapisg.id
  internal_dns_name_label   = "api"

  ip_configuration {
    name                                    = "tenpoAPINICConfiguration"
    subnet_id                               = azurerm_subnet.tenposubnet.id
    private_ip_address_allocation           = "Dynamic"
    load_balancer_backend_address_pools_ids = [azurerm_lb_backend_address_pool.tenpobackendap.id]
  }

  tags = var.tags
}

## API VM
resource "azurerm_virtual_machine" "tenpoapivm" {
  name                  = "tenpoAPIVM"
  location              = var.location
  resource_group_name   = azurerm_resource_group.tenporesourcegroup.name
  network_interface_ids = [azurerm_network_interface.tenpoapinic.id]
  vm_size               = "Standard_B1s"

  storage_os_disk {
    name              = "APIOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "api"
    admin_username = "tenpo"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/tenpo/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+3CPZN7hECdhxhQTXY9Tthva4uq4aa5qYUcio3axOpwTLckNSCkeq7sGxSNgn2rzEEelelcR+zWFRIpTFKojBXDgspB38+4v4nrEuuJbXlJZvIBX+wYRFe+ijbpbgMwtNT03qpJWFP34oTYxHOy5+rRyKBm6hyBIfcaNGPQy97DfcUPjvI6oWIo2KO93j9hItytpgTcMfQFHdmPbXpzZGnzxPoCSfFM3x1PlTYcyJ9oaStDhMzHV+leAQZyESf8TR93EfgSmbfcaNPeBe+yh5rcQo9/KDPBERxJXAYbcneEJPm/3i8nAymATyfwV1MylsGzi0IOIpeMGB6W5EMrqd luismancillaavila@penguin"
    }
  }

  depends_on = [azurerm_network_interface.tenpoapinic]
  tags = var.tags
}

# Database

## DB SG
resource "azurerm_network_security_group" "tenpodbsg" {
  name                = "tenpoDBSecurityGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.tenporesourcegroup.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "PostgreSQL"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

## DB NIC
resource "azurerm_network_interface" "tenpodbnic" {
  name                      = "tenpoDBNIC"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.tenporesourcegroup.name
  network_security_group_id = azurerm_network_security_group.tenpodbsg.id
  internal_dns_name_label   = "db"

  ip_configuration {
    name                          = "tenpoDBNICConfiguration"
    subnet_id                     = azurerm_subnet.tenposubnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = var.tags
}

## DB VM
resource "azurerm_virtual_machine" "tenpodbvm" {
  name                  = "tenpoDBVM"
  location              = var.location
  resource_group_name   = azurerm_resource_group.tenporesourcegroup.name
  network_interface_ids = [azurerm_network_interface.tenpodbnic.id]
  vm_size               = "Standard_B1s"

  storage_os_disk {
    name              = "DBOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "db"
    admin_username = "tenpo"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/tenpo/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+3CPZN7hECdhxhQTXY9Tthva4uq4aa5qYUcio3axOpwTLckNSCkeq7sGxSNgn2rzEEelelcR+zWFRIpTFKojBXDgspB38+4v4nrEuuJbXlJZvIBX+wYRFe+ijbpbgMwtNT03qpJWFP34oTYxHOy5+rRyKBm6hyBIfcaNGPQy97DfcUPjvI6oWIo2KO93j9hItytpgTcMfQFHdmPbXpzZGnzxPoCSfFM3x1PlTYcyJ9oaStDhMzHV+leAQZyESf8TR93EfgSmbfcaNPeBe+yh5rcQo9/KDPBERxJXAYbcneEJPm/3i8nAymATyfwV1MylsGzi0IOIpeMGB6W5EMrqd luismancillaavila@penguin"
    }
  }

  depends_on = [azurerm_network_interface.tenpodbnic]
  tags = var.tags
}

# Bastion Host

## Bastion SG
resource "azurerm_network_security_group" "tenpobastionsg" {
  name                = "tenpoBastionSecurityGroup"
  location            = var.location
  resource_group_name = azurerm_resource_group.tenporesourcegroup.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

## Bastion Public IP
resource "azurerm_public_ip" "tenpobastionpublicip" {
  name                = "tenpoBastionPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.tenporesourcegroup.name
  allocation_method   = "Dynamic"
  tags                = var.tags
}

## Bastion NIC
resource "azurerm_network_interface" "tenpobastionnic" {
  name                      = "tenpoBastionNIC"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.tenporesourcegroup.name
  network_security_group_id = azurerm_network_security_group.tenpobastionsg.id

  ip_configuration {
    name                          = "tenpoBastionNICConfiguration"
    subnet_id                     = azurerm_subnet.tenposubnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.tenpobastionpublicip.id
  }

  tags = var.tags
}

## Bastion VM
resource "azurerm_virtual_machine" "tenpobastion" {
  name                  = "tenpoBastion"
  location              = var.location
  resource_group_name   = azurerm_resource_group.tenporesourcegroup.name
  network_interface_ids = [azurerm_network_interface.tenpobastionnic.id]
  vm_size               = "Standard_B1s"

  storage_os_disk {
    name              = "BastionOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "bastion-host"
    admin_username = "bastion"
    custom_data    = <<-EOF
      #!/bin/bash
      apt update
      apt install software-properties-common
      apt-add-repository --yes --update ppa:ansible/ansible
      sudo apt install -y ansible
      echo -n '${file("${path.module}/bastion-private-key.pem")}' > /home/bastion/.ssh/id_rsa
      chown bastion:bastion /home/bastion/.ssh/id_rsa
      chmod 0600 /home/bastion/.ssh/id_rsa
      sudo -H -u bastion bash -c 'ansible-galaxy install geerlingguy.pip'
      sudo -H -u bastion bash -c 'ansible-galaxy install geerlingguy.postgresql'
      sudo -H -u bastion bash -c 'ansible-galaxy install geerlingguy.docker'
      cd /home/bastion/
      git clone https://github.com/steve-perry-o/infra-provision-test.git
      cd infra-provision-test/provisioning/ansible/
      sudo -H -u bastion bash -c 'ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u tenpo postgresql_server.yml -i hosts'
      sudo -H -u bastion bash -c 'ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u tenpo docker_ubuntu.yml -i hosts'
      sudo chown bastion:bastion config.ru
      scp config.ru tenpo@api:/tmp/
      sudo -H -u bastion bash -c 'ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -u tenpo docker_ruby_sinatra.yml -i hosts'
      EOF
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/bastion/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+3CPZN7hECdhxhQTXY9Tthva4uq4aa5qYUcio3axOpwTLckNSCkeq7sGxSNgn2rzEEelelcR+zWFRIpTFKojBXDgspB38+4v4nrEuuJbXlJZvIBX+wYRFe+ijbpbgMwtNT03qpJWFP34oTYxHOy5+rRyKBm6hyBIfcaNGPQy97DfcUPjvI6oWIo2KO93j9hItytpgTcMfQFHdmPbXpzZGnzxPoCSfFM3x1PlTYcyJ9oaStDhMzHV+leAQZyESf8TR93EfgSmbfcaNPeBe+yh5rcQo9/KDPBERxJXAYbcneEJPm/3i8nAymATyfwV1MylsGzi0IOIpeMGB6W5EMrqd luismancillaavila@penguin"
    }
  }

  provisioner "remote-exec" {
    # command = "cloud-init status --wait"
    # inline = [
    #   "/bin/bash -c \"timeout 300 sed '/finished/q' <(tail -f /var/log/cloud-init-output.log)\""
    # ]
  }

  depends_on = [
    azurerm_virtual_machine.tenpoapivm,
    azurerm_virtual_machine.tenpodbvm,
    azurerm_network_interface.tenpobastionnic,
    azurerm_public_ip.tenpobastionpublicip
  ]

  tags = var.tags
}
