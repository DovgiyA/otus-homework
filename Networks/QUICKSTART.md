# Quick Start Guide

Быстрый старт для запуска OTUS Network Lab.

## Требования

- **Vagrant** 2.3+
- **VirtualBox** 7.0+ ИЛИ **VMware Desktop** 13.0+
- **Ansible** 2.9+
- **2+ GB RAM** и **2+ CPU** на хост-машине

## Установка

### macOS с VirtualBox (по умолчанию)

```bash
# Просто запустить (VirtualBox используется по умолчанию)
vagrant up --provision
```

### macOS M1 с VMware Desktop (если нужно)

```bash
# Установить Vagrant plugin для VMware
vagrant plugin install vagrant-vmware-desktop

# Запустить лабораторию
VAGRANT_DEFAULT_PROVIDER=vmware_desktop vagrant up --provision
```

## Основные команды

```bash
# Запустить лабораторию с provisioning
vagrant up --provision

# SSH на любую машину
vagrant ssh inetRouter
vagrant ssh centralRouter
vagrant ssh office1Server
vagrant ssh office2Server
# и т.д.

# Остановить лабораторию
vagrant halt

# Удалить все VM
vagrant destroy -f

# Перепровизировать (переприменить Ansible)
vagrant provision
```

## Быстрая проверка

После `vagrant up --provision` проверить, что всё работает:

```bash
# Проверить, что машины запущены
vagrant status

# SSH на server и проверить сеть
vagrant ssh office1Server
$ ip route | grep default
# Должно быть: default via 192.168.200.10 dev eth1

$ ping 192.168.200.10
# Gateway должен быть доступен

$ ping 192.168.200.21
# Centralserver должен быть доступен

$ ping 192.168.200.23
# office2Server должен быть доступен

$ ping 8.8.8.8
# Интернет через inetRouter

# SSH на router и проверить маршрутизацию
vagrant ssh centralRouter
$ ip route
# Должны быть маршруты ко всем сетям

$ sysctl net.ipv4.ip_forward
# Должен быть 1
```

## Запуск тестов

```bash
# Все тесты
bash tests/run_tests.sh

# Конкретные тесты
bash tests/test_pings.sh          # Проверка ping между VM
bash tests/test_routes.sh         # Проверка таблиц маршрутизации
bash tests/test_forwarding.sh     # Проверка IP forwarding
```

## Структура виртуальных машин

```
Все машины на одной сети (192.168.200.0/24):

inetRouter (192.168.200.10) - шлюз в интернет
├── eth0: Vagrant NAT
└── eth1: сеть 192.168.200.0/24 (vmnet6)

centralRouter (192.168.200.11) - хаб маршрутизации
├── eth0: Vagrant NAT
└── eth1: сеть 192.168.200.0/24 (vmnet6)

office1Router (192.168.200.12)
├── eth0: Vagrant NAT
└── eth1: сеть 192.168.200.0/24 (vmnet6)

office2Router (192.168.200.13)
├── eth0: Vagrant NAT
└── eth1: сеть 192.168.200.0/24 (vmnet6)

centralServer (192.168.200.21)
├── eth0: Vagrant NAT
└── eth1: сеть 192.168.200.0/24 (vmnet6)

office1Server (192.168.200.22)
├── eth0: Vagrant NAT
└── eth1: сеть 192.168.200.0/24 (vmnet6)

office2Server (192.168.200.23)
├── eth0: Vagrant NAT
└── eth1: сеть 192.168.200.0/24 (vmnet6)
```

## Решение проблем

### "Failed to enable device" на VMware

Используйте VirtualBox:

```bash
vagrant destroy -f
vagrant up --provision  # По умолчанию VirtualBox
```

### Машины не пингуют друг друга

```bash
# Проверить маршруты на роутере
vagrant ssh centralRouter -c "ip route"

# Проверить IP forwarding
vagrant ssh centralRouter -c "sysctl net.ipv4.ip_forward"

# Перепровизировать
vagrant provision
```

### Интернет не работает

```bash
# Проверить NAT на inetRouter
vagrant ssh inetRouter -c "sudo iptables -t nat -L -n -v"

# Проверить default route на routers
vagrant ssh centralRouter -c "ip route | grep default"
```
