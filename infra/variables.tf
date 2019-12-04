variable "tags" {
 description = "A map of the tags to use for the resources that are deployed"
 type        = map(string)

 default = {
   environment = "Production"
 }
}

variable "location" {
  description = "Set default location"
  type        = string
  default     = "East US"
}
