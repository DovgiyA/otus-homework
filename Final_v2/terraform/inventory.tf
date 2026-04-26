resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/hosts.yml.tpl", {
    ssh_user             = var.ssh_user
    ssh_private_key_path = var.ssh_private_key_path
    domain_name          = var.domain_name
    certbot_email        = var.certbot_email
    frontend_public      = yandex_compute_instance.vm["frontend"].network_interface.0.nat_ip_address
    frontend_private     = yandex_compute_instance.vm["frontend"].network_interface.0.ip_address
    backend_db_public    = yandex_compute_instance.vm["backend-db"].network_interface.0.nat_ip_address
    backend_db_private   = yandex_compute_instance.vm["backend-db"].network_interface.0.ip_address
    db_replica_public    = yandex_compute_instance.vm["db-replica"].network_interface.0.nat_ip_address
    db_replica_private   = yandex_compute_instance.vm["db-replica"].network_interface.0.ip_address
    backup_public        = yandex_compute_instance.vm["backup"].network_interface.0.nat_ip_address
    backup_private       = yandex_compute_instance.vm["backup"].network_interface.0.ip_address
    monitor_public       = yandex_compute_instance.vm["monitor"].network_interface.0.nat_ip_address
    monitor_private      = yandex_compute_instance.vm["monitor"].network_interface.0.ip_address
    s3_access_key        = yandex_iam_service_account_static_access_key.backup_sa_key.access_key
    s3_secret_key        = yandex_iam_service_account_static_access_key.backup_sa_key.secret_key
    s3_bucket            = yandex_storage_bucket.backups.bucket
  })
  filename = "${path.module}/../ansible/inventory/hosts.yml"

  file_permission = "0644"
}
