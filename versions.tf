# our required provider with preferred versions
terraform {
  required_providers {
    linode = {
      source = "linode/linode"
      #version = "1.16.0"
    }
    akamai = {
      source  = "akamai/akamai"
      #version = "5.2.0"
    }
  }
}
