# Quick Start Guide

Быстрый старт для запуска OTUS Network Lab.

## Требования

- **Vagrant** 2.3+
- **VirtualBox** 7.0+ ИЛИ **VMware Desktop** 13.0+
- **Ansible** 2.9+
- **2+ GB RAM** и **2+ CPU** на хост-машине

## Установка

### macOS M1 с VMware Desktop

```bash
# Установить Vagrant plugin для VMware
vagrant plugin install vagrant-vmware-desktop

# Запустить лабораторию
VAGRANT_DEFAULT_PROVIDER=vmware_desktop vagrant up --provision
```

### macOS/Linux/Windows с VirtualBox

```bash
# Просто запустить (VirtualBox используется по умолчанию)
vagrant up --provision
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
$ ip route                        # Должен быть default via 192.168.2.1
$ ping 192.168.2.1               # Gateway должен быть доступен
$ ping 192.168.0.2               # Должен пинговать centralServer (кросс-офис)
$ ping 192.168.1.2               # Должен пинговать office2Server (кросс-офис)
$ ping 8.8.8.8                   # Интернет через inetRouter

# SSH на router и проверить маршрутизацию
vagrant ssh centralRouter
$ ip route                        # Должны быть маршруты ко всем сетям
$ sysctl net.ipv4.ip_forward     # Должен быть 1
$ ip addr                         # Должны быть 5 интерфейсов (eth0-eth4)
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
inetRouter (шлюз в интернет)
├── eth0: Vagrant NAT
└── eth1: Transit to Central (10.0.0.2 на vmnet11)

centralRouter (хаб маршрутизации)
├── eth0: Vagrant NAT
├── eth1: Office1 Transit (192.168.254.1 на vmnet9)
├── eth2: Office2 Transit (192.168.253.1 на vmnet10)
├── eth3: Central LAN (192.168.0.1 на vmnet8)
└── eth4: inetRouter Transit (10.0.0.1 на vmnet11)

office1Router
├── eth0: Vagrant NAT
├── eth1: Office1 LAN (192.168.2.1 на vmnet6)
└── eth2: Central Transit (192.168.254.2 на vmnet9)

office2Router
├── eth0: Vagrant NAT
├── eth1: Office2 LAN (192.168.1.1 на vmnet7)
└── eth2: Central Transit (192.168.253.2 на vmnet10)

centralServer
├── eth0: Vagrant NAT
└── eth1: Central LAN (192.168.0.2 на vmnet8)

office1Server
├── eth0: Vagrant NAT
└── eth1: Office1 LAN (192.168.2.2 на vmnet6)

office2Server
├── eth0: Vagrant NAT
└── eth1: Office2 LAN (192.168.1.2 на vmnet7)
```

## Решение проблем

### VMware: "Failed to enable device"

Если VMware не может создать 6 отдельных сетей, используйте VirtualBox:

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

# Проверить default route на centralRouter
vagrant ssh centralRouter -c "ip route | grep default"
```

## Топология сети

```
Office1 (192.168.2.0/24)
  office1Server: 192.168.2.2
  office1Router: 192.168.2.1 (local) + 192.168.254.2 (transit)
         │
         └──────────────────────────────┐
                    vmnet9              │
            192.168.254.0/24            │
                    │                   │
                    │                   │
        ┌───────────────────────────────┐
        │                               │
   centralRouter──────────────────office2Router
   (hub-маршрутизатор)            (маршрутизатор office2)
   ├─ eth1: 192.168.254.1         ├─ eth1: 192.168.1.1
   ├─ eth2: 192.168.253.1         └─ eth2: 192.168.253.2
   ├─ eth3: 192.168.0.1               │
   └─ eth4: 10.0.0.1                  │
       │                              │
       ├─ centralServer           office2Server
       │  192.168.0.2             192.168.1.2
       │
       └─ inetRouter
          10.0.0.2
          (NAT to Internet)

Все маршруты идут через centralRouter!
```
