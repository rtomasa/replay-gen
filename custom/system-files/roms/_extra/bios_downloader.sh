#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <destination_directory>"
  exit 1
fi

# Variables
URL="https://os.rgb-pi.com/downloads/replay_extra/bios.tar"  # Replace with your URL
DEST_DIR=$1  # The destination directory is passed as an argument

# Create the destination directory if it doesn't exist
if [ ! -d "$DEST_DIR" ]; then
  mkdir -p $DEST_DIR
fi

# Download and extract the tar file
echo "Downloading and extracting $URL..."
if wget -qO- $URL | tar --no-same-owner -xvf - -C $DEST_DIR; then
  echo "Download completed"
else
  echo "Download failed"
  exit 1
fi

exit 0
