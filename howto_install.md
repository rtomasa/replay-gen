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
`systemctl disable apparmor`
`apt-get remove --purge apparmor`
`rm -rf /etc/apparmor.d/`

8. Remove rsync
`apt-get remove --purge rsyn`

9. Remove sudo
`apt-get remove --purge sudo`

10. Remove triggerhappy
`systemctl disable triggerhappy`
`apt-get remove --purge triggerhappy`

11. Remove raspi-config
`update-rc.d raspi-config remove`
`apt-get remove --purge raspi-config`

12. Disable NetworkManager-wait-online
`systemctl disable NetworkManager-wait-online.service`
`systemctl mask NetworkManager-wait-online.service`

13. Disable e2scrub_reap.service
`systemctl disable e2scrub_reap.service`
`systemctl mask e2scrub_reap.service`
`systemctl disable e2scrub_all.timer`
`systemctl mask e2scrub_all.timer`

14. Remove udisks2.service
`systemctl disable udisks2.service`
`apt-get remove --purge udisks2`

15. Remove getty
`systemctl disable getty@tty1.service`

16. Remove ModemManager
`systemctl disable ModemManager`

17. Enable dhcpcd
`systemctl enable dhcpcd`

18. Disable rpi-eeprom-update
`systemctl disable rpi-eeprom-update`

19. Remove avahi-daemon
`systemctl disable avahi-daemon`

20. Remove networking
`systemctl disable networking`

21. Enable wpa_supplicant@wlan0
`systemctl enable wpa_supplicant@wlan0`

22. Create mount points
`mkdir /media/sd`
`mkdir /media/usb`
`mkdir /media/nfs`

23. Build and install GunGon2 driver
24. Build and install Tatito T&P driver

25. Install create-fat-partition service
`cp create-fat-partition.sh /etc/init.d/create-fat-partition.sh`
`update-rc.d create-fat-partition.sh defaults`

26. Copy replay service
`cp replay.service /etc/systemd/system/replay.service`

27. Copy replay folder to /opt

28. Clear history
`history -c`
`cat /dev/null > ~/.bash_history && history -c && poweroff`

DEVELOP AND CREATE NEW SYSTEM IMAGE
===================================

``` sh

# Remove development libraries
apt purge gdb build-essential alsa-utils joystick \
libgles-dev libegl-dev libdrm-dev libgbm-dev \
libsdl2-dev libsdl2-image-dev libsdl2-gfx-dev \
libavcodec-dev libavformat-dev libswscale-dev libavutil-dev \
libsamplerate0-dev libinput-dev libass-dev \
libcurl4-openssl-dev libblkid-dev libcjson-dev libgpiod-dev \
zlib1g-dev libbsd-dev

# Install runtime libraries
apt install --no-install-recommends \
libgles2 libegl1 libdrm2 libgbm1 \
libsdl2-2.0-0 libsdl2-image-2.0-0 libsdl2-gfx-1.0-0 \
libavcodec59 libavformat59 libswscale6 libavutil57 \
libsamplerate0 libinput10 libass9 \
libcurl4 libblkid1 libcjson1 libgpiod2 \
zlib1g libbsd0

# Put logs in RAM
echo "deb [signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian/ bookworm main" | sudo tee /etc/apt/sources.list.d/azlux.list
wget -O /usr/share/keyrings/azlux-archive-keyring.gpg  https://azlux.fr/repo.gpg
apt update
apt install log2ram

# Disable the swapfile	
dphys-swapfile swapoff
systemctl disable dphys-swapfile
rm /var/swap
apt install zram-tools

# Change locale
sudo nano /etc/locale.gen
Uncomment # en_US.UTF-8 UTF-8
sudo locale-gen
sudo update-locale LANG=en_US.UTF-8


```

# Development phase
1. Write latest image into SD
2. Prevent partition script to run renaming `/etc/init.d/create-fat-partition.sh` directly in the SD before first boot
3. Boot the system and perform a system update (not upgrade)
4. Copy config.txt and cmdline.txt if required
5. Make any required package installation
6. Make Kernel upgrade if required (instructions down below)
    1. Check installed Kernels: `dpkg -l 'linux-image-*' | grep '^ii'`
    2. Remove old Kernels: `apt-get purge linux-image-$(uname -r)`
    4. Install TAITO Paddle & Trackball driver
    5. Install NAMCO GunCon 2 Lightgun driver
    6. Install GPIO Joystick driver
    7. Copy GPIO Joystick dtbo
7. Make release compilation of the frontend and clean all development files
8. Copy any other required or modified file like for example sdl controller db, etc.
9. Restore back the original partition script name `/etc/init.d/create-fat-partition.sh`
10. Create firstboot file `touch /opt/replay/firstboot`
11. Cleanup and shutdown:
    Check for installed packages and kernels: `dpkg --get-selections | awk '{print $1}' | sort > ~/pkgs_current.txt`
    Remove old kernels based on the above list: `apt purge <kernel_package>`
    Remove some packages: `apt remove sudo python3`
    ```sh
    rm -f /var/log/replay.log \
    && rm -rf /tmp/* /var/tmp/* /var/log/* \
    && apt-get -y autoremove \
    && apt-get clean \
    && apt-get autoclean \
    && rm -f ~/.bash_history* \
    && history -c \
    && poweroff
    ```
12. Create new image file from PC and remove unallocated space:

**NOTE**: the below image preparation steps are automated in replay_img.sh

## Mount the Image File
`sudo losetup -f --show replay_0410.img`
Output: /dev/loop39
## Examine the Partitions
`sudo parted /dev/loop39 print`
Output indicates the last partition ends at 4541MB
## Unmount the Loop Device
`sudo losetup -d /dev/loop39`
## Truncate the Image File
`truncate --size=4541MB replay_0410.img`
## Compress
`xz -k replay_0410.img`

## Kernel Update
### Update system
`apt update`
`apt upgrade`
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