# Linode API token stored in env var VAR_TF_token
# export TF_VAR_token="25xxx"
provider "linode" {
  token = var.token
}

resource "linode_sshkey" "linode_ssh_key" {
  label   = "my_ssh_key"
  ssh_key = chomp(file("~/.ssh/jgrinwis-2018-07-09.pub"))
}

resource "random_password" "linode_root_password" {
  length  = 32
  special = true
}

resource "random_password" "wp_db_password" {
  length  = 32
  special = true
}

# had some issues so no special characters for now
resource "random_password" "wp_admin_password" {
  length  = 32
  special = false
}

# let's lookup information from the stackscript
data "linode_stackscript" "my_stackscript" {
  id = var.stackscript_id
}

# all these secrets should be stored in a vault
# something for our next project, password can be shown via 'terraform output -json'
# but all credentials should move to Hashicorp Vault in a next release.
resource "linode_instance" "my_wp_instance" {
  image           = data.linode_stackscript.my_stackscript.images[0]
  label           = var.label
  region          = var.region
  type            = var.type
  authorized_keys = [linode_sshkey.linode_ssh_key.ssh_key]
  root_pass       = random_password.linode_root_password.result
  stackscript_id  = var.stackscript_id
  # we need to correct input vars for this stackscript
  # all possible vars can be checked via GET https://api.linode.com/v4/linode/stackscripts/401697
  stackscript_data = {
    "soa_email_address" = "john@grinwis.com"
    "wp_admin"          = "admin"
    "wp_password"       = resource.random_password.wp_admin_password.result
    "dbroot_password"   = resource.random_password.wp_db_password.result
    "db_password"       = resource.random_password.wp_db_password.result
  }
}
