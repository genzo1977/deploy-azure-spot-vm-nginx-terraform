# Deploy an environment on Azure running NGINX RedHat
Does what it says on the tin. All you need to do is enter your subscription_id in the first provider block.

### Prerequisites:
1. Install Terraform on the local machine

`choco install -y terraform`

2. Install Azure CLI
https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-windows?tabs=azure-cli

3. Authenticate via Azure CLI

4. Clone this repo:

`git clone https://github.com/genzo1977/enable-private-end-point-on-app-service-and-secure-access-to-storage-account.git`

5. Change directory:

`C:\ProgramFiles\terraform\deploy-azure-spot-vm-nginx-terraform\`

6. Log into Azure:

`az login`

### Steps to Initialize and Apply:
1. Run `terraform init` to initialize the backend.
2. Run `terraform plan` to see what you are about to apply
3. Run `terraform apply` to apply the infrastructure.

### Test
Get the VM piblic IP address and enter in the address bar of the brouwswe `https://<IP_ADDRESS>`
If the NGINX home page is not popping up, check the iinternal firewall

`firewall-cmd --state`

`firewall-cmd --zone=public --add-service=http --permanent

`firewall-cmd --reload`

Now it should all work

If it's running, ensure HTTP (port 80) is allowed:

4. Clean up once you are done - `terraform destroy`



