resource "yandex_vpc_security_group" "frontend" {
  name       = "frontend-sg"
  network_id = data.yandex_vpc_network.speedtest.id

  ingress {
    description    = "HTTP"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "HTTPS"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "SSH"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description    = "Node Exporter from internal"
    protocol       = "TCP"
    port           = 9100
    v4_cidr_blocks = ["10.129.0.0/24"]
  }

  ingress {
    description    = "Fluentd from internal"
    protocol       = "TCP"
    port           = 24224
    v4_cidr_blocks = ["10.129.0.0/24"]
  }

  egress {
    description    = "Allow all outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "backend_db" {
  name       = "backend-db-sg"
  network_id = data.yandex_vpc_network.speedtest.id

  ingress {
    description    = "SSH"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description    = "HTTP from frontend"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["10.129.0.0/24"]
  }

  ingress {
    description    = "PostgreSQL from internal"
    protocol       = "TCP"
    port           = 5432
    v4_cidr_blocks = ["10.129.0.0/24"]
  }

  ingress {
    description    = "Node Exporter from internal"
    protocol       = "TCP"
    port           = 9100
    v4_cidr_blocks = ["10.129.0.0/24"]
  }

  egress {
    description    = "Allow all outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "db_replica" {
  name       = "db-replica-sg"
  network_id = data.yandex_vpc_network.speedtest.id

  ingress {
    description    = "SSH"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description    = "PostgreSQL from internal"
    protocol       = "TCP"
    port           = 5432
    v4_cidr_blocks = ["10.129.0.0/24"]
  }

  ingress {
    description    = "Node Exporter from internal"
    protocol       = "TCP"
    port           = 9100
    v4_cidr_blocks = ["10.129.0.0/24"]
  }

  ingress {
    description    = "All internal traffic"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.129.0.0/24"]
  }

  egress {
    description    = "Allow all outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "backup" {
  name       = "backup-sg"
  network_id = data.yandex_vpc_network.speedtest.id

  ingress {
    description    = "SSH"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description    = "All internal traffic"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.129.0.0/24"]
  }

  ingress {
    description    = "HTTP (when acting as frontend)"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "HTTPS (when acting as frontend)"
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "Allow all outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "monitoring" {
  name       = "monitoring-sg"
  network_id = data.yandex_vpc_network.speedtest.id

  ingress {
    description    = "SSH"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description    = "Grafana"
    protocol       = "TCP"
    port           = 3000
    v4_cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description    = "Kibana"
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description    = "Prometheus"
    protocol       = "TCP"
    port           = 9090
    v4_cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description    = "All internal traffic"
    protocol       = "ANY"
    v4_cidr_blocks = ["10.129.0.0/24"]
  }

  egress {
    description    = "Allow all outbound"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
