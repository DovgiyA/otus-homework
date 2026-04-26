output "frontend_public_ip" {
  value = yandex_compute_instance.vm["frontend"].network_interface.0.nat_ip_address
}

output "frontend_private_ip" {
  value = yandex_compute_instance.vm["frontend"].network_interface.0.ip_address
}

output "backend_db_public_ip" {
  value = yandex_compute_instance.vm["backend-db"].network_interface.0.nat_ip_address
}

output "backend_db_private_ip" {
  value = yandex_compute_instance.vm["backend-db"].network_interface.0.ip_address
}

output "db_replica_public_ip" {
  value = yandex_compute_instance.vm["db-replica"].network_interface.0.nat_ip_address
}

output "db_replica_private_ip" {
  value = yandex_compute_instance.vm["db-replica"].network_interface.0.ip_address
}

output "backup_public_ip" {
  value = yandex_compute_instance.vm["backup"].network_interface.0.nat_ip_address
}

output "backup_private_ip" {
  value = yandex_compute_instance.vm["backup"].network_interface.0.ip_address
}

output "monitor_public_ip" {
  value = yandex_compute_instance.vm["monitor"].network_interface.0.nat_ip_address
}

output "monitor_private_ip" {
  value = yandex_compute_instance.vm["monitor"].network_interface.0.ip_address
}

output "s3_access_key" {
  value     = yandex_iam_service_account_static_access_key.backup_sa_key.access_key
  sensitive = true
}

output "s3_secret_key" {
  value     = yandex_iam_service_account_static_access_key.backup_sa_key.secret_key
  sensitive = true
}

output "s3_bucket_name" {
  value = yandex_storage_bucket.backups.bucket
}
