# Vagrant-стенд с PostgreSQL: репликация и резервное копирование

## Описание

Стенд из трёх виртуальных машин для демонстрации:
- **Hot Standby репликации** PostgreSQL 14 с использованием слотов
- **Резервного копирования** через Barman каждые 4 дня

## Архитектура

```
+-------------------+       +-------------------+       +-------------------+
|     master        |       |     replica        |       |     barman        |
| 192.168.50.11     |<------| 192.168.50.12      |       | 192.168.50.13     |
| PostgreSQL Master | WAL   | PostgreSQL Standby |       | Barman Backup     |
|                   |------>|  (hot_standby)     |       |                   |
|                   |       |                    |       |                   |
|                   |<------|--------------------+------>|                   |
+-------------------+  SSH + rsync backup                +-------------------+
```

| ВМ       | IP             | Роль                           | ОС            |
|----------|----------------|--------------------------------|---------------|
| master   | 192.168.50.11  | PostgreSQL Master               | Ubuntu 22.04  |
| replica  | 192.168.50.12  | PostgreSQL Replica (hot_standby)| Ubuntu 22.04  |
| barman   | 192.168.50.13  | Barman — резервное копирование  | Ubuntu 22.04  |

## Требования

- [Vagrant](https://www.vagrantup.com/) >= 2.3
- [VirtualBox](https://www.virtualbox.org/) >= 6.1
- [Ansible](https://www.ansible.com/) >= 2.12

## Быстрый старт

```bash
# Клонировать репозиторий и перейти в каталог
cd Postgres

# Запустить стенд (порядок важен: master → replica → barman)
vagrant up master
vagrant up replica
vagrant up barman
```

> **Важно:** ВМ следует поднимать последовательно, т.к. replica зависит от master,
> а barman — от master и SSH-ключей.

## Структура проекта

```
Postgres/
├── Vagrantfile                    # Описание ВМ
├── ansible.cfg                    # Конфигурация Ansible
├── inventory/
│   └── hosts                      # Инвентарь хостов
├── playbooks/
│   ├── master.yml                 # Плейбук для мастера
│   ├── replica.yml                # Плейбук для реплики
│   └── barman.yml                 # Плейбук для barman
├── roles/
│   ├── postgres-common/           # Общая установка PostgreSQL
│   ├── postgres-master/           # Настройка мастера
│   │   └── templates/
│   │       ├── postgresql.conf.j2 # Конфиг PostgreSQL (master)
│   │       └── pg_hba.conf.j2     # Аутентификация (master)
│   ├── postgres-replica/          # Настройка реплики
│   │   └── templates/
│   │       ├── postgresql.conf.j2 # Конфиг PostgreSQL (replica)
│   │       ├── pg_hba.conf.j2     # Аутентификация (replica)
│   │       └── standby.signal.j2  # Сигнальный файл standby
│   └── barman-server/             # Настройка barman
│       └── templates/
│           ├── barman.conf.j2     # Глобальный конфиг barman
│           └── master.conf.j2     # Конфиг сервера для barman
└── README.md
```

## Настройка hot_standby репликации

### Как это работает

1. **Мастер** (`master`) настроен с `wal_level = replica`, включённым `archive_mode`, и слотом репликации `standby_slot`
2. **Реплика** (`replica`) инициализируется через `pg_basebackup` с мастера
3. Вместо устаревшего `recovery.conf` (PG ≤ 11) используется:
   - Файл `standby.signal` — сигнализирует PostgreSQL о режиме standby
   - Параметры `primary_conninfo` и `primary_slot_name` в `postgresql.conf`

### Ключевые параметры postgresql.conf (master)

```
wal_level = replica
max_wal_senders = 5
max_replication_slots = 5
hot_standby = on
archive_mode = on
archive_command = 'cp %p /var/lib/postgresql/14/archive/%f'
```

### Ключевые параметры postgresql.conf (replica)

```
hot_standby = on
primary_conninfo = 'host=192.168.50.11 port=5432 user=replicator password=... application_name=replica'
primary_slot_name = 'standby_slot'
```

### pg_hba.conf (master)

Добавлены правила для подключения реплики и barman:
```
host    replication     replicator      192.168.50.12/32        scram-sha-256
host    all             barman          192.168.50.13/32        scram-sha-256
host    replication     barman          192.168.50.13/32        scram-sha-256
```

### Справка: recovery.conf (для PostgreSQL ≤ 11)

В PostgreSQL версий до 11 включительно вместо `standby.signal` и параметров в `postgresql.conf` использовался файл `recovery.conf`:

```
# recovery.conf (для PG <= 11, НЕ используется в данном стенде)
standby_mode = 'on'
primary_conninfo = 'host=192.168.50.11 port=5432 user=replicator password=ReplicaPass123 application_name=replica'
primary_slot_name = 'standby_slot'
trigger_file = '/tmp/postgresql.trigger'
restore_command = 'cp /var/lib/postgresql/archive/%f %p'
```

## Резервное копирование (Barman)

### Конфигурация

- **Метод бэкапа:** rsync (через SSH)
- **Сжатие:** gzip
- **Политика хранения:** 14 дней (RECOVERY WINDOW)
- **Расписание:** каждые 4 дня в 03:00

### Crontab для barman

```cron
# Обработка WAL — каждую минуту
* * * * * /usr/bin/barman cron

# Резервное копирование — каждые 4 дня в 03:00
0 3 */4 * * /usr/bin/barman backup master --wait 2>&1 | tee -a /var/log/barman/backup.log
```

## Проверка работоспособности

### 1. Проверить статус ВМ

```bash
vagrant status
```

### 2. Проверить репликацию

```bash
# На мастере — проверить подключённые реплики
vagrant ssh master -c "sudo -u postgres psql -c 'SELECT pid, usename, application_name, client_addr, state, sync_state FROM pg_stat_replication;'"

# Проверить слоты репликации
vagrant ssh master -c "sudo -u postgres psql -c 'SELECT slot_name, slot_type, active FROM pg_replication_slots;'"
```

### 3. Проверить синхронизацию данных

```bash
# Добавить запись на мастере
vagrant ssh master -c "sudo -u postgres psql -d testdb -c \"INSERT INTO test_table(name) VALUES('replication_test');\""

# Проверить что запись появилась на реплике
vagrant ssh replica -c "sudo -u postgres psql -d testdb -c 'SELECT * FROM test_table;'"
```

### 4. Проверить barman

```bash
# Статус barman
vagrant ssh barman -c "sudo -u barman barman check master"

# Создать резервную копию
vagrant ssh barman -c "sudo -u barman barman backup master"

# Список резервных копий
vagrant ssh barman -c "sudo -u barman barman list-backup master"

# Проверить crontab
vagrant ssh barman -c "sudo -u barman crontab -l"
```

## Пользователи БД

| Пользователь | Пароль         | Роль                    | Назначение         |
|-------------|----------------|-------------------------|--------------------|
| postgres    | (peer auth)    | SUPERUSER               | Системный          |
| replicator  | ReplicaPass123 | REPLICATION, LOGIN      | Репликация         |
| barman      | BarmanPass123  | SUPERUSER, LOGIN        | Резервное копирование |
