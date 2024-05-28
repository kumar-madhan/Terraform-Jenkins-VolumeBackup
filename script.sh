#!/bin/bash

# Update the package index
sudo yum update -y

# Install necessary packages
sudo yum install -y lvm2

# List of device names for bin, dom, and log volumes
BIN_DEVICE="/dev/sdf"
DOM_DEVICE="/dev/sdg"
LOG_DEVICE="/dev/sdh"

# List of mount points
BIN_MOUNT="/mnt/bin"
DOM_MOUNT="/mnt/dom"
LOG_MOUNT="/mnt/log"

# Create mount points
sudo mkdir -p ${BIN_MOUNT}
sudo mkdir -p ${DOM_MOUNT}
sudo mkdir -p ${LOG_MOUNT}

# Function to format and mount a volume
format_and_mount() {
    local device=$1
    local mount_point=$2

    # Check if the device is already formatted
    if ! file -s ${device} | grep -q 'filesystem'; then
        # If not formatted, format the device
        sudo mkfs -t ext4 ${device}
    fi

    # Mount the device
    sudo mount ${device} ${mount_point}

    # Add to /etc/fstab to mount at boot
    echo "${device} ${mount_point} ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
}

# Format and mount each volume
format_and_mount ${BIN_DEVICE} ${BIN_MOUNT}
format_and_mount ${DOM_DEVICE} ${DOM_MOUNT}
format_and_mount ${LOG_DEVICE} ${LOG_MOUNT}

# Ensure the mounts are applied
sudo mount -a

# Verify the mounts
df -h
