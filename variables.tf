variable "label" {
  description = "Provide a label for this image"
  type        = string
  default     = "WordPress"
}

variable "token" {
  description = "The API token to use"
  type        = string
}

# akamai .edgerc variables
variable "akamai_access_token" {
  description = "The akamai API access token to use"
  type        = string
}

variable "akamai_client_token" {
  description = "The Akamai API client token to use"
  type        = string
}

variable "akamai_client_secret" {
  description = "The Akamai API client secretto use"
  type        = string
}

variable "akamai_host" {
  description = "The API host to use"
  type        = string
}

# just an example to restrict the region to deploy your instance in
# All available regions can be found here: https://api.linode.com/v4/regions
variable "region" {
  description = "The region to deploy this image"
  type        = string
  validation {
    condition     = contains(["eu-west", "eu-central"], var.region)
    error_message = "A valid region should be selected."
  }
  default = "eu-west"
}

variable "type" {
  description = "The type of image"
  type        = string
}

variable "stackscript_id" {
  description = "stackscript_id to use"
  type        = number
}

# map of akamai products, just to make life easy
variable "aka_products" {
  description = "map of akamai products"
  type        = map(string)

  default = {
    "ion" = "prd_Fresca"
    "dsa" = "prd_Site_Accel"
    "dd"  = "prd_Download_Delivery"
  }
}

variable "cpcode" {
  description = "Your unique Akamai CPcode name to be used with your property"
  type        = string
}

# akamai product to use
variable "product_name" {
  description = "The Akamai delivery product name"
  type        = string
  default     = "ion"
}

# IPV4, IPV6_PERFORMANCE or IPV6_COMPLIANCE
variable "ip_behavior" {
  description = "use IPV4 to only use IPv4"
  type        = string
  default     = "IPV6_COMPLIANCE"
}

# FreeFlow=edgesuite.net, ESSL=egekey.net
variable "domain_suffix" {
  description = "edgehostname suffix"
  type        = string
  default     = "edgekey.net"
}

variable "group_name" {
  description = "Akamai group to use this resource in"
  type        = string
}

variable "email" {
  description = "Email address of users to inform when property gets created"
  type        = string
}

variable "hostname" {
  description = "Name of the hostname but also user for property and edgehostname"
  type        = string
}

# security related information
variable "security_configuration" {
  description = "The active security configuration of the security policy you want to use."
  type        = string
}

variable "security_policy" {
  description = "The active security policy the hostnames should be attached to."
  type        = string
}
