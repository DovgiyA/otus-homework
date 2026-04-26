locals {
  vms = {
    frontend = {
      cores           = 2
      memory          = 2
      disk_size       = 15
      security_groups = [yandex_vpc_security_group.frontend.id]
      nat             = true
    }
    backend-db = {
      cores           = 2
      memory          = 4
      disk_size       = 30
      security_groups = [yandex_vpc_security_group.backend_db.id]
      nat             = true
    }
    db-replica = {
      cores           = 2
      memory          = 4
      disk_size       = 30
      security_groups = [yandex_vpc_security_group.db_replica.id]
      nat             = true
    }
    backup = {
      cores           = 2
      memory          = 4
      disk_size       = 30
      security_groups = [yandex_vpc_security_group.backup.id]
      nat             = true
    }
    monitor = {
      cores           = 2
      memory          = 4
      disk_size       = 30
      security_groups = [yandex_vpc_security_group.monitoring.id]
      nat             = true
    }
  }
}

resource "yandex_compute_instance" "vm" {
  for_each    = local.vms
  name        = each.key
  hostname    = each.key
  platform_id = "standard-v3"
  zone        = var.yc_zone

  resources {
    cores  = each.value.cores
    memory = each.value.memory
  }

  boot_disk {
    initialize_params {
      image_id = var.ubuntu_image_id
      size     = each.value.disk_size
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = data.yandex_vpc_subnet.speedtest.id
    nat                = each.value.nat
    nat_ip_address     = lookup(var.static_ips, each.key, null)
    security_group_ids = each.value.security_groups
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(pathexpand(var.ssh_public_key_path))}"
  }

  scheduling_policy {
    preemptible = false
  }
}
