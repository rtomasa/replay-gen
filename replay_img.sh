#!/bin/bash

# Check if image file is provided as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <image_file>"
    exit 1
fi

IMAGE_FILE="$1"

# Step 1: Mount the image file to a loop device
LOOP_DEVICE=$(sudo losetup -f --show "$IMAGE_FILE")
if [ $? -ne 0 ]; then
    echo "Failed to mount the image file."
    exit 1
fi
echo "Mounted $IMAGE_FILE to $LOOP_DEVICE"

# Step 2: Examine the partitions to find the last partition size
LAST_PARTITION_SIZE=$(sudo parted "$LOOP_DEVICE" print | awk '/^ [0-9]+/{size=$3} END{gsub("MB", "", size); print size}')
if [ -z "$LAST_PARTITION_SIZE" ]; then
    echo "Failed to determine the size of the last partition."
    sudo losetup -d "$LOOP_DEVICE"
    exit 1
fi
echo "Last partition ends at ${LAST_PARTITION_SIZE}MB"

# Step 3: Unmount the loop device
sudo losetup -d "$LOOP_DEVICE"
if [ $? -ne 0 ]; then
    echo "Failed to unmount the loop device."
    exit 1
fi
echo "Unmounted $LOOP_DEVICE"

# Step 4: Truncate the image file
truncate --size="${LAST_PARTITION_SIZE}MB" "$IMAGE_FILE"
if [ $? -ne 0 ]; then
    echo "Failed to truncate the image file."
    exit 1
fi
echo "Truncated $IMAGE_FILE to ${LAST_PARTITION_SIZE}MB"

# Step 5: Compress the image file
xz -k "$IMAGE_FILE"
if [ $? -ne 0 ]; then
    echo "Failed to compress the image file."
    exit 1
fi
echo "Compressed $IMAGE_FILE to ${IMAGE_FILE}.xz"

echo "Process completed successfully."

