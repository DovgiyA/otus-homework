# Networks Lab - Architecture Redesign

## Changes Made

### Major Architecture Redesign

Проект был переспроектирован с упрощённой архитектуры (одна сеть vmnet6 для всех хостов) на **многосетевую архитектуру** с отдельными vmnet для каждого сегмента.

#### Previous Architecture (Single Network)
- Все 7 VM на одной сети: 192.168.200.0/24 (vmnet6)
- IP адресация 192.168.200.x для разделения функций
- Ограничение: не соответствовало исходному заданию

#### New Architecture (Multi-Network)
```
Office1 LAN         Office2 LAN         Central LAN
192.168.2.0/24      192.168.1.0/24      192.168.0.0/24
    │                   │                    │
(vmnet6)            (vmnet7)             (vmnet8)
    │                   │                    │
 office1Router ─── centralRouter ─── office2Router
 (192.168.254.2)  (192.168.254.1)  (192.168.253.2)
                       │
                      eth4
                   10.0.0.1
                  (vmnet11)
                       │
                  inetRouter
                  (10.0.0.2)
                      │
                 Internet (eth0)
```

### Files Modified

1. **Vagrantfile** - Полная переработка:
   - Добавлены 6 vmnet сетей (vmnet6-vmnet11)
   - Каждой VM назначены правильные IP адреса
   - centralRouter теперь имеет 5 интерфейсов (eth0-eth4)

2. **ansible/roles/router/tasks/main.yml** - Новые маршруты:
   - Статические маршруты для каждого роутера
   - inetRouter: NAT/MASQUERADE на eth0
   - centralRouter: маршруты к office1 и office2
   - office1/office2Router: маршруты к other office и central

3. **ansible/roles/server/tasks/main.yml** - Правильные шлюзы:
   - centralServer → 192.168.0.1 (через eth1 на vmnet8)
   - office1Server → 192.168.2.1 (через eth1 на vmnet6)
   - office2Server → 192.168.1.1 (через eth1 на vmnet7)

4. **ansible/inventory.yml** - Упрощённый инвентарь:
   - Удалены hardcoded gateway IPs из inventory
   - Всё управляется через Vagrantfile переменные

5. **README.md** - Полная документация:
   - Новая архитектура с диаграммами
   - Таблица маршрутизации для каждого хоста
   - Подробное описание всех 6 vmnet сетей

6. **QUICKSTART.md** - Создан новый файл:
   - Быстрый старт для развёртывания
   - Проверка после provisioning
   - Решение проблем

## Network Topology Details

### VirtualBox
- Использует `virtualbox__intnet` для создания internal networks
- Сетевые имена: "inet-central", "office1-central", etc.

### VMware Desktop
- Использует `vmware__network_name` для назначения vmnet
- vmnet6, vmnet7, vmnet8, vmnet9, vmnet10, vmnet11

### IP Addressing Scheme

| Network | Format | CIDR | vmnet | Для |
|---------|--------|------|-------|-----|
| Office1 Local | 192.168.2.0/24 | /24 | vmnet6 | office1Router + office1Server |
| Office2 Local | 192.168.1.0/24 | /24 | vmnet7 | office2Router + office2Server |
| Central Local | 192.168.0.0/24 | /24 | vmnet8 | centralRouter + centralServer |
| Office1↔Central | 192.168.254.0/24 | /24 | vmnet9 | office1Router + centralRouter |
| Office2↔Central | 192.168.253.0/24 | /24 | vmnet10 | office2Router + centralRouter |
| Central↔inetRouter | 10.0.0.0/24 | /24 | vmnet11 | centralRouter + inetRouter |

## Static Routes (Applied by Ansible)

### centralRouter
```bash
ip route add 192.168.2.0/24 via 192.168.254.2 dev eth1    # К office1
ip route add 192.168.1.0/24 via 192.168.253.2 dev eth2    # К office2
ip route add default via 10.0.0.2 dev eth4                # К иnetRouter
```

### office1Router
```bash
ip route add 192.168.0.0/24 via 192.168.254.1 dev eth2    # К central
ip route add 192.168.1.0/24 via 192.168.254.1 dev eth2    # К office2
ip route add default via 192.168.254.1 dev eth2            # К иnetRouter (через central)
```

### office2Router
```bash
ip route add 192.168.0.0/24 via 192.168.253.1 dev eth2    # К central
ip route add 192.168.2.0/24 via 192.168.253.1 dev eth2    # К office1
ip route add default via 192.168.253.1 dev eth2            # К иnetRouter (через central)
```

## Testing Expected Results

После `vagrant up --provision`:

✓ **Intra-office connectivity**: office1Server ↔ office1Router  
✓ **Cross-office connectivity**: office1Server → office2Server (через centralRouter)  
✓ **Internet connectivity**: office1Server → 8.8.8.8 (через centralRouter → inetRouter)  
✓ **IP forwarding**: включён на всех роутерах  
✓ **Route persistence**: маршруты восстанавливаются после boot  
✓ **NAT**: MASQUERADE на inetRouter работает  

## Previous Issues Fixed

1. ✓ **Single vmnet limitation** - теперь используется 6 отдельных vmnet для изоляции трафика
2. ✓ **Architecture mismatch** - реальная архитектура соответствует исходному заданию  
3. ✓ **Complex routing logic** - явные статические маршруты вместо ad-hoc правил
4. ✓ **Central router as true hub** - centralRouter теперь действительно маршрутизирует трафик между всеми сегментами

## Deployment Instructions

```bash
# Clean start
vagrant destroy -f

# Fresh deployment (выбрать провайдер)
VAGRANT_DEFAULT_PROVIDER=vmware_desktop vagrant up --provision  # VMware
# или просто
vagrant up --provision                                          # VirtualBox

# Run tests
bash tests/run_tests.sh
```

## Compatibility

- **VirtualBox 7.0+**: ✓ Поддерживается (default)
- **VMware Desktop 13.0+ (M1)**: ✓ Поддерживается (требует vmnet6-vmnet11)
- **Ansible 2.9+**: ✓
- **Vagrant 2.3+**: ✓

## Notes for VMware Users

Если VMware не может создать 6 vmnet сетей:

```bash
# Проверить доступные vmnet
nmcfg list

# Если лимит, переключиться на VirtualBox
vagrant destroy -f
vagrant up --provision  # vmware_desktop не указан, будет VirtualBox
```

---

**Last Updated**: March 16, 2026  
**Status**: ✓ Ready for testing
