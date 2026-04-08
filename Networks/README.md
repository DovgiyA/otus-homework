# OTUS Linux Network Lab - Vagrant + Ansible

Сетевая лаборатория для OTUS Linux, реализованная с использованием Vagrant и Ansible. Совместима с VMware Desktop (M1 MacBook) и VirtualBox.

## Упрощённая архитектура (совместимость с VMware и VirtualBox)

Для обхода ограничений VMware на количество виртуальных сетей используется **одна сеть** (192.168.200.0/24) для всех внутренних соединений. Логическое разделение на "офисы" осуществляется через IP-адресацию и маршрутизацию.

```
                        Internet
                           ↑
                           │ (eth0 NAT)
                       inetRouter
                      (192.168.200.10)
                           │
                    vmnet6 / 192.168.200.0/24
                      (eth1)
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   centralRouter      office1Router      office2Router
   (192.168.200.11)   (192.168.200.12)   (192.168.200.13)
        │                  │                  │
   centralServer      office1Server      office2Server
   (192.168.200.21)   (192.168.200.22)   (192.168.200.23)
```

## Виртуальные машины (7 шт)

| Имя | IP-адрес | Роль |
|-----|----------|------|
| inetRouter | 192.168.200.10 | Шлюз в интернет (NAT/MASQUERADE на eth0) |
| centralRouter | 192.168.200.11 | Центральный маршрутизатор (хаб маршрутизации) |
| office1Router | 192.168.200.12 | Маршрутизатор офиса 1 |
| office2Router | 192.168.200.13 | Маршрутизатор офиса 2 |
| centralServer | 192.168.200.21 | Сервер центрального офиса |
| office1Server | 192.168.200.22 | Сервер офиса 1 |
| office2Server | 192.168.200.23 | Сервер офиса 2 |

## Архитектура сети (ДЛЯ СПРАВКИ — исходное задание)

**Логическая структура подсетей, указанная в задании:**

| Назначение | Подсеть | Маска | Хосты | Шлюз |
|-----------|--------|-------|-------|------|
| dev | 192.168.2.0/26 | /26 | 62 | 192.168.2.1 |
| test servers | 192.168.2.64/26 | /26 | 62 | 192.168.2.1 |
| managers | 192.168.2.128/26 | /26 | 62 | 192.168.2.1 |
| office hardware | 192.168.2.192/26 | /26 | 62 | 192.168.2.1 |

**Примечание**: `office1Server` использует IP `192.168.2.2`, `office1Router eth1` = `192.168.2.1` (шлюз)

### Office 2 Network (vmnet7)
Адресное пространство: `192.168.1.0/24` (256 адресов)

| Назначение | Подсеть | Маска | Хосты | Шлюз |
|-----------|--------|-------|-------|------|
| dev | 192.168.1.0/25 | /25 | 126 | 192.168.1.1 |
| test servers | 192.168.1.128/26 | /26 | 62 | 192.168.1.1 |
| office hardware | 192.168.1.192/26 | /26 | 62 | 192.168.1.1 |

**Примечание**: `office2Server` использует IP `192.168.1.2`, `office2Router eth1` = `192.168.1.1` (шлюз)

## Таблица маршрутизации (реальная конфигурация)

Все маршрутизаторы и серверы используют **inetRouter** (192.168.200.10) как default gateway.

| Хост | Default Gateway | Интерфейс |
|------|-----------------|-----------|
| inetRouter | (internet via eth0 NAT) | eth0 |
| centralRouter | 192.168.200.10 | eth1 |
| office1Router | 192.168.200.10 | eth1 |
| office2Router | 192.168.200.10 | eth1 |
| centralServer | 192.168.200.10 | eth1 |
| office1Server | 192.168.200.10 | eth1 |
| office2Server | 192.168.200.10 | eth1 |

## Запуск

### Требования

- Vagrant 2.3+
- VirtualBox 7.0+ ИЛИ VMware Desktop 13.0+
- Ansible 2.9+
- 2+ GB RAM, 2+ CPU на хост-машине

### Инструкции

```bash
cd /Users/a1/otus-homework/Networks

# VirtualBox (по умолчанию)
vagrant up --provision

# VMware Desktop (M1 MacBook) - если нужно
VAGRANT_DEFAULT_PROVIDER=vmware_desktop vagrant up --provision
```

### SSH доступ к машинам

```bash
vagrant ssh inetRouter
vagrant ssh centralRouter
vagrant ssh centralServer
vagrant ssh office1Router
vagrant ssh office1Server
vagrant ssh office2Router
vagrant ssh office2Server
```

### Остановка и удаление

```bash
vagrant halt           # Остановить все VM
vagrant destroy -f     # Удалить все VM
```

## Проверка и тестирование

### Быстрая проверка после `vagrant up --provision`

**На любом сервере** (например office1Server):
```bash
vagrant ssh office1Server

# Проверить маршруты
$ ip route | grep default
# Должно быть: default via 192.168.200.10 dev eth1

# Пингануть шлюз
$ ping 192.168.200.10

# Пингануть другие серверы
$ ping 192.168.200.21  # centralServer
$ ping 192.168.200.23  # office2Server

# Проверить интернет
$ ping 8.8.8.8
```

**На роутерах**:
```bash
vagrant ssh centralRouter

# Проверить IP forwarding (должно быть 1)
$ sysctl net.ipv4.ip_forward

# Проверить таблицу маршрутизации
$ ip route

# Проверить NAT правила на inetRouter
$ vagrant ssh inetRouter -c "sudo iptables -t nat -L -n -v | grep MASQUERADE"
```

### Автоматизированные тесты

```bash
# Запустить все тесты
bash tests/run_tests.sh

# Конкретные тесты
bash tests/test_pings.sh          # Проверка ping между VM
bash tests/test_routes.sh         # Проверка таблиц маршрутизации
bash tests/test_forwarding.sh     # Проверка IP forwarding на роутерах
```

**Ожидаемые результаты тестов**:
- ✓ Все серверы пингуют шлюз (192.168.200.10)
- ✓ Кросс-офисное соединение работает (office1 ↔ office2)
- ✓ Интернет доступен со всех серверов (8.8.8.8)
- ✓ IP forwarding включен на всех роутерах (значение = 1)
- ✓ Никаких маршрутов к 10.0.2.0/24 (Vagrant NAT) после provisioning

## Структура проекта

```
.
├── Vagrantfile                      # 7 VM на одной сети (vmnet6)
├── ansible/
│   ├── ansible.cfg                  # Конфигурация Ansible
│   ├── inventory.yml               # Инвентарь хостов
│   ├── playbooks/
│   │   ├── common.yml              # Обновления, установка утилит
│   │   ├── networking.yml          # Вызов ролей маршрутизации
│   │   └── site.yml                # Главный playbook
│   └── roles/
│       ├── router/
│       │   ├── handlers/main.yml    # Обработчики для сервисов
│       │   └── tasks/main.yml       # Конфигурация маршрутизации, NAT
│       └── server/
│           └── tasks/main.yml       # Конфигурация шлюза по-умолчанию
├── tests/
│   ├── run_tests.sh
│   ├── test_pings.sh
│   ├── test_routes.sh
│   └── test_forwarding.sh
├── README.md
├── QUICKSTART.md
└── FIXES.md
```

## Возможные проблемы и решения

### VMware: "Failed to enable device"

**Причина**: Невозможно создать vmnet сеть (лимит или конфигурация).

**Решение**: Используйте VirtualBox (по умолчанию):
```bash
vagrant destroy -f
vagrant up --provision  # Автоматически использует VirtualBox
```

### Машины не пингуют друг друга

**Проверить IP forwarding на роутерах**:
```bash
vagrant ssh inetRouter -c "sysctl net.ipv4.ip_forward"
vagrant ssh centralRouter -c "sysctl net.ipv4.ip_forward"
# Должно быть: net.ipv4.ip_forward = 1
```

**Перепровизировать**:
```bash
vagrant provision
```

### Интернет недоступен

**Проверить NAT на inetRouter**:
```bash
vagrant ssh inetRouter -c "sudo iptables -t nat -L -n -v | grep MASQUERADE"
# Должно быть правило MASQUERADE
```

## Ключевые особенности

- **Одна vmnet-сеть** — совместимость с VMware на M1
- **NAT/MASQUERADE** на inetRouter для доступа в интернет
- **IP forwarding** на всех роутерах
- **Route persistence** через systemd-сервис
- **Idempotent Ansible** — безопасно запускать многократно
- **Поддержка обоих гипервизоров** — VirtualBox и VMware Desktop

## Лицензия

Учебный проект для OTUS Linux.
