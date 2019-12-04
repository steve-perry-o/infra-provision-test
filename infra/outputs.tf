output "public_ip_address" {
  description  = "Bastion Host IP address"
  value        = "${azurerm_public_ip.tenpobastionpublicip.ip_address}"
}
