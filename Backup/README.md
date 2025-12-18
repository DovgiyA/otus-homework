
1. Остановливаем бэкап

systemctl stop borg-backup.timer

2. Создаем тестовый файл

echo 'Verification Timestamp: $(date)' > /etc/backup_test_verification.txt

3. Запускаем ручной бэкап

/usr/local/bin/borg-backup.sh
Result: Backup id etc-2025-12-18_10:11:14 created.

4. Удаляем тестовый файл

rm /etc/backup_test_verification.txt

5. Восстанавливаем файл

mkdir -p /tmp/restore_test
cd /tmp/restore_test
borg extract ssh://borg@158.160.207.47/var/backup/repo::etc-2025-12-18_10:11:14 etc/backup_test_verification.txt

6. Проверяем файл

cat /tmp/restore_test/etc/backup_test_verification.txt
Output:

Verification Timestamp: Thu Dec 18 01:11:02 PM MSK 2025

