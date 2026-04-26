---
all:
  vars:
    ansible_user: ${ssh_user}
    ansible_python_interpreter: /usr/bin/python3
    ansible_ssh_private_key_file: ${ssh_private_key_path}
    domain_name: "${domain_name}"
    domain_name_www: "www.${domain_name}"
    certbot_email: "${certbot_email}"

    # S3 backup credentials
    s3_access_key: "${s3_access_key}"
    s3_secret_key: "${s3_secret_key}"
    s3_bucket: "${s3_bucket}"
    s3_endpoint: "https://storage.yandexcloud.net"

    # IP mapping
    frontend_ip: "${frontend_private}"
    backend_db_ip: "${backend_db_private}"
    db_replica_ip: "${db_replica_private}"
    backup_ip: "${backup_private}"
    monitoring_ip: "${monitor_private}"

    # /etc/hosts entries
    etc_hosts_entries:
      - ip: "${frontend_private}"
        hostname: "frontend"
      - ip: "${backend_db_private}"
        hostname: "backend-db"
      - ip: "${db_replica_private}"
        hostname: "db-replica"
      - ip: "${backup_private}"
        hostname: "backup"
      - ip: "${monitor_private}"
        hostname: "monitor"

  children:
    frontend_group:
      vars:
        backend_listen_port: 8080
      hosts:
        frontend:
          ansible_host: ${frontend_public}
          private_ip: ${frontend_private}
          firewall_allowed_ports:
            - 22
            - 80
            - 443
            - 9100

    backend_db_group:
      hosts:
        backend-db:
          ansible_host: ${backend_db_public}
          private_ip: ${backend_db_private}
          firewall_allowed_ports:
            - 22
            - 80
            - 5432
            - 9100

    db_replica_group:
      hosts:
        db-replica:
          ansible_host: ${db_replica_public}
          private_ip: ${db_replica_private}
          firewall_allowed_ports:
            - 22
            - 5432
            - 9100

    backup_group:
      hosts:
        backup:
          ansible_host: ${backup_public}
          private_ip: ${backup_private}
          firewall_allowed_ports:
            - 22
            - 80
            - 443
            - 5432
            - 9100

    monitoring:
      hosts:
        monitor:
          ansible_host: ${monitor_public}
          private_ip: ${monitor_private}
          firewall_allowed_ports:
            - 22
            - 3000
            - 5601
            - 9090
            - 9093
            - 9100
            - 9200
            - 24224
