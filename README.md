# srinitfcode

- This script will use latest providers and install Linux VM using Terrafom.
- Sensetive data we are saving in keyvault for Vm username and password.
- We use remote exec to install and config of media wiki instead of using anisble or puppet

Local development
In local development, no backend is configured so a local backend is used.

Install Azure CLI and login. Terraform will use your Azure CLI credentials.

$ az login -o table
You have logged in. Now let us find all the subscriptions to which you have access...

$ terraform init

Initializing the backend...

Initializing provider plugins...
- Checking for available provider plugins...
- Downloading plugin for provider "azurerm" (hashicorp/azurerm) 1.38.0...

Terraform has been successfully initialized!

Run terraform plan.

$ terraform plan -out tfplan
Refreshing Terraform state in-memory prior to plan...
Check the plan to crosscechk resources deploy based on requirnment
Run terraform apply 


IN Case of Automated Deployment we can use Azure Devops with YAML based 

