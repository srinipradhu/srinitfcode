
Key Vault creation to store user name and password for RHEl VMs

#Create KeyVault ID
resource "random_id" "kvname" {
  byte_length = 5
  prefix = "keyvault"
}
#Keyvault Creation
data "azurerm_client_config" "current" {}
resource "azurerm_key_vault" "demo_kv1" {
  depends_on = [ azurerm_resource_group ]
  name                        = random_id.kvname.hex
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name = "standard"
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    key_permissions = [
      "get",
    ]
    secret_permissions = [
      "get", "backup", "delete", "list", "purge", "recover", "restore", "set",
    ]
    storage_permissions = [
      "get",
    ]
  }
}

#Create KeyVault VM password
resource "random_password" "vmpassword" {
  length = 20
  special = true
}
#Create Key Vault Secret
resource "azurerm_key_vault_secret" "vmpassword" {
  name         = "vmpassword"
  value        = random_password.vmpassword.result
  key_vault_id = azurerm_key_vault.demo_kv1.id
  depends_on = [ azurerm_key_vault.demo_kv1 ]
  
  

#Create Resource groups for media wiki tier
resource "azurerm_resource_group" "example" {
  name     = var.rgname
  location = var.rglocation
}

#Create virtual network and subnets for media wiki tier
resource "azurerm_virtual_network" "demovnet" {
  name                = var.vnetname
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  address_space       = var.cidrrange
}

#Create subnet for media wiki tier
resource "azurerm_subnet" "presentation-subnet" {
  name                 = var.subnetname
  resource_group_name  = azurerm_resource_group.example.name.name
  virtual_network_name = azurerm_virtual_network.demovnet.name
  address_prefixes     = var.subnetcidr
}

#Create Public IP Address
resource "azurerm_public_ip" "demo-pip" {
  name                = var.vmpipname
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "example" {
  name                = var.vmnicname
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "demo-vm-01" {
  name                  = var.vmname
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.example.id]
  size                  = "Standard_DC1ds_v3"
  admin_username = azurerm_key_vault_secret.name.value
  admin_password = azurerm_key_vault_secret.vmpassword.value 

  os_disk {
    name                 = "vm01disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "6.9"
    version   = "6.9.2018010506"
  }

  computer_name                   = "demo-webserver-vm-01"
  admin_username                  = "linuxsrvuser"
  disable_password_authentication = true



  # Provisioning script
  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y centos-release-scl",
      "sudo yum install -y httpd24-httpd rh-php73 rh-php73-php rh-php73-php-mbstring rh-php73-php-mysqlnd rh-php73-php-gd rh-php73-php-xml mariadb-server mariadb",
      "sudo systemctl start mariadb",
      "sudo mysql_secure_installation",
      "sudo mysql -u root -e \"CREATE USER 'wiki'@'localhost' IDENTIFIED BY 'demo123$';\"",
      "sudo mysql -u root -e \"CREATE DATABASE wikidatabase;\"",
      "sudo mysql -u root -e \"GRANT ALL PRIVILEGES ON wikidatabase.* TO 'wiki'@'localhost';\"",
      "sudo mysql -u root -e \"FLUSH PRIVILEGES;\"",
      "sudo yum install -y wget",
      "cd /home/ec2-user",
      "wget https://releases.wikimedia.org/mediawiki/1.41/mediawiki-1.41.0.tar.gz",
      "wget https://releases.wikimedia.org/mediawiki/1.41/mediawiki-1.41.0.tar.gz.sig",
      "gpg --verify mediawiki-1.41.0.tar.gz.sig mediawiki-1.41.0.tar.gz",
      "sudo mkdir -p /var/www",
      "sudo tar -zxf mediawiki-1.41.0.tar.gz -C /var/www",
      "sudo ln -s /var/www/mediawiki-1.41.0/ /var/www/mediawiki",
      "sudo chown -R apache:apache /var/www/mediawiki-1.41.0",
      "sudo chown -R apache:apache /var/www/mediawiki",
      "sudo systemctl restart httpd",
      "sudo firewall-cmd --permanent --zone=public --add-service=http",
      "sudo firewall-cmd --permanent --zone=public --add-service=https",
      "sudo systemctl restart firewalld",
      "sudo restorecon -FR /var/www/mediawiki-1.41.0/",
      "sudo restorecon -FR /var/www/mediawiki"
    ]
  }
}

