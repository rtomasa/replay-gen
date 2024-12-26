RePlay OS
=========

Configuration steps after first boot
====================================

1. Poweroff and resize the ext4 root partition to 4GB from desktop PC

2. First time SSH login
    User     : replay
    Password : replayos

3. Enable Root User
`sudo passwd root`
Password : replayos

4. Configure SSH for Root Login and Default Path
`sudo nano /etc/ssh/sshd_config`
Change `#PermitRootLogin prohibit-password` to `PermitRootLogin yes`
Change `Subsystem       sftp    /usr/lib/openssh/sftp-server` to `Subsystem       sftp    /usr/lib/openssh/sftp-server -d /media`
`sudo reboot` and use root for next logins

5. Remove User (replay)
`deluser --remove-home replay`

6. Clean Boot
Remove journal boot messages: `nano /etc/systemd/journald.conf` set `Storage=none`
Remove boot messages: `rm /etc/systemd/system/getty@tty1.service.d/noclear.conf`
Remove welcome message: `touch ~/.hushlogin`
Remove linux version info: `echo "" > /etc/issue`
Remove the message of the day: `echo "" > /etc/motd`
Remove Kernel messages: `nano /etc/rc.local` comment out the IP print and add this before `exit 0`: `dmesg --console-off`
Update cmdline.txt: `video=HDMI-A-1:1280x720@60D video=HDMI-A-2:1280x720@60D console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 fsck.repair=no vt.global_cursor_default=0 quiet loglevel=0 systemd.show_status=false rd.udev.log_level=0 rootwait fastboot cfg80211.ieee80211_regdom=ES usbhid.quirks=0x0ae4:0x0701:0x0004 usbhid.jspoll=1 usbcore.autosuspend=-1" > /boot/firmware/cmdline.txt`
`reboot`

7. Remove AppArmor
`systemctl stop apparmor`
`systemctl disable apparmor`
`apt-get remove --purge apparmor`
`rm -rf /etc/apparmor.d/`

8. Remove rsync
`apt-get remove --purge rsyn`

9. Remove sudo
`apt-get remove --purge sudo`

10. Remove triggerhappy
`systemctl stop triggerhappy`
`systemctl disable triggerhappy`
`apt-get remove --purge triggerhappy`

11. Remove raspi-config
`service raspi-config stop`
`update-rc.d raspi-config remove`
`apt-get remove --purge raspi-config`

12. Disable NetworkManager-wait-online
`systemctl stop NetworkManager-wait-online.service`
`systemctl disable NetworkManager-wait-online.service`
`systemctl mask NetworkManager-wait-online.service`

13. Disable e2scrub_reap.service
`systemctl stop e2scrub_reap.service`
`systemctl disable e2scrub_reap.service`
`systemctl mask e2scrub_reap.service`
`systemctl stop e2scrub_all.timer`
`systemctl disable e2scrub_all.timer`
`systemctl mask e2scrub_all.timer`

14. Remove udisks2.service
`systemctl stop udisks2.service`
`systemctl disable udisks2.service`
`apt-get remove --purge udisks2`

15. Remove getty
`systemctl stop getty@tty1.service`
`systemctl disable getty@tty1.service`

16. Create mount points
`mkdir /media/sd`
`mkdir /media/usb`
`mkdir /media/nfs`

17. Build and install GunGon2 driver
18. Build and install Tatito T&P driver

19. Install create-fat-partition service
`cp create-fat-partition.sh /etc/init.d/create-fat-partition.sh`
`update-rc.d create-fat-partition.sh defaults`

20. Copy replay service
`cp replay.sh /etc/init.d/replay.sh`

21. Copy replay folder to /opt

22. Clear history
`history -c`
`cat /dev/null > ~/.bash_history && history -c && poweroff`

DEVELOP AND CREATE NEW SYSTEM IMAGE
===================================

# Development phase
1. Write latest image into SD.
2. Prevent partition script to run renaming `/etc/init.d/create-fat-partition.sh` directly in the SD bebore first boot.
3. Boot the system and restore back the original partition script name `/etc/init.d/create-fat-partition.sh`.
4. Disable the partiton service while doing development `update-rc.d create-fat-partition.sh remove`.
5. Make any required change, development, installation, etc. as needed.
6. Enable the partiton `update-rc.d create-fat-partition.sh defaults`.
7. Create firstboot file `touch /opt/replay/firstboot`.
8. If kernel was updated you need replace manually. Example: `cp /boot/initrd.img-6.6.51+rpt-rpi-v8 /boot/firmware/initrd.img`.
9. Clean history and shutdown system `cat /dev/null > ~/.bash_history && history -c && poweroff`.
10. Create new image file from PC and remove unallocated space:

# New image creation phase
1. Make release compilation of the frontend and clean all development files.
2. Enable the partiton `update-rc.d create-fat-partition.sh defaults`.
3. Create firstboot file `touch /opt/replay/firstboot`.
4. Clean history and shutdown system `cat /dev/null > ~/.bash_history && history -c && poweroff`
5. Create new image file from PC and remove unallocated space:

## Mount the Image File
`sudo losetup -f --show replay_0410.img`
Output: /dev/loop39

## Examine the Partitions
`sudo parted /dev/loop39 print`
Output indicates the last partition ends at 4541MB.

## Unmount the Loop Device
`sudo losetup -d /dev/loop39`

## Truncate the Image File
`truncate --size=4541MB replay_0410.img`

## Compress
`xz -k replay_0410.img`

## Kernel Update
### Check Installed Kernel Versions
`dpkg --list | grep linux-image`
ii: Installed package.
rc: Package removed, but configuration files remain.
### Remove Old Kernels
`sudo apt remove linux-image-<version>`
### Clean Up Dependencies
`sudo apt autoremove --purge`
### Verify and Regenerate Initramfs
`sudo update-initramfs -u -k all`
### Manually Copy New Kernel
`cp /boot/vmlinuz-<version>-v8 /boot/firmware/kernel8.img`
`cp /boot/initrd.img-<version>-v8 /boot/firmware/initrd.img`
### Reboot

MISC COMMAND NOTES
==================
```
systemd-analyze
systemd-analyze critical-chain
systemd-analyze blame

update-rc.d create-fat-partition.sh defaults
update-rc.d create-fat-partition.sh remove
Check partition sectors: fdisk -l /dev/mmcblk0
```

ARCH LINUX SILENT BOOT
======================
[https://wiki.archlinux.org/title/Silent_boot]