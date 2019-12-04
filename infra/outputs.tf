output "bastion_public_ip_address" {
  description  = "Bastion Host IP address"
  value        = azurerm_public_ip.tenpobastionpublicip.ip_address
}

output "load_balancer_public_ip_address" {
  description  = "Load Balancer IP address"
  value        = azurerm_public_ip.tenpolbpublicip.ip_address
}
