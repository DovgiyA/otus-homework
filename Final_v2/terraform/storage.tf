resource "yandex_iam_service_account" "backup_sa" {
  name        = "speedtest-backup-sa"
  description = "Service account for PostgreSQL backups to Object Storage"
}

resource "yandex_resourcemanager_folder_iam_member" "backup_sa_storage" {
  folder_id = var.yc_folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.backup_sa.id}"
}

resource "yandex_iam_service_account_static_access_key" "backup_sa_key" {
  service_account_id = yandex_iam_service_account.backup_sa.id
  description        = "Static access key for S3 backups"
}

resource "yandex_storage_bucket" "backups" {
  bucket     = "speedtest-db-backups-${var.yc_folder_id}"
  access_key = yandex_iam_service_account_static_access_key.backup_sa_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.backup_sa_key.secret_key

  lifecycle_rule {
    id      = "daily-cleanup"
    enabled = true

    filter {
      prefix = "daily/"
    }

    expiration {
      days = 7
    }
  }

  lifecycle_rule {
    id      = "weekly-cleanup"
    enabled = true

    filter {
      prefix = "weekly/"
    }

    expiration {
      days = 30
    }
  }

  depends_on = [yandex_resourcemanager_folder_iam_member.backup_sa_storage]
}
