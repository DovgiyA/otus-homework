# otus-homework
Работа с LVM
Ubuntu 20.04.6 LTS (GNU/Linux 5.4.0-186-generic x86_64)

user@epd7qmkpg2ndngefrl4m:~$ lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
├─vda1 252:1    0   1M  0 part 
└─vda2 252:2    0  30G  0 part /
vdb    252:16   0  30G  0 disk 

user@epd7qmkpg2ndngefrl4m:~$ sudo pvcreate /dev/vdb
  Physical volume "/dev/vdb" successfully created.

user@epd7qmkpg2ndngefrl4m:~$ sudo vgcreate test /dev/vdb
  Volume group "test" successfully created

user@epd7qmkpg2ndngefrl4m:~$ sudo lvcreate -l+50%FREE -n l01 test
  Logical volume "l01" created.

  vda    252:0    0  30G  0 disk user@epd7qmkpg2ndngefrl4m:~$ sudo lvdisplay /dev/test/l01
  --- Logical volume ---
  LV Path                /dev/test/l01
  LV Name                l01
  VG Name                test
  LV UUID                5DxqW5-NRRN-U1pP-6j0I-LtxB-p3KK-wPfhVO
  LV Write Access        read/write
  LV Creation host, time epd7qmkpg2ndngefrl4m, 2025-05-17 13:27:25 +0000
  LV Status              available
  # open                 0
  LV Size                <15.00 GiB
  Current LE             3839
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto

  
  - currently set to     256
  Block device           253:0

user@epd7qmkpg2ndngefrl4m:~$ sudo mkfs.ext4 /dev/test/l01
mke2fs 1.45.5 (07-Jan-2020)
Creating filesystem with 3931136 4k blocks and 983040 inodes
Filesystem UUID: 7b5fef86-ea0b-4d2e-8f91-78206800c861
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632, 2654208

Allocating group tables: done

user@epd7qmkpg2ndngefrl4m:~$ sudo mount /dev/test/l01 /mnt
user@epd7qmkpg2ndngefrl4m:~$ df -Th
Filesystem           Type      Size  Used Avail Use% Mounted on
udev                 devtmpfs  1.9G     0  1.9G   0% /dev
tmpfs                tmpfs     392M  796K  392M   1% /run
/dev/vda2            ext4       30G  2.6G   26G  10% /
tmpfs                tmpfs     2.0G     0  2.0G   0% /dev/shm
tmpfs                tmpfs     5.0M     0  5.0M   0% /run/lock
tmpfs                tmpfs     2.0G     0  2.0G   0% /sys/fs/cgroup
tmpfs                tmpfs     392M     0  392M   0% /run/user/1000
/dev/mapper/test-l01 ext4       15G   24K   14G   1% /mnt

user@epd7qmkpg2ndngefrl4m:~$ sudo umount /dev/test/l01

user@epd7qmkpg2ndngefrl4m:~$ sudo lvextend -l+50%FREE /dev/test/l01
  Size of logical volume test/l01 changed from <15.00 GiB (3839 extents) to <22.50 GiB (5759 extents).
  Logical volume test/l01 successfully resized.

user@epd7qmkpg2ndngefrl4m:~$ sudo lvs /dev/test/l01
  LV   VG   Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  l01  test -wi-a----- <22.50g  

user@epd7qmkpg2ndngefrl4m:~$ sudo mount /dev/test/l01 /mnt

user@epd7qmkpg2ndngefrl4m:~$ sudo resize2fs /dev/test/l01
resize2fs 1.45.5 (07-Jan-2020)
Filesystem at /dev/test/l01 is mounted on /mnt; on-line resizing required
old_desc_blocks = 2, new_desc_blocks = 3
The filesystem on /dev/test/l01 is now 5897216 (4k) blocks long.

user@epd7qmkpg2ndngefrl4m:~$ df -Th
Filesystem           Type      Size  Used Avail Use% Mounted on
udev                 devtmpfs  1.9G     0  1.9G   0% /dev
tmpfs                tmpfs     392M  796K  392M   1% /run
/dev/vda2            ext4       30G  2.6G   26G  10% /
tmpfs                tmpfs     2.0G     0  2.0G   0% /dev/shm
tmpfs                tmpfs     5.0M     0  5.0M   0% /run/lock
tmpfs                tmpfs     2.0G     0  2.0G   0% /sys/fs/cgroup
tmpfs                tmpfs     392M     0  392M   0% /run/user/1000
/dev/mapper/test-l01 ext4       23G   24K   21G   1% /mnt

user@epd7qmkpg2ndngefrl4m:~$ sudo nano /etc/fstab

UUID=be2c7c06-cc2b-4d4b-96c6-e3700932b129 /               ext4    errors=remount-ro 0       1
UUID=7b5fef86-ea0b-4d2e-8f91-78206800c861 /mnt     ext4 errors=remount-ro 0       1



  
