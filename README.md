# otus-homework

Ubuntu 20.04.6 LTS (GNU/Linux 5.4.0-186-generic x86_64)

user@epdvnkmmlmqc73svshg5:~$ lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
vda    252:0    0  30G  0 disk 
├─vda1 252:1    0   1M  0 part 
└─vda2 252:2    0  30G  0 part /
vdb    252:16   0  30G  0 disk 
user@epdvnkmmlmqc73svshg5:~$ sudo fdisk /dev/vdb

Welcome to fdisk (util-linux 2.34).
Changes will remain in memory only, until you decide to write them.
Be careful before using the write command.

Device does not contain a recognized partition table.
Created a new DOS disklabel with disk identifier 0x3ba016ed.

Command (m for help): n
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): p
Partition number (1-4, default 1): 1
First sector (2048-62914559, default 2048): 
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-62914559, default 62914559): +1G

Created a new partition 1 of type 'Linux' and of size 1 GiB.

Command (m for help): n
Partition type
   p   primary (1 primary, 0 extended, 3 free)
   e   extended (container for logical partitions)
Select (default p): p
Partition number (2-4, default 2): 2
First sector (2099200-62914559, default 2099200): 
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2099200-62914559, default 62914559): +1G

Created a new partition 2 of type 'Linux' and of size 1 GiB.

Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.

user@epdvnkmmlmqc73svshg5:~$ lsblk
NAME   MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
vda    252:0    0  30G  0 disk 
├─vda1 252:1    0   1M  0 part 
└─vda2 252:2    0  30G  0 part /
vdb    252:16   0  30G  0 disk 
├─vdb1 252:17   0   1G  0 part 
└─vdb2 252:18   0   1G  0 part 

user@epdvnkmmlmqc73svshg5:~$ sudo mdadm --create --verbose /dev/md0 -l 1 -n 2 /dev/vdb{1,2}
mdadm: Note: this array has metadata at the start and
    may not be suitable as a boot device.  If you plan to
    store '/boot' on this device please ensure that
    your boot-loader understands md/v1.x metadata, or use
    --metadata=0.90
mdadm: size set to 1046528K
Continue creating array? 
Continue creating array? (y/n) y
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
user@epdvnkmmlmqc73svshg5:~$ lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
vda     252:0    0   30G  0 disk  
├─vda1  252:1    0    1M  0 part  
└─vda2  252:2    0   30G  0 part  /
vdb     252:16   0   30G  0 disk  
├─vdb1  252:17   0    1G  0 part  
│ └─md0   9:0    0 1022M  0 raid1 
└─vdb2  252:18   0    1G  0 part  
  └─md0   9:0    0 1022M  0 raid1 
user@epdvnkmmlmqc73svshg5:~$ sudo cat /proc/mdstat
Personalities : [raid1] 
md0 : active raid1 vdb2[1] vdb1[0]
      1046528 blocks super 1.2 [2/2] [UU]
      [====>................]  resync = 20.6% (216576/1046528) finish=1.7min speed=7734K/sec
      
unused devices: <none>

user@epdvnkmmlmqc73svshg5:~$ sudo mdadm /dev/md0 --fail /dev/vdb2
mdadm: set /dev/vdb2 faulty in /dev/md0
user@epdvnkmmlmqc73svshg5:~$ sudo mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Fri May  9 12:12:09 2025
        Raid Level : raid1
        Array Size : 1046528 (1022.00 MiB 1071.64 MB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent

       Update Time : Fri May  9 12:18:39 2025
             State : clean, degraded 
    Active Devices : 1
   Working Devices : 1
    Failed Devices : 1
     Spare Devices : 0

Consistency Policy : resync

              Name : epdvnkmmlmqc73svshg5:0  (local to host epdvnkmmlmqc73svshg5)
              UUID : af730f71:a1513edb:c4b11149:8b7c5545
            Events : 19

    Number   Major   Minor   RaidDevice State
       0     252       17        0      active sync   /dev/vdb1
       -       0        0        1      removed

       1     252       18        -      faulty   /dev/vdb2
user@epdvnkmmlmqc73svshg5:~$ sudo mdadm /dev/md0 --remove /dev/vdb2
mdadm: hot removed /dev/vdb2 from /dev/md0
user@epdvnkmmlmqc73svshg5:~$ sudo mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Fri May  9 12:12:09 2025
        Raid Level : raid1
        Array Size : 1046528 (1022.00 MiB 1071.64 MB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 2
     Total Devices : 1
       Persistence : Superblock is persistent

       Update Time : Fri May  9 12:19:18 2025
             State : clean, degraded 
    Active Devices : 1
   Working Devices : 1
    Failed Devices : 0
     Spare Devices : 0

Consistency Policy : resync

              Name : epdvnkmmlmqc73svshg5:0  (local to host epdvnkmmlmqc73svshg5)
              UUID : af730f71:a1513edb:c4b11149:8b7c5545
            Events : 20

    Number   Major   Minor   RaidDevice State
       0     252       17        0      active sync   /dev/vdb1
       -       0        0        1      removed
user@epdvnkmmlmqc73svshg5:~$ sudo mdadm /dev/md0 --add /dev/vdb2
mdadm: added /dev/vdb2
user@epdvnkmmlmqc73svshg5:~$ sudo mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Fri May  9 12:12:09 2025
        Raid Level : raid1
        Array Size : 1046528 (1022.00 MiB 1071.64 MB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent

       Update Time : Fri May  9 12:20:11 2025
             State : clean, degraded, recovering 
    Active Devices : 1
   Working Devices : 2
    Failed Devices : 0
     Spare Devices : 1

Consistency Policy : resync

    Rebuild Status : 3% complete

              Name : epdvnkmmlmqc73svshg5:0  (local to host epdvnkmmlmqc73svshg5)
              UUID : af730f71:a1513edb:c4b11149:8b7c5545
            Events : 22

    Number   Major   Minor   RaidDevice State
       0     252       17        0      active sync   /dev/vdb1
       2     252       18        1      spare rebuilding   /dev/vdb2

user@epdvnkmmlmqc73svshg5:~$ sudo parted -s /dev/md0 mklabel gpt

user@epdvnkmmlmqc73svshg5:~$ sudo parted /dev/md0 mkpart primary ext4 0% 20%
Information: You may need to update /etc/fstab.

user@epdvnkmmlmqc73svshg5:~$ sudo parted /dev/md0 mkpart primary ext4 20% 40%
Information: You may need to update /etc/fstab.

user@epdvnkmmlmqc73svshg5:~$ sudo parted /dev/md0 mkpart primary ext4 40% 60%
Information: You may need to update /etc/fstab.

user@epdvnkmmlmqc73svshg5:~$ sudo parted /dev/md0 mkpart primary ext4 60% 80%
Information: You may need to update /etc/fstab.

user@epdvnkmmlmqc73svshg5:~$ sudo parted /dev/md0 mkpart primary ext4 80% 100%
Information: You may need to update /etc/fstab.

user@epdvnkmmlmqc73svshg5:~$  for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
mke2fs 1.45.5 (07-Jan-2020)
Creating filesystem with 51968 4k blocks and 51968 inodes
Filesystem UUID: 7a9986e6-c61f-47d0-82e1-f55c9cfafe3d
Superblock backups stored on blocks: 
	32768

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.45.5 (07-Jan-2020)
Creating filesystem with 52480 4k blocks and 52480 inodes
Filesystem UUID: ea23e3da-0360-4163-9223-c029d6effc8b
Superblock backups stored on blocks: 
	32768

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.45.5 (07-Jan-2020)
Creating filesystem with 52224 4k blocks and 52224 inodes
Filesystem UUID: 60ff5575-b7b6-4bfc-bb06-0bc9b6aeb2fa
Superblock backups stored on blocks: 
	32768

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.45.5 (07-Jan-2020)
Creating filesystem with 52480 4k blocks and 52480 inodes
Filesystem UUID: 01d49df3-fc67-4df3-b683-7be76525f6d2
Superblock backups stored on blocks: 
	32768

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.45.5 (07-Jan-2020)
Creating filesystem with 51968 4k blocks and 51968 inodes
Filesystem UUID: 88f6e058-4fd3-4dbc-8ccc-26fb5f8d130b
Superblock backups stored on blocks: 
	32768

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

user@epdvnkmmlmqc73svshg5:~$ for i in $(seq 1 5); do sudo mount /dev/md0p$i /raid/part$i; done

user@epdvnkmmlmqc73svshg5:~$ lsblk
NAME        MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINT
vda         252:0    0   30G  0 disk  
├─vda1      252:1    0    1M  0 part  
└─vda2      252:2    0   30G  0 part  /
vdb         252:16   0   30G  0 disk  
├─vdb1      252:17   0    1G  0 part  
│ └─md0       9:0    0 1022M  0 raid1 
│   ├─md0p1 259:1    0  203M  0 part  /raid/part1
│   ├─md0p2 259:4    0  205M  0 part  /raid/part2
│   ├─md0p3 259:5    0  204M  0 part  /raid/part3
│   ├─md0p4 259:8    0  205M  0 part  /raid/part4
│   └─md0p5 259:9    0  203M  0 part  /raid/part5
└─vdb2      252:18   0    1G  0 part  
  └─md0       9:0    0 1022M  0 raid1 
    ├─md0p1 259:1    0  203M  0 part  /raid/part1
    ├─md0p2 259:4    0  205M  0 part  /raid/part2
    ├─md0p3 259:5    0  204M  0 part  /raid/part3
    ├─md0p4 259:8    0  205M  0 part  /raid/part4
    └─md0p5 259:9    0  203M  0 part  /raid/part5
