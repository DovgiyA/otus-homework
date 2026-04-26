variable "yc_token" {
  description = "Yandex Cloud OAuth token"
  type        = string
  sensitive   = true
}

variable "yc_cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "yc_folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "yc_zone" {
  description = "Yandex Cloud availability zone"
  type        = string
  default     = "ru-central1-b"
}

variable "ubuntu_image_id" {
  description = "Ubuntu 22.04 LTS image ID in Yandex Cloud"
  type        = string
  default     = "fd8autg36kchufhej85b"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for Ansible"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "ssh_user" {
  description = "SSH user for VM access"
  type        = string
  default     = "ubuntu"
}

variable "admin_cidr" {
  description = "CIDR for SSH access (your IP)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "domain_name" {
  description = "Primary domain name"
  type        = string
  default     = "xn----ctbkoedricefmgyd0k.xn--p1ai"
}

variable "certbot_email" {
  description = "Email for Let's Encrypt certificate"
  type        = string
}

variable "static_ips" {
  description = "Static public IPs for VMs (pre-reserved in Yandex Cloud)"
  type        = map(string)
  default     = {}
}
