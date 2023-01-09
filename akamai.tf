# Terraform script to create a CDN config in front of a linode instance
# A basic config using Secure By Default (SBD) certs pointing to linode backend in a 1:1 relation
# EdgeDNS used to create the CNAME records for the SBD DV certs.

# for cloud usage these vars have been defined in terraform cloud as a set
# Configure the Akamai Terraform Provider to use betajam credentials
provider "akamai" {
  edgerc         = "~/.edgerc"
  config_section = "betajam"
}

# just use group_name to lookup our contract_id and group_id
# this will simplify our variables file as this contains contract and group id
# use "akamai property groups list" to find all your groups
data "akamai_contract" "contract" {
  group_name = var.group_name
}

locals {
  # using ION as our default product in case wrong product type has been provided as input var.
  # our failsave method just because we can. ;-)
  default_product = "prd_Fresca"

  # convert the list of maps to a map of maps with entry.hostname as key of the map
  # this map of maps will be fed into our EdgeDNS module to create the CNAME records.
  dv_records = { for entry in resource.akamai_property.aka_property.hostnames[*].cert_status[0] : entry.hostname => entry }

  cp_code_id = tonumber(trimprefix(resource.akamai_cp_code.cp_code.id, "cpc_"))

  # our dynamically created linode hostname, domain is always the same so no var.
  # linode will automatically request a DV certificate for the origin.
  origin_hostname = format("%s.ip.linodeusercontent.com", join("-", split(".", resource.linode_instance.my_wp_instance.ip_address)))
}


# for the demo don't create cpcode's over and over again, just reuse existing one
# if cpcode already existst it will take the existing one.
resource "akamai_cp_code" "cp_code" {
  name        = var.cpcode
  contract_id = data.akamai_contract.contract.id
  group_id    = data.akamai_contract.contract.group_id
  product_id  = lookup(var.aka_products, lower(var.product_name), local.default_product)
}

# as the config will be pretty static, use template file
# we're going to use all required rules in this tf file.
# create our edge hostname resource
resource "akamai_edge_hostname" "aka_edge" {
  product_id  = resource.akamai_cp_code.cp_code.product_id
  contract_id = data.akamai_contract.contract.id
  group_id    = data.akamai_contract.contract.group_id
  ip_behavior = var.ip_behavior

  # edgehostname based on hostname + networkf(FF/ESSL)
  edge_hostname = "${var.hostname}.${var.domain_suffix}"
}

resource "akamai_property" "aka_property" {
  name        = var.hostname
  contract_id = data.akamai_contract.contract.id
  group_id    = data.akamai_contract.contract.group_id
  product_id  = resource.akamai_cp_code.cp_code.product_id

  # our pretty static hostname configuration so a simple 1:1 between front-end and back-end
  hostnames {
    cname_from             = var.hostname
    cname_to               = resource.akamai_edge_hostname.aka_edge.edge_hostname
    cert_provisioning_type = "DEFAULT"
  }

  # our pretty static rules file. Only dynamic part is the origin name
  # we could use the akamai_template but trying standard templatefile() for a change.
  # we might want to add cpcode in here which is statically configured now
  rules = templatefile("akamai_config/config.tftpl", { origin_hostname = local.origin_hostname, cp_code_id = local.cp_code_id, cp_code_name = var.cpcode })
}

# let's activate this property on staging
# staging will always use latest version but when useing on production a version number should be provided.
resource "akamai_property_activation" "aka_staging" {
  property_id = resource.akamai_property.aka_property.id
  contact     = [var.email]
  version     = resource.akamai_property.aka_property.latest_version
  network     = "STAGING"
  note        = "Action triggered by Terraform."
}

# if you your DNS provider has a Terraform module just use it here to create the CNAME records
# let's create our DV records using a module with with different credentials.
# Terraform has some limitations regarding using count and for_each with a module and separate provider configs
# Providers cannot be configured within modules using count, for_each or depends_on
# so just feeding our edgehostname created dv strings into our edgedns_cname module as a test for secure_by_default
module "edgedns_cert_cname" {
  source = "../modules/services/edgedns_cert_cname"

  # our modules needs a list so convert our single hostname to a unique list=set
  hostnames = toset([var.hostname])

  # our secure by default converted dv_keys output, lets feed into our edgedns module
  # feeding our local created map of maps var
  dv_records = local.dv_records
}

# our explicit reference to a provider using an alias
# https://developer.hashicorp.com/terraform/language/modules/develop/providers#passing-providers-explicitly
provider "akamai" {
  edgerc         = "~/.edgerc"
  config_section = "gss_training"
  alias          = "edgedns"
}

# let's directly cname to akamai, it's for a demo only
# using staging environment but let's wait until property has been activated.
module "edgedns_cname" {
  source = "../modules/services/edgedns_cname_2_akamai"

  # in this example just a single hostname we CNAME to edgehostname
  hostname = var.hostname

  # we're going to replace our edgehostname with -staging.net
  # so edgekey.net or edgesuite.net because -staging.net
  edge_hostname = replace(resource.akamai_edge_hostname.aka_edge.edge_hostname, "/\\.net$/", "-staging.net")

  # we're now able to use depends_on with a module by making this explicit reference in our main module 
  providers = {
    akamai = akamai.edgedns
  }

  # with our explict reference to a provider we should now be able to use depends_on
  # so let's wait until our property is active before creating the CNAME to our edgehostname.
  depends_on = [
    akamai_property_activation.aka_staging
  ]
}

# last but not least add this hostname to a pre-configured security policy
/* module "enable_security" {
  source = "../modules/services/security_policy"

  # use our pre-configured configuration & policy
  security_configuration = var.security_configuration
  security_policy        = var.security_policy

  # add our hostname to our security configuration match target.
  hostnames = [var.hostname]

  # list of users to inform when policy has been activated
  email = [var.email]

  depends_on = [
    akamai_property_activation.aka_staging
  ]
} */
