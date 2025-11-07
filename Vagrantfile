Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024  # Устанавливаем память 1024 МБ

    vb.customize ["createhd", "--filename", "disk1.vdi", "--size", 1024]
    vb.customize ["createhd", "--filename", "disk2.vdi", "--size", 1024]

    vb.customize ["storageattach", :id, "--storagectl", "SATA Controller", "--port", 1, "--device", 0, "--type", "hdd", "--medium", "disk1.vdi"]
    vb.customize ["storageattach", :id, "--storagectl", "SATA Controller", "--port", 2, "--device", 0, "--type", "hdd", "--medium", "disk2.vdi"]
  end

  config.vm.network "forwarded_port", guest: 80, host: 8080

  config.vm.provision "shell", inline: <<-SHELL
    disk1=/dev/sdb
    disk2=/dev/sdc

    sudo mkfs.ext4 $disk1
    sudo mkfs.ext4 $disk2

    sudo mkdir -p /mnt/disk1
    sudo mkdir -p /mnt/disk2

    sudo mount $disk1 /mnt/disk1
    sudo mount $disk2 /mnt/disk2

    echo "$disk1 /mnt/disk1 ext4 defaults 0 0" | sudo tee -a /etc/fstab
    echo "$disk2 /mnt/disk2 ext4 defaults 0 0" | sudo tee -a /etc/fstab
  SHELL
end
