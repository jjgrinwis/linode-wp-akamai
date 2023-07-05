output "origin_hostname" {
  description = "The ip address of our WP Linode instance"
  value       = local.origin_hostname
}

output "hostname" {
  description = "Our configured host/property name"
  value       = var.hostname
}

output "wp_password" {
  description = "Wordpress admin password"
  value       = resource.random_password.linode_root_password
  sensitive   = true
}
