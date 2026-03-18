# Split-DNS Лаборатория с Vagrant + Ansible на AlmaLinux 9

## 📌 Название задания
**Настройка Split-DNS в Linux-based системах с использованием BIND DNS сервера**

---

## 📖 Текст задания

### Цель
Создать домашнюю сетевую лабораторию для изучения основ DNS и технологии Split-DNS (split-view DNS) в Linux-based системах с использованием BIND DNS сервера, сохраняя при этом SELinux в режиме Enforcing.

### Требования

#### Инфраструктура
- **ОС:** AlmaLinux 9 (образ almalinux/9)
- **Гипервизор:** VMware Fusion Desktop (MacBook M1 Tahoe)
- **Инструменты:** Vagrant + Ansible

#### DNS архитектура
1. **DNS серверы:**
   - `ns01` (192.168.50.10) - master DNS сервер
   - `ns02` (192.168.50.11) - slave DNS сервер

2. **Клиенты:**
   - `client` (192.168.50.15) - тестовый клиент №1
   - `client2` (192.168.50.16) - тестовый клиент №2

#### DNS зоны и записи

**Зона `dns.lab`:**
- `ns01.dns.lab` → 192.168.50.10
- `ns02.dns.lab` → 192.168.50.11
- `web1.dns.lab` → 192.168.50.15 (client)
- `web2.dns.lab` → 192.168.50.16 (client2)

**Зона `newdns.lab`:**
- `ns01.newdns.lab` → 192.168.50.10
- `ns02.newdns.lab` → 192.168.50.11
- `www.newdns.lab` → 192.168.50.15 и 192.168.50.16 (оба клиента)

**Зона `ddns.lab`:**
- Зона с поддержкой динамических обновлений (DDNS)

#### Split-DNS правила

| Клиент | Видимые зоны | Видимые записи |
|--------|--------------|----------------|
| **client** (192.168.50.15) | dns.lab, newdns.lab | web1, www |
| **client2** (192.168.50.16) | dns.lab только | web2 |
| **Остальная сеть** | Все зоны | Все записи |

#### Зон-трансфер
- Master (ns01) отправляет полные зоны на Slave (ns02)
- Аутентификация: TSIG ключ (`zonetransfer.key`)
- Защита: Подпись всех zone transfer транзакций


---

### Быстрые команды для тестирования

```bash
# Проверить, что DNS работает на master
vagrant ssh ns01 -c "sudo systemctl status named"

# Проверить, что zone transfer прошел на slave
vagrant ssh ns02 -c "sudo ls -la /var/named/slaves/"

# Тестировать split-DNS с client
vagrant ssh client -c "nslookup web1.dns.lab 192.168.50.10"
vagrant ssh client -c "nslookup web2.dns.lab 192.168.50.10"

# Проверить SELinux статус
vagrant ssh ns01 -c "sudo getenforce"
```

---

## ✅ Результаты тестирования

### Статус инфраструктуры

| ВМ | IP адрес | BIND статус | SELinux |
|----|----------|------------|--------|
| ns01 (Master) | 192.168.50.10 | ✅ active (running) | ✅ Enforcing |
| ns02 (Slave) | 192.168.50.11 | ✅ active (running) | ✅ Enforcing |
| client | 192.168.50.15 | N/A (клиент) | ✅ Enforcing |
| client2 | 192.168.50.16 | N/A (клиент) | ✅ Enforcing |

### Zone Transfer (TSIG)

✅ **Все 4 зоны успешно получены на ns02:**
- `dns.lab.zone`
- `dns.lab.rev.zone`
- `newdns.lab.zone`
- `ddns.lab.zone`

### Split-DNS Тестирование (Все тесты успешны)

**Client (192.168.50.15):**
- ✅ `web1.dns.lab` → 192.168.50.15 (видит)
- ✅ `web2.dns.lab` → NXDOMAIN (НЕ видит)
- ✅ `www.newdns.lab` → 192.168.50.15 (видит)

**Client2 (192.168.50.16):**
- ✅ `web1.dns.lab` → NXDOMAIN (НЕ видит)
- ✅ `web2.dns.lab` → 192.168.50.16 (видит)
- ✅ `www.newdns.lab` → SERVFAIL (НЕ имеет доступа)

**Результат:** Split-DNS работает идеально! 🎉

---

## �🏗️ Особенности проектирования и реализации

### 1. Архитектура Split-DNS (Views)

VIEW ARCHITECTURE:
┌─────────────────────────────────────┐
│  BIND DNS Server (ns01, ns02)       │
├─────────────────────────────────────┤
│  Global Options (recursion, etc)    │
├─────────────────────────────────────┤
│  View "client1_view"                │
│  ├─ match-clients { 192.168.50.15 } │
│  ├─ zone "dns.lab"        (web1)    │
│  └─ zone "newdns.lab"     (www)     │
├─────────────────────────────────────┤
│  View "client2_view"                │
│  ├─ match-clients { 192.168.50.16 } │
│  ├─ zone "dns.lab"        (web2)    │
│  └─ [нет newdns.lab]                │
├─────────────────────────────────────┤
│  View "default_view"                │
│  ├─ match-clients { any }           │
│  ├─ zone "dns.lab"   (полная)       │
│  ├─ zone "newdns.lab" (полная)      │
│  └─ zone "ddns.lab"   (полная)      │
└─────────────────────────────────────┘
```

**Файлы зон:**
- `named.dns.lab` - полная зона (для slave и default view)
- `named.dns.lab.client1` - только web1 (для client1_view)
- `named.dns.lab.client2` - только web2 (для client2_view)
- `named.newdns.lab.client1` - www с IP client (для client1_view)
- `named.newdns.lab` - полная зона (для slave и default view)


### 2 VMware Fusion вместо VirtualBox

**Различия в Vagrantfile:**
```ruby
# VirtualBox
config.vm.provider "virtualbox" do |v|
  v.memory = 256
end

# VMware Fusion
config.vm.provider "vmware_fusion" do |v|
  v.vmx["memsize"] = "256"
  v.vmx["numvcpus"] = "1"
end
```
### 3. Файловая структура проекта

```
vagrant-bind/
├── Vagrantfile                    # Конфиг ВМ (VMware, AlmaLinux 9)
├── README.md                      # Этот файл
└── provisioning/
    ├── playbook.yml              # Главный Ansible playbook
    │
    ├── master-named.conf         # ns01: конфиг с views, TSIG
    ├── slave-named.conf          # ns02: конфиг slave mode
    │
    ├── named.dns.lab             # Полная зона (slave/default)
    ├── named.dns.lab.client1     # Зона для client (только web1)
    ├── named.dns.lab.client2     # Зона для client2 (только web2)
    │
    ├── named.newdns.lab          # Полная зона (slave/default)
    ├── named.newdns.lab.client1  # Зона для client (www)
    │
    ├── named.dns.lab.rev         # Reverse зона
    ├── named.ddns.lab            # DDNS зона
    ├── named.zonetransfer.key    # TSIG ключ (shared)
    │
    ├── rndc.conf                 # RNDC конфиг (управление DNS)
    ├── client-resolv.conf        # Resolv для client
    ├── client2-resolv.conf       # Resolv для client2
    ├── servers-resolv.conf       # Resolv для ns01, ns02
    └── client-motd               # Message of the day
```

---
