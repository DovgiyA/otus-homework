# OTUS Linux Network Lab - Vagrant + Ansible

Сетевая лаборатория для OTUS Linux, реализованная с использованием Vagrant и Ansible. Совместима с VMware Desktop (M1 MacBook) и VirtualBox.

## Архитектура сети

```
                        Internet
                           ↑
                           │ eth0 (NAT Vagrant)  
                       inetRouter
                      (10.0.0.2)
                           │
                    vmnet11 / 10.0.0.0/24
                      eth1: 10.0.0.2
                           │
                    eth4: 10.0.0.1
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   eth1: 192.168.254.1 centralRouter     eth2: 192.168.253.1
   eth2: 192.168.253.1  (hub router)     
   eth3: 192.168.0.1                        │
        │                  │                │
   vmnet9          vmnet8 / vmnet10    vmnet10
192.168.254.0/24 192.168.0.0/24      192.168.253.0/24
        │          office1Router ←→  office2Router
        │       192.168.254.2  192.168.253.2
        │              │                  │
        │         eth1: 192.168.2.1  eth1: 192.168.1.1
        │         vmnet6                vmnet7
        │         192.168.2.0/24        192.168.1.0/24
        │              │                  │
   office1Router   office1Server      office2Server
   eth2: 192.168.254.2 192.168.2.2   192.168.1.2
        │
   centralServer
   eth1: 192.168.0.2
```

## Виртуальные машины (7 шт)

| Имя | Localnet IP | Роль |
|-----|------------|------|
| inetRouter | 10.0.0.2 | Шлюз в интернет (NAT/MASQUERADE на eth0) |
| centralRouter | 10.0.0.1 (eth4), 192.168.254.1 (eth1), 192.168.253.1 (eth2), 192.168.0.1 (eth3) | Хаб-маршрутизатор, соединяет все сети |
| office1Router | 192.168.254.2 (eth2), 192.168.2.1 (eth1) | Маршрутизатор офиса 1 |
| office2Router | 192.168.253.2 (eth2), 192.168.1.1 (eth1) | Маршрутизатор офиса 2 |
| centralServer | 192.168.0.2 | Сервер центрального офиса |
| office1Server | 192.168.2.2 | Сервер офиса 1 |
| office2Server | 192.168.1.2 | Сервер офиса 2 |

## Сетевые сегменты

### Office 1 Network (vmnet6)
Адресное пространство: `192.168.2.0/24` (256 адресов)

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

### Central Network (vmnet8)
Адресное пространство: `192.168.0.0/24` (256 адресов)

| Назначение | Подсеть | Маска | Хосты | Шлюз |
|-----------|--------|-------|-------|------|
| directors | 192.168.0.0/28 | /28 | 14 | 192.168.0.1 |
| office hardware | 192.168.0.32/28 | /28 | 14 | 192.168.0.1 |
| wifi | 192.168.0.64/26 | /26 | 62 | 192.168.0.1 |

**Примечание**: `centralServer` использует IP `192.168.0.2`, `centralRouter eth3` = `192.168.0.1` (шлюз)

## Сегменты маршрутизации (transit networks)

### Office1 ↔ Central Transit (vmnet9)
- Сеть: 192.168.254.0/24
- `office1Router eth2`: 192.168.254.2
- `centralRouter eth1`: 192.168.254.1

### Office2 ↔ Central Transit (vmnet10)
- Сеть: 192.168.253.0/24
- `office2Router eth2`: 192.168.253.2
- `centralRouter eth2`: 192.168.253.1

### Central ↔ inetRouter Transit (vmnet11)
- Сеть: 10.0.0.0/24
- `centralRouter eth4`: 10.0.0.1
- `inetRouter eth1`: 10.0.0.2

## Таблица маршрутизации

### inetRouter
```
Destination     Gateway         Interface
0.0.0.0/0       <default>       eth0 (интернет)
10.0.0.0/24     direct          eth1
192.168.0.0/24  10.0.0.1        eth1 (central)
192.168.1.0/24  10.0.0.1        eth1 (office2)
192.168.2.0/24  10.0.0.1        eth1 (office1)
```

### centralRouter
```
Destination     Gateway         Interface
0.0.0.0/0       10.0.0.2        eth4 (к иnetRouter)
10.0.0.0/24     direct          eth4
192.168.0.0/24  direct          eth3 (central local)
192.168.1.0/24  192.168.253.2   eth2 (office2)
192.168.2.0/24  192.168.254.2   eth1 (office1)
192.168.253.0/24 direct         eth2
192.168.254.0/24 direct         eth1
```

### office1Router
```
Destination     Gateway         Interface
0.0.0.0/0       192.168.254.1   eth2 (к centralRouter)
192.168.0.0/24  192.168.254.1   eth2 (central)
192.168.1.0/24  192.168.254.1   eth2 (office2)
192.168.2.0/24  direct          eth1 (local)
192.168.254.0/24 direct         eth2
```

### office2Router
```
Destination     Gateway         Interface
0.0.0.0/0       192.168.253.1   eth2 (к centralRouter)
192.168.0.0/24  192.168.253.1   eth2 (central)
192.168.2.0/24  192.168.253.1   eth2 (office1)
192.168.1.0/24  direct          eth1 (local)
192.168.253.0/24 direct         eth2
```

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

# VMware Desktop (M1 MacBook)
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
$ ip route

# Проверить локальный шлюз
$ ping 192.168.2.1

# Проверить доступ к центру
$ ping 192.168.0.1
$ ping 192.168.0.2

# Проверить доступ к office2
$ ping 192.168.1.1
$ ping 192.168.1.2

# Проверить интернет через inetRouter
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
$ vagrant ssh inetRouter -c "sudo iptables -t nat -L -n -v"
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
- ✓ Все серверы пингуют свои локальные шлюзы
- ✓ Кросс-офисное соединение работает (office1 ↔ office2 через central)
- ✓ Интернет доступен со всех серверов (8.8.8.8)
- ✓ Таблицы маршрутизации корректны на всех роутерах
- ✓ IP forwarding включен на всех роутерах (значение = 1)
- ✓ Никаких маршрутов к 10.0.2.0/24 (Vagrant NAT) после provisioning

## Структура проекта

```
.
├── Vagrantfile                      # 7 VM с многосетевой топологией
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
│       │   └── tasks/main.yml       # Конфигурация маршрутизации, NAT, статические маршруты
│       └── server/
│           └── tasks/main.yml       # Конфигурация шлюзов по-умолчанию
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

**Причина**: Превышено максимальное количество vmnet-сетей.

**Решение**: Данный проект использует 6 отдельных vmnet (vmnet6-vmnet11). Если VMware не может создать столько сетей, переведите на VirtualBox:
```bash
vagrant destroy -f
vagrant up --provision  # По умолчанию используется VirtualBox
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

**Проверить маршруты на роутерах**:
```bash
vagrant ssh centralRouter -c "ip route | grep default"
# Должно быть: default via 10.0.0.2 dev eth4
```

### Ansible не может подключиться

Vagrant автоматически генерирует inventory. Если проблема возникает:
```bash
vagrant destroy -f
vagrant up --provision
```

## Ключевые особенности

- **Многосетевая архитектура** — отдельные vmnet для каждого сегмента
- **NAT/MASQUERADE на inetRouter** — доступ в интернет из всех офисов
- **IP forwarding на всех маршрутизаторах** — маршрутизация между сегментами
- **Статические маршруты** — явное управление потоками трафика
- **Route persistence** — маршруты сохраняются после перезагрузки через systemd-сервис
- **Idempotent Ansible** — безопасно запускать playbook многократно
- **Поддержка VirtualBox и VMware Desktop** — совместимость с обоими гипервизорами

## Лицензия

Учебный проект для OTUS Linux.
