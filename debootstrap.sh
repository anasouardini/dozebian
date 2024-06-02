#!/bin/bash

set -e
cd $(dirname $0)

printGreen() {
	printf '\033[1;32m> %s\033[0m\n' "$@" >&2  # bold Green
}
printRed() {
	printf '\033[1;31m> %s\033[0m\n' "$@" >&2  # bold Red
}

mountPath="/media/usb"
mirror="http://ftp.es.debian.org/debian/"
distribution="testing"
arch="amd64"
partTableType='msdos'

printGreen "Pick a usb device:"
lsblk -dno name,size,type,mountpoint | awk '{print NR, ") ", $0}';

echo ""
read -p 'Device number: ' deviceNumber;

chosenDevice=$(lsblk -dno name,size,type,mountpoint | sed -n ${deviceNumber}p | awk '{print "/dev/" $1}')

echo ""
printGreen "Are you sure you want to format the device ${chosenDevice}? (y/N)"
read -p "[n] : " isContinue
if [[ ! $isContinue = "y" ]];then
  echo 'exitting...'
  exit 0
fi

# set -x
printGreen "Check if ${chosenDevice} is already mounted"
mountedDev=$(mount | grep $chosenDevice) || mountedDev=""
if [[ -n $mountedDev ]];then
  printGreen "${chosenDevice} is already mounted; unmounting..."
  sudo umount -R $(mount | grep $chosenDevice | awk '{print $3}')
fi

mkdir -p $mountPath

printGreen "Clearing partition table"
yes | sudo sgdisk --zap-all "$chosenDevice"

printGreen "Partitioning and formatting"
sudo parted "$chosenDevice" --script mklabel "$partTableType"
# sudo parted "$chosenDevice" --script mkpart primary fat32 1MB 100%
sudo parted "$chosenDevice" --script mkpart primary ext4 1MB 100%
sudo parted "$chosenDevice" --script set 1 boot on
# yes | sudo mkfs.fat -F32 "${chosenDevice}1"
yes | sudo mkfs.ext4 "${chosenDevice}1"

printGreen "Mounting ${chosenDevice}1 to ${mountPath}"
sudo mount "${chosenDevice}1" $mountPath

# Install debootstrap if it's not already installed
sudo which debootstrap > /dev/null
if [[ ! $? = 0 ]];then
    echo "debootstrap not found. Installing..."
    sudo apt-get update
    sudo apt-get install debootstrap
fi

printGreen "debootstraping..."
sudo debootstrap --arch="$arch" "$distribution" "$mountPath" "$mirror"

printGreen "Seting up bindings"
sudo mount --make-rslave --rbind /dev $mountPath/dev
sudo mount --make-rslave --rbind /proc $mountPath/proc
sudo mount --make-rslave --rbind /sys $mountPath/sys
sudo mount --make-rslave --rbind /run $mountPath/run

printRed "Changing rootfs to ${mountPath}"

printGreen "Adding proxy for faster downloads"
sudo chroot $mountPath /bin/bash -c "echo 'Acquire::http {Proxy \"http://192.168.1.115:3142\";}' > /etc/apt/apt.conf.d/proxy && apt update"
printGreen "Adding non-free and contrib repos"
sudo chroot $mountPath /bin/bash -c "echo 'deb http://ftp.es.debian.org/debian testing main contrib non-free' > /etc/apt/sources.list && apt update"

printGreen "Installing kernel and grub packages"
sudo chroot $mountPath /bin/bash -c "apt install -y --no-install-recommends linux-image-amd64 firmware-linux-free network-manager grub2"
printGreen "Installing grub"
sudo chroot $mountPath /bin/bash -c "grub-install --root-directory / ${chosenDevice}"

printGreen "Unounting ${chosenDevice}"
sudo mount  $mountPath/dev
sudo mount  $mountPath/proc
sudo mount  $mountPath/sys
sudo mount  $mountPath/run

printGreen "Booting ${chosenDevice} in Qemu"
sudo qemu-system-x86_64 -machine accel=kvm:tcg -m 512 -hda $chosenDevice
