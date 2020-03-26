#!/bin/sh

echo "$# parameters"

if [ "$#" -ne 5 ]; then
    echo "$0 host_name /dev/sd? swap_size ubuntu_version arch"
    echo "Ubuntu version:"
    echo "12.04 precise"
    echo "13.04 raring"
    echo "14.04 trusty"
    echo "16.04 xenial"
    exit
fi

START_TIME=$(date +%s)

echo 0 $0
echo 1 $1
echo 2 $2
echo 3 $3
echo 4 $4
echo 5 $5

HOST_NAME=$1
DISK=$2
SWAP_SIZE=$3
UBUNTU_VERSION=$4
ARCH=$5

echo HOST_NAME=${HOST_NAME}
# DISK=/dev/vda
echo DISK=${DISK}
echo SWAP_SIZE=${SWAP_SIZE}
echo UBUNTU_VERSION=${UBUNTU_VERSION}
echo ARCH=${ARCH}


sudo fdisk -l ${DISK}
TOTAL_SIZE=`sudo sfdisk -s $DISK`
TOTAL_SIZE=`expr ${TOTAL_SIZE} / 1024`
ROOTFS_SIZE=`expr ${TOTAL_SIZE} - ${SWAP_SIZE}`
cat << __EOF
TOTAL_SIZE:  ${TOTAL_SIZE}MB
ROOTFS_SIZE: ${ROOTFS_SIZE}MB
SWAP_SIZE:   ${SWAP_SIZE}MB
__EOF


# Clear partition
sudo dd if=/dev/zero of=${DISK} bs=512 count=2

sudo fdisk ${DISK} << __EOF
p
n



+${ROOTFS_SIZE}M
p
n




p
t
2
82
p
wq
__EOF

sudo fdisk -l ${DISK} && date +%Y%m%d%H%M%S


echo !!!!!! umount /mnt/installer
sudo umount /mnt/installer/proc
sudo umount /mnt/installer/sys
sudo umount /mnt/installer/dev/pts
sudo umount /mnt/installer/dev
sudo umount /mnt/installer
sudo mkfs.ext4 ${DISK}1
sudo mkdir /mnt/installer
sudo mount ${DISK}1 /mnt/installer
echo !!!!!! df /mnt/installer
df /mnt/installer
sudo swapoff ${DISK}2
sudo mkswap ${DISK}2
sudo apt-get install -y debootstrap




#PACKAGE_URL=http://mirror01.idc.hinet.net/ubuntu
#PACKAGE_URL=http://free.nchc.org.tw/ubuntu
# https://blog.elleryq.idv.tw/2018/11/apt-mirror.html
# http://mirrors.ubuntu.com/mirrors.txt
ACKAGE_URL=http://ftp.yzu.edu.tw/ubuntu

cat << __EOF
PACKAGE_URL:    ${PACKAGE_URL}
UBUNTU_VERSION: ${UBUNTU_VERSION}
__EOF
mount


sudo debootstrap --arch=${ARCH} ${UBUNTU_VERSION} /mnt/installer ${PACKAGE_URL}

sudo mount --bind /dev /mnt/installer/dev
sudo mount --bind /dev/pts /mnt/installer/dev/pts
sudo mount -t proc proc /mnt/installer/proc
sudo mount -t sysfs sys /mnt/installer/sys
echo HERE01
sudo cp install-04.sh /mnt/installer
sudo chroot /mnt/installer ./install-04.sh $HOST_NAME $UBUNTU_VERSION $DISK


sudo rm /mnt/installer/install-04.sh
sudo umount /mnt/installer/proc
sudo umount /mnt/installer/sys
sudo umount /mnt/installer/dev/pts
sudo umount /mnt/installer/dev
sudo umount /mnt/installer


END_TIME=$(date +%s)
echo $START_TIME
echo $END_TIME
echo HERE11
DIFF=$(echo "$END_TIME - $START_TIME" | bc)
echo HERE12
HH=$(echo "$DIFF / 3600" | bc)
MM=$(echo "$DIFF - ($HH * 3600)" | bc)
MM=$(echo "$MM / 60" | bc)
SS=$(echo "$DIFF % 60" | bc)
echo diff=$DIFF
echo $HH:$MM:$SS

echo HOST_NAME=$HOST_NAME
echo DISK=$DISK
echo SWAP_SIZE=$SWAP_SIZE
echo UBUNTU_VERSION=$UBUNTU_VERSION
echo ARCH=$ARCH

echo Done
