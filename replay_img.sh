#!/bin/bash

# Check if image file is provided as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <image_file>"
    exit 1
fi

IMAGE_FILE="$1"
MOUNT_DIR="/mnt/wipe"  # Dedicated mount directory

# Step 1: Mount the image file to a loop device
LOOP_DEVICE=$(sudo losetup -f --show "$IMAGE_FILE")
if [ $? -ne 0 ]; then
    echo "Failed to mount the image file."
    exit 1
fi
echo "Mounted $IMAGE_FILE to $LOOP_DEVICE"

# Step 2: Wipe free space in the filesystem
echo "Preparing to wipe free space..."

# Ensure partitions are detected (critical for some kernels)
sudo partprobe "$LOOP_DEVICE"

# Mount the first partition (adjust p1 to pN if needed)
PARTITION="${LOOP_DEVICE}p2"
sudo mkdir -p "$MOUNT_DIR"
sudo mount "$PARTITION" "$MOUNT_DIR"
if [ $? -ne 0 ]; then
    echo "Failed to mount partition $PARTITION for wiping."
    sudo losetup -d "$LOOP_DEVICE"
    exit 1
fi

# Overwrite free space with zeros
echo "Wiping free space in $PARTITION..."
sudo dd if=/dev/zero of="$MOUNT_DIR/zero_filler" bs=1M status=progress 2>/dev/null
sudo sync  # Force write to disk
sudo rm -f "$MOUNT_DIR/zero_filler"

# Unmount partition
sudo umount "$MOUNT_DIR"
if [ $? -ne 0 ]; then
    echo "Failed to unmount $MOUNT_DIR. WARNING: Potential filesystem corruption!"
    sudo losetup -d "$LOOP_DEVICE"
    exit 1
fi

# Step 3: Get the last partition's end sector
END_SECTOR=$(sudo parted -m "$LOOP_DEVICE" unit s print | awk -F: '/^[0-9]+:/ {last=$3} END {gsub("s", "", last); print last}')
if [ -z "$END_SECTOR" ]; then
    echo "Failed to determine the end sector of the last partition."
    sudo losetup -d "$LOOP_DEVICE"
    exit 1
fi
echo "Last partition ends at sector $END_SECTOR"

# Step 4: Unmount the loop device
sudo losetup -d "$LOOP_DEVICE"
if [ $? -ne 0 ]; then
    echo "Failed to unmount the loop device."
    exit 1
fi
echo "Unmounted $LOOP_DEVICE"

# Step 5: Truncate the image file to the correct size based on end sector
TRUNCATE_SIZE=$(( (END_SECTOR + 1) * 512 ))
truncate --size="$TRUNCATE_SIZE" "$IMAGE_FILE"
if [ $? -ne 0 ]; then
    echo "Failed to truncate the image file."
    exit 1
fi
echo "Truncated $IMAGE_FILE to $TRUNCATE_SIZE bytes (aligned to 512 bytes)"

# Step 6: Compress the image file
xz -k "$IMAGE_FILE"
if [ $? -ne 0 ]; then
    echo "Failed to compress the image file."
    exit 1
fi
echo "Compressed $IMAGE_FILE to ${IMAGE_FILE}.xz"

echo "Process completed successfully."
