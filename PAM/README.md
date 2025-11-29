Домашнее задание

PAM

Что нужно сделать?

Ограничить доступ к системе для всех пользователей, кроме группы администраторов, в выходные дни (суббота и воскресенье), за исключением праздничных дней.

alex@Lenovo:~$ ssh user@158.160.209.151
The authenticity of host '158.160.209.151 (158.160.209.151)' can't be established.
ED25519 key fingerprint is SHA256:Ymsid6ud/4nXCT5eYDAudTo3CR2DZnN34qtknkprsE8.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '158.160.209.151' (ED25519) to the list of known hosts.
user@158.160.209.151's password: 
Welcome to Ubuntu 24.04.2 LTS (GNU/Linux 6.8.0-60-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Sat Nov 29 10:40:09 UTC 2025

  System load:  0.08              Processes:             138
  Usage of /:   30.5% of 9.04GB   Users logged in:       0
  Memory usage: 9%                IPv4 address for eth0: 10.130.0.11
  Swap usage:   0%


Expanded Security Maintenance for Applications is not enabled.

user@fv4bdu5lcq4p9bdg84rk:~$ sudo groupadd -f admin
user@fv4bdu5lcq4p9bdg84rk:~$ sudo useradd otusadm
user@fv4bdu5lcq4p9bdg84rk:~$ sudo useradd otus
user@fv4bdu5lcq4p9bdg84rk:~$ sudo passwd otusadm
New password: 
Retype new password: 
passwd: password updated successfully
user@fv4bdu5lcq4p9bdg84rk:~$ sudo passwd otus
New password: 
Retype new password: 
passwd: password updated successfully
user@fv4bdu5lcq4p9bdg84rk:~$ sudo usermod -aG admin otusadm
user@fv4bdu5lcq4p9bdg84rk:~$ sudo usermod -aG admin root
user@fv4bdu5lcq4p9bdg84rk:~$ sudo nano /usr/local/bin/login.sh
user@fv4bdu5lcq4p9bdg84rk:~$ sudo chmod +x /usr/local/bin/login.sh
user@fv4bdu5lcq4p9bdg84rk:~$ sudo nano /etc/pam.d/sshd
user@fv4bdu5lcq4p9bdg84rk:~$ sudo systemctl restart ssh

alex@Lenovo:~$ ssh otus@158.160.209.151
otus@158.160.209.151's password: 
Permission denied, please try again.
otus@158.160.209.151's password: 

alex@Lenovo:~$ ssh otusadm@158.160.209.151
otusadm@158.160.209.151's password: 
Welcome to Ubuntu 24.04.2 LTS (GNU/Linux 6.8.0-60-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Sat Nov 29 10:47:10 UTC 2025

  System load:  0.0               Processes:             133
  Usage of /:   30.6% of 9.04GB   Users logged in:       1
  Memory usage: 10%               IPv4 address for eth0: 10.130.0.11
  Swap usage:   0%
