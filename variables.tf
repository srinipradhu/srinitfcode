# Variables
variable "rgname" {}
variable "rglocation" {}
variable "vnetcidrrange" {
  type = list(string)
}
variable "subnetcidr" {
  type = list(string)
}
variable "vmname" {}
variable "vnetname" {}
variable "subnetname" {}
variable "vmpipname" {}
variable "vmnicname" {}

