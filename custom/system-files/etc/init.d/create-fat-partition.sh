#!/bin/sh
### BEGIN INIT INFO
# Provides:          create-fat-partition
# Required-Start:
# Required-Stop:
# Default-Start: 3
# Default-Stop:
# Short-Description: Creates the user fat partition
# Description:
### END INIT INFO

set +e

case "$1" in
    start)
        echo "Resizing FAT partition..."
        # Determine the partition to resize
	DEVICE="/dev/mmcblk0"
	NEW_PARTITION_NUM="3"
	NEW_PARTITION="${DEVICE}p${NEW_PARTITION_NUM}"  # Assuming the third partition is the one to resize
	MOUNT_POINT="/media/sd"

	# Resize the partition
	echo "Resizing the partition using fdisk..."
	echo "Creating a new FAT partition using fdisk..."
	(
	echo n       # Add a new partition
	echo p       # Primary partition
	echo $NEW_PARTITION_NUM  # Specify the partition number
	echo 8869888 # Default - start at beginning of free space
	echo         # Default - extend partition to end of disk
	echo t       # Change partition type
	echo $NEW_PARTITION_NUM  # Specify the partition number
	echo c       # Set type to W95 FAT32 (LBA)
	echo w       # Write changes
	) | fdisk $DEVICE

	# Resize filesystem
	mkfs.vfat -F 32 -n "replay" $NEW_PARTITION

	# Add new partition to fstab
	echo "/dev/mmcblk0p3        /media/sd       vfat    rw,sync,dirsync,noatime,nodiratime,fmask=0022,dmask=0022,iocharset=utf8,errors=remount-ro   0   0" | tee -a /etc/fstab
	
	# Remove this script to prevent from executing it again and enable frontend
	update-rc.d create-fat-partition.sh remove &&
	rm /etc/init.d/create-fat-partition.sh
	update-rc.d replay.sh defaults
	
	# Reboot the system
	echo "Rebooting system to apply partition changes..."
	reboot
        ;;
    stop)
        # No-op
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac

exit 0
