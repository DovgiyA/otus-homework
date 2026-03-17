# Задание: Настройка LDAP-сервера и подключение LDAP-клиентов

## 1. Исходное задание

Цель: настроить LDAP-сервер FreeIPA и подключить LDAP-клиентов, включая SSH-аутентификацию по ключам и firewall.

Состав решения:
- `Vagrantfile` для 2 ВМ (`ipa-server`, `ldap-client`)
- Ansible playbooks для сервера, клиента и SSH-ключей
- Настройка firewalld на обеих машинах

## 2. Структура проекта

```text
LDAP/
├── Vagrantfile
├── README.md
└── ansible/
   ├── inventory.ini
   └── playbooks/
      ├── site.yml
      ├── server/
      │  └── freeipa-install.yml
      └── client/
         ├── freeipa-client-install.yml
         └── ssh-keys-setup.yml
```

## 3. Требования

- **VMware Fusion** (для Apple Silicon M1/M2/M3)
- **Vagrant** + плагин `vagrant-vmware-desktop`
- **Ansible**

```bash
vagrant plugin install vagrant-vmware-desktop
```

## 4. Команды запуска

### 4.1 Развертывание ВМ

```bash
vagrant up
```

Пример успешного вывода:

```text
Bringing machine 'ipa-server' up with 'vmware_desktop' provider...
Bringing machine 'ldap-client' up with 'vmware_desktop' provider...
...
ipa-server: Machine booted and ready!
ldap-client: Machine booted and ready!
```

### 4.2 Проверка доступности ВМ

```bash
vagrant status
```

Пример:

```text
Current machine states:

ipa-server                 running (vmware_desktop)
ldap-client                running (vmware_desktop)
```

### 4.3 Запуск Ansible playbooks

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/site.yml
```

Или по отдельности:

```bash
ansible-playbook -i ansible/inventory.ini ansible/playbooks/server/freeipa-install.yml
ansible-playbook -i ansible/inventory.ini ansible/playbooks/client/freeipa-client-install.yml
ansible-playbook -i ansible/inventory.ini ansible/playbooks/client/ssh-keys-setup.yml
```

Пример успешного вывода:

```text
PLAY RECAP *********************************************************************
ipa-server : ok=10   changed=1    unreachable=0 failed=0 skipped=2 rescued=0 ignored=0
ldap-client: ok=12   changed=4    unreachable=0 failed=0 skipped=0 rescued=0 ignored=0
```

## 5. Архитектура решения

### 5.1 Диаграмма взаимодействия

```text
+----------------------+            LDAP/Kerberos            +----------------------+
|   ldap-client        | <---------------------------------> |     ipa-server       |
| 172.16.1.11          |                                     | 172.16.1.10          |
| freeipa-client, sssd |                                     | freeipa-server       |
+----------------------+                                     +----------------------+
          |                                                           |
          +----------------------- SSH (keys via LDAP) ---------------+
```

### 5.2 Роли узлов

- **ipa-server**:
  - поднимает FreeIPA (LDAP + Kerberos + DNS)
  - хранит пользователей и их SSH-публичные ключи
  - управляет политиками аутентификации

- **ldap-client**:
  - вступает в домен FreeIPA
  - использует SSSD для LDAP/Kerberos аутентификации
  - получает SSH ключи через `sss_ssh_authorizedkeys`

### 5.3 Firewall правила

На `ipa-server` открыты:
- 80/tcp, 443/tcp (HTTP/HTTPS)
- 389/tcp, 636/tcp (LDAP/LDAPS)
- 88/tcp, 88/udp (Kerberos)
- 464/tcp, 464/udp (kpasswd)
- 123/udp (NTP)
- 53/tcp, 53/udp (DNS)

На `ldap-client` открыты:
- 22/tcp (SSH)
- 88/tcp, 88/udp
- 464/tcp, 464/udp
- 389/tcp, 636/tcp
- 123/udp

Все правила применяются через `ansible.posix.firewalld` с `permanent: true` и сохраняются после перезагрузки.

## 6. Особенности проектирования и реализации

- Использованы переменные в playbooks (`ipa_domain`, `ipa_realm`, списки портов).
- Идемпотентность:
  - проверка статуса сервиса `ipa.service` перед `ipa-server-install`
  - проверка `/etc/ipa/default.conf` перед `ipa-client-install`
  - повторный запуск playbooks не ломает конфигурацию
- Обработка ошибок:
  - автоматический uninstall при обнаружении сломанной установки
  - корректная настройка `/etc/hosts` для разрешения FQDN
- Выбор ОС/ПО:
  - `almalinux/9` (официальный ARM64-бокс для VMware на Apple Silicon)
  - `freeipa-server`, `freeipa-server-dns`, `freeipa-client`, `sssd`, `firewalld`

## 7. Проверка работоспособности

### 7.1 Проверка пользователя из LDAP

```bash
vagrant ssh ldap-client -c 'id ldapuser'
```

Ожидаемый вывод:

```text
uid=... ldapuser gid=... groups=...
```

### 7.2 Проверка получения SSH-ключа

```bash
vagrant ssh ldap-client -c 'sss_ssh_authorizedkeys ldapuser'
```

## 8. Заметки

### Трудности
- Автоматизация `ipa-server-install` и `ipa-client-install` в unattended-режиме
- Согласование DNS/hostname/FQDN между узлами
- Настройка сети в ARM64-образах на VMware Fusion

### Советы по отладке
- Проверка состояния IPA:
  ```bash
  sudo ipactl status
  ```
- Проверка клиента:
  ```bash
  ipa config-show
  getent passwd ldapuser
  ```
- Проверка firewall:
  ```bash
  sudo firewall-cmd --list-all
  ```

### Полезные ссылки
- https://www.freeipa.org/page/Documentation
- https://docs.ansible.com/
- https://firewalld.org/documentation/
- https://wiki.almalinux.org/installation/vagrant-boxes.html

## 9. Чеклист соответствия критериям

- [x] Vagrantfile разворачивает 2 ВМ (AlmaLinux 9 ARM64 на VMware Fusion)
- [x] FreeIPA сервер устанавливается playbook'ом
- [x] Клиент подключается к FreeIPA
- [x] Firewall включен и настроен на обеих ВМ
- [x] SSH-ключи LDAP пользователя настраиваются
- [x] Playbooks воспроизводимы и идемпотентны
- [x] README содержит команды и примеры вывода
