# Настройка VLAN и Bond на Linux

## Название задания
Настройка VLAN с помощью встроенных средств операционной системы Linux

## Текст задания
В Office1 в тестовой подсети появляются сервера с дополнительными интерфейсами и адресами:
- В internal сети testLAN:
  - testClient1 - 10.10.10.10
  - testClient2 - 10.10.20.10
  - testServer1 - 10.10.10.20
  - testServer2 - 10.10.20.20

Требуется:
1. Развести вланами: testClient1 <-> testServer1 (VLAN 10), testClient2 <-> testServer2 (VLAN 20)
2. Между centralRouter и inetRouter "пробросить" 2 линка и объединить их в bond, проверить работу с отключением интерфейсов

## Схема сети

```
                              +-----------------+
                              |   inetRouter    |
                              |  bond0:         |
                              |  192.168.10.10  |
                              +--------+--------+
                                       |
                              bond0 (active-backup)
                              eth1 (vmnet2) + eth2 (vmnet3)
                                       |
                              +--------+--------+
                              |  centralRouter  |
                              |  bond0:         |
                              |  192.168.10.20  |
                              |  VLAN10: 10.10.10.1/24
                              |  VLAN20: 10.10.20.1/24
                              +--------+--------+
                                       |
                                 trunk (eth3, vmnet4)
                                       |
                    +------------------+------------------+
                    |                                     |
              VLAN 10 (10.10.10.0/24)              VLAN 20 (10.10.20.0/24)
                    |                                     |
         +----------+----------+               +----------+----------+
         |                     |               |                     |
  +------+------+      +------+------+  +------+------+      +------+------+
  | testClient1 |      | testServer1 |  | testClient2 |      | testServer2 |
  | 10.10.10.10 |      | 10.10.10.20 |  | 10.10.20.10 |      | 10.10.20.20 |
  +-------------+      +-------------+  +-------------+      +-------------+
       VLAN 10              VLAN 10          VLAN 20              VLAN 20
```

> **Примечание:** адреса разделены по VLAN 10 и VLAN 20, что исключает конфликты и упрощает диагностику.

## Стек технологий

- **Vagrant** + **VMware Desktop** (bento/ubuntu-24.04)
- **Ansible** для автоматизации настройки
- **Netplan** (networkd) для конфигурации сети на Ubuntu
- Модули ядра: **8021q** (VLAN), **bonding** (bond)

## Описание команд и их вывод

### Настройка VLAN (через netplan)

#### Загрузка модуля 802.1Q
```bash
modprobe 8021q
echo "8021q" > /etc/modules-load.d/vlan.conf
```

#### Пример конфигурации netplan для VLAN
```yaml
# /etc/netplan/60-vlan10.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth2:
      dhcp4: false
  vlans:
    vlan10:
      id: 10
      link: eth2
      addresses:
        - 10.10.10.254/24
```

#### Применение конфигурации
```bash
netplan apply
```

#### Проверка VLAN
```bash
ip -d link show vlan10
```
Вывод:
```
6: vlan10@eth2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default qlen 1000
    link/ether 08:00:27:xx:xx:xx brd ff:ff:ff:ff:ff:ff promiscuity 0
    vlan protocol 802.1Q id 10 <REORDER_HDR> addrgenmode eui64 numtxqueuelen 1000
```

### Настройка Bond (через netplan)

#### Загрузка модуля bonding
```bash
modprobe bonding
echo "bonding" > /etc/modules-load.d/bonding.conf
```

#### Пример конфигурации netplan для bond
```yaml
# /etc/netplan/60-bond.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth1:
      dhcp4: false
    eth2:
      dhcp4: false
  bonds:
    bond0:
      interfaces:
        - eth1
        - eth2
      addresses:
        - 192.168.10.10/24
      parameters:
        mode: active-backup
        mii-monitor-interval: 100
        primary: eth1
```

#### Применение конфигурации
```bash
netplan apply
```

#### Проверка bond
```bash
cat /proc/net/bonding/bond0
```
Вывод:
```
Ethernet Channel Bonding Driver: v5.x

Bonding Mode: fault-tolerance (active-backup)
Primary Slave: eth1
Currently Active Slave: eth1
MII Status: up
MII Polling Interval (ms): 100

Slave Interface: eth1
MII Status: up
Speed: 1000 Mbps
Duplex: full

Slave Interface: eth2
MII Status: up
Speed: 1000 Mbps
Duplex: full
```

#### Тестирование отказоустойчивости bond
```bash
# Отключение активного интерфейса
ip link set eth1 down

# Проверка - трафик должен перейти на eth2
cat /proc/net/bonding/bond0
ping -c 3 192.168.10.20

# Включение обратно
ip link set eth1 up
```

### Проверка связности VLAN

```bash
# На testClient1 (VLAN 10)
ping 10.10.10.1  # testServer1

# На testClient2 (VLAN 20)
ping 10.10.20.20  # testServer2

# Проверка изоляции VLAN
# testClient1 не должен видеть testServer2
```



## Особенности проектирования и реализации

1. **Использование 802.1Q тегирования**: VLAN настраиваются на уровне ядра Linux через модуль 8021q. Это позволяет создавать виртуальные интерфейсы поверх физического trunk-порта.

2. **Bond в режиме active-backup**: Выбран режим отказоустойчивости, где активен только один интерфейс, второй находится в резерве. При падении активного интерфейса происходит автоматическое переключение.

3. **Одинаковые IP-адреса в разных VLAN**: testClient1 и testClient2 имеют одинаковый IP (10.10.10.254), как и testServer1/testServer2 (10.10.10.1). Это допустимо, так как VLAN изолируют broadcast-домены.

4. **Netplan вместо ifcfg**: Используется Ubuntu (bento/ubuntu-24.04) с netplan и systemd-networkd в качестве renderer. Конфигурация сети описывается в YAML-файлах `/etc/netplan/`.

5. **VMware Desktop**: Используется провайдер vmware_desktop с явным указанием vmnet:
   - vmnet2: bond link1 (192.168.10.0/24)
   - vmnet3: bond link2 (192.168.11.0/24)
   - vmnet4: trunk для VLAN

## Заметки

- Для тестирования bond можно использовать `tcpdump -i bond0` для мониторинга трафика
- Проверить настройки VLAN: `ip -d link show` или `bridge vlan show`
- Для отладки VLAN: `tcpdump -i eth3 -e | grep -i vlan`
- После отключения интерфейса bond восстанавливается автоматически при `ip link set ethX up`
- Конфигурация netplan хранится в `/etc/netplan/` и применяется командой `netplan apply`
