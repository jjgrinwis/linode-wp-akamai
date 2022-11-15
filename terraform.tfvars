# instance type to run our application on
# GET https://api.linode.com/v4/linode/types
type = "g6-nanode-1"

# The wordpress stack id
# check GET https://api.linode.com/v4/linode/stackscripts/607433 for the required values
stackscript_id = 401697

# group to create resources in
group_name = "Ion Standard Beta Jam 1-3-16TWBVX"

# what user to inform when hostname has been created
email = "nobody@akamai.com"

# let's use FF network
domain_suffix = "edgesuite.net"

# property name
hostname = "wordpress.great-demo.com"

# this is an exising cpcode name connected to the right product (ion)
# you can find cpcodes via akamai pm lcp -g grp_id -c ctr_id
cpcode = "jgrinwis"

# our security configuration
security_configuration = "WAF Security File"

# security policy to attach this property to. Security policy should be part of security config var.security_configuration
security_policy = "Monitoring Only Security Policy"
