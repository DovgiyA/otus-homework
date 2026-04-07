# 🚀 LibreSpeed High Availability & Observability Stack
## Финальный проект курса DevOps (OTUS)

Этот проект представляет собой полностью автоматизированную инфраструктуру для сервиса измерения скорости [LibreSpeed](https://github.com/librespeed/speedtest). Инфраструктура развернута в Yandex Cloud с использованием Ansible и спроектирована с учетом отказоустойчивости (HA), масштабируемости и глубокой наблюдаемости (Observability).

---

## 🗺 Карта инфраструктуры

| Имя хоста | Роль | Внутренний IP | Публичный IP |
| :--- | :--- | :--- | :--- |
| **frontend** | Nginx Proxy, SSL, Балансировщик | 10.130.0.26 | 158.160.200.2 |
| **backend1** | PHP-FPM, LibreSpeed Endpoint, Adminer | 10.130.0.13 | - |
| **backend2** | PHP-FPM, LibreSpeed Endpoint, Adminer | 10.130.0.15 | - |
| **database** | PostgreSQL 16 (Primary) | 10.130.0.18 | - |
| **dbreplica** | PostgreSQL 16 (Standby) | 10.130.0.17 | - |
| **monitor**  | Prometheus, Grafana, ELK, Alertmanager | 10.130.0.21 | 158.160.248.236 |

---

## 🔗 Быстрый доступ (Dashboard URLs)

| Сервис | URL | Учетные данные |
| :--- | :--- | :--- |
| **Сайт (Speedtest)** | [https://xn----ctbkoedricefmgyd0k.xn--p1ai](https://xn----ctbkoedricefmgyd0k.xn--p1ai) | Публичный доступ |
| **Grafana** | [http://158.160.248.236:3000](http://158.160.248.236:3000) | `Alex` / `grafana` |
| **Kibana (Logs)** | [http://158.160.248.236:5601](http://158.160.248.236:5601) | Без пароля |
| **Prometheus** | [http://158.160.248.236:9090](http://158.160.248.236:9090) | `rebrainme` / `prometheus` |
| **Adminer (DB)** | [https://.../adminer/](https://xn----ctbkoedricefmgyd0k.xn--p1ai/adminer/) | PostgreSQL: `speedtest` / `SpeedTest@2026Secure` |

---

## 🛠 Экзаменационный сценарий: Проверка работоспособности

### 1. Веб-сервис и Балансировка (Nginx + PHP)
Убедиться, что запросы распределяются между бэкендами и сессия закрепляется (sticky sessions).
```bash
# Проверка доступности фронтенда
curl -kI https://xn----ctbkoedricefmgyd0k.xn--p1ai

# Проверка логов балансировки на фронтенде (JSON формат)
ansible frontend -m shell -a "tail -n 1 /var/log/nginx/speedtest_access.log"
```

### 2. Слой данных (PostgreSQL Replication)
Продемонстрировать работу Streaming Replication между Primary и Standby.
```bash
# На Primary (database): Проверка статуса репликации
ansible database -m shell -a "sudo -u postgres psql -c 'select * from pg_stat_replication;'"

# На Standby (dbreplica): Подтверждение режима Read-Only
ansible dbreplica -m shell -a "sudo -u postgres psql -c 'select pg_is_in_recovery();'"
```

### 3. Логирование (EFK Stack)
Показать, что логи со всех узлов собираются в Elasticsearch в структурированном виде.
```bash
# Проверка наличия индексов Fluentd (выполнять с монитора или фронтенда)
ansible monitor -m shell -a "curl -s http://localhost:9200/_cat/indices?v | grep fluentd"

# Проверка работы парсера (последняя запись в ES)
ansible monitor -m shell -a "curl -s http://localhost:9200/fluentd-*/_search?size=1 | jq"
```

### 4. Мониторинг и Алертинг (Prometheus + Alertmanager)
Продемонстрировать сбор метрик и работу уведомлений в Telegram.
```bash
# Проверка статуса таргетов в Prometheus
curl -u rebrainme:prometheus http://158.160.248.236:9090/api/v1/targets | jq '.data.activeTargets[].health'

# Симуляция падения сервиса (для алертинга в Telegram)
ansible backend2 -m shell -a "sudo systemctl stop nginx"
# Через 1-2 минуты в Telegram придет уведомление "NginxDown"
# После проверки вернуть в строй:
ansible backend2 -m shell -a "sudo systemctl start nginx"

# Ручная отправка тестового алерта через API
ansible monitor -m shell -a 'curl -XPOST -H "Content-Type: application/json" http://localhost:9093/api/v2/alerts -d "[{\"labels\":{\"alertname\":\"ExamTestAlert\",\"severity\":\"critical\",\"instance\":\"monitor\"},\"annotations\":{\"summary\":\"Экзаменационная проверка\",\"description\":\"Уведомление успешно доставлено.\"}}]"'
```

### 5. Безопасность (Firewall)
```bash
# Проверка статуса UFW на любом сервере
ansible all -m shell -a "sudo ufw status"
```

---

## 📈 Метрики и Дашборды
В Grafana настроены следующие дашборды:
1.  **Node Exporter Full:** Общее состояние железа всех 6 серверов.
2.  **PostgreSQL Overview:** Мониторинг транзакций и состояния репликации.
3.  **Logs Analytics:** (через Kibana) Визуализация 4xx/5xx ошибок и географии запросов.

---

## 📂 Структура репозитория
*   `ansible/roles/` — модульная конфигурация каждого компонента.
*   `ansible/inventory/` — настройки окружения.
*   `ansible/playbooks/site.yml` — мастер-плейбук для полного деплоя.
