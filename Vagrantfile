Vagrant.configure("2") do |config|
  # Используем ARM-совместимый образ Ubuntu для M1
  config.vm.box = "spox/ubuntu-arm"
  config.vm.box_version = "1.0.0"

  # Добавляем два виртуальных диска по 1 ГБ каждый
  config.vm.disk :disk, size: "1GB", name: "disk1.vmdk"
  config.vm.disk :disk, size: "1GB", name: "disk2.vmdk"

  # Проброс порта с гостевой 80 на хостовую 8080
  config.vm.network "forwarded_port", guest: 80, host: 8080, auto_correct: true

  # Конфигурация VMware Desktop
  config.vm.provider :vmware_desktop do |vmware|
    vmware.gui = true            # запуск с GUI VMware
    vmware.cpus = 2
    vmware.memory = 1024         # 2 ГБ оперативной памяти
  end

  # Провижининг скрипт для форматирования и монтирования дисков
  config.vm.provision "shell", inline: <<-SHELL
    # имена дисков (по умолчанию vmware под Linux видит их как /dev/sdb, /dev/sdc и т.д.)
    DISK1="/dev/sdb"
    DISK2="/dev/sdc"
    # Создаем файловую систему ext4
    mkfs.ext4 -F $DISK1
    mkfs.ext4 -F $DISK2

    # Создаем точки монтирования
    mkdir -p /mnt/disk1
    mkdir -p /mnt/disk2

    # Монтируем диски
    mount $DISK1 /mnt/disk1
    mount $DISK2 /mnt/disk2

    # Добавляем в /etc/fstab для автоматического монтирования при загрузке
    echo "$DISK1 /mnt/disk1 ext4 defaults 0 2" >> /etc/fstab
    echo "$DISK2 /mnt/disk2 ext4 defaults 0 2" >> /etc/fstab
  SHELL
end
