#!/bin/sh

echo "$# parameters"

if [ "$#" -ne 3 ]; then
    echo "$0 host_name ubuntu_version disk_name"
    exit
fi

echo 0 $0
echo 1 $1
echo 2 $2
echo 3 $3
HOST_NAME=$1
UBUNTU_VERSION=$2
# DISK=/dev/vda
DISK=$3

echo HERE02
#export DEBIAN_FRONTEND=noninteractive



cp /usr/share/zoneinfo/Asia/Taipei /etc/localtime
echo 'LANG="en_US.UTF-8"' >  /etc/default/locale
echo 'Asia/Taipei' > /etc/timezone
locale-gen en_US.UTF-8
dpkg-reconfigure -f non-interactive tzdata
echo HERE03


PACKAGE_URL=http://mirror01.idc.hinet.net/ubuntu
SECURITY_PACKAGE_URL=http://mirror01.idc.hinet.net/ubuntu
#PACKAGE_URL=http://free.nchc.org.tw/ubuntu
#SECURITY_PACKAGE_URL=http://free.nchc.org.tw/ubuntu

cat << __EOF
UBUNTU_VERSION:       ${UBUNTU_VERSION}
PACKAGE_URL:          ${PACKAGE_URL}
SECURITY_PACKAGE_URL: ${SECURITY_PACKAGE_URL}
__EOF

cat > /etc/apt/sources.list << __EOF
deb ${PACKAGE_URL} ${UBUNTU_VERSION} main multiverse restricted universe
deb-src ${PACKAGE_URL} ${UBUNTU_VERSION} main multiverse restricted universe
deb ${PACKAGE_URL} ${UBUNTU_VERSION}-updates main multiverse restricted universe
deb-src ${PACKAGE_URL} ${UBUNTU_VERSION}-updates main multiverse restricted universe
deb ${PACKAGE_URL} ${UBUNTU_VERSION}-backports main multiverse restricted universe
deb-src ${PACKAGE_URL} ${UBUNTU_VERSION}-backports main multiverse restricted universe
deb ${SECURITY_PACKAGE_URL} ${UBUNTU_VERSION}-security main multiverse restricted universe
deb-src ${SECURITY_PACKAGE_URL} ${UBUNTU_VERSION}-security main multiverse restricted universe
__EOF

cat /etc/apt/sources.list


cat > /etc/mtab << __EOF
${DISK}1 / ext4 rw,errors=remount-ro 0 0
proc /proc proc rw,noexec,nosuid,nodev 0 0
none /sys sysfs rw,noexec,nosuid,nodev 0 0
none /sys/fs/fuse/connections fusectl rw 0 0
none /sys/kernel/debug debugfs rw 0 0
none /sys/kernel/security securityfs rw 0 0
none /dev devtmpfs rw,mode=0755 0 0
none /dev/pts devpts rw,noexec,nosuid,gid=5,mode=0620 0 0
none /dev/shm tmpfs rw,nosuid,nodev 0 0
none /var/run tmpfs rw,nosuid,mode=0755 0 0
none /var/lock tmpfs rw,noexec,nosuid,nodev 0 0
none /lib/init/rw tmpfs rw,nosuid,mode=0755 0 0
__EOF

cat > /etc/network/interfaces << __EOF
# interfaces(5) file used by ifup(8) and ifdown(8)
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
__EOF

cat >> /etc/hosts << __EOF
127.0.1.1       ${HOST_NAME}.localdomain ${HOST_NAME}
__EOF

cat > /etc/hostname << __EOF
${HOST_NAME}
__EOF


echo ------------------------------------------------------------------
echo /etc/apt/sources.list
cat /etc/apt/sources.list
echo ------------------------------------------------------------------
echo /etc/network/interfaces
cat /etc/network/interfaces
echo ------------------------------------------------------------------
echo /etc/hosts
cat /etc/hosts
echo ------------------------------------------------------------------
echo /etc/hostname
cat /etc/hostname


# Below by
# apt-get install debconf-utils
# debconf-get-selections | grep grub-pc
echo "grub-pc	grub-pc/install_devices_empty	boolean	false
grub-pc	grub2/kfreebsd_cmdline_default	string	quiet splash
grub-pc	grub2/linux_cmdline_default	string
grub-pc	grub-pc/postrm_purge_boot_grub	boolean	false
grub-pc	grub2/linux_cmdline	string
grub-pc	grub-pc/timeout	string	10
grub-pc	grub-pc/install_devices_disks_changed	multiselect
grub-pc	grub-pc/kopt_extracted	boolean	false
grub-pc	grub-pc/mixed_legacy_and_grub2	boolean	true
grub-pc	grub-pc/chainload_from_menu.lst	boolean	true
grub-pc	grub-pc/hidden_timeout	boolean	true
grub-pc	grub-pc/install_devices	multiselect	${DISK}
grub-pc	grub2/device_map_regenerated	note
grub-pc	grub-pc/install_devices_failed_upgrade	boolean	true
grub-pc	grub-pc/install_devices_failed	boolean	false
grub-pc	grub2/kfreebsd_cmdline	string" | debconf-set-selections


apt-get update && apt-get -y dist-upgrade
# Install Linux firmware for wifi and etc
apt-get install -y linux-firmware
if [ $UBUNTU_VERSION = "precise" ] || [ $UBUNTU_VERSION = "raring" ] ; then
    apt-get install -y linux-image
elif [ $UBUNTU_VERSION = "xenial" ] ; then
    # Bug in kernel 4.13 HWE for change display resolution https://goo.gl/5RCPMP
    LATEST_KERNEL_IMAGE=linux-image-generic-lts-xenial
    LATEST_KERNEL_IMAGE_EXTRA=linux-image-extra-virtual-lts-xenial
    echo LATEST_KERNEL_IMAGE=$LATEST_KERNEL_IMAGE
    echo LATEST_KERNEL_IMAGE_EXTRA=$LATEST_KERNEL_IMAGE_EXTRA
    apt-get install -y $LATEST_KERNEL_IMAGE $LATEST_KERNEL_IMAGE_EXTRA
    # Can't shutdown without dbus
    # Failed to connect to bus: No such file or directory
    apt-get install -y dbus
else
    LATEST_KERNEL_IMAGES=`apt-cache search linux-image | grep linux-image-3 | grep generic | sort -V | awk '{print $1}'`
    LATEST_KERNEL_IMAGE=`apt-cache search linux-image | grep linux-image-3 | grep generic | sort -V | awk '{print $1}' | tail -n1`
    LATEST_KERNEL_IMAGE_EXTRA=`apt-cache search linux-image-extra | grep linux-image-extra-3 | grep generic | sort -V | awk '{print $1}' | tail -n1`
    echo LATEST_KERNEL_IMAGES=$LATEST_KERNEL_IMAGES
    echo LATEST_KERNEL_IMAGE=$LATEST_KERNEL_IMAGE
    echo LATEST_KERNEL_IMAGE_EXTRA=$LATEST_KERNEL_IMAGE_EXTRA
    apt-get install -y $LATEST_KERNEL_IMAGE $LATEST_KERNEL_IMAGE_EXTRA
fi

#grub-install --help
#grub-install /dev/sda


blkid
UUID_SDA1=`blkid | grep ${DISK}1 | awk '{print $2}' | cut -c7- | cut -c-36`
UUID_SDA2=`blkid | grep ${DISK}2 | awk '{print $2}' | cut -c7- | cut -c-36`
echo UUID_SDA1=${UUID_SDA1}
echo UUID_SDA2=${UUID_SDA2}
cat /etc/fstab
echo "proc            /proc           proc    nodev,noexec,nosuid 0       0" >> /etc/fstab
echo "UUID=${UUID_SDA1} /               ext4    errors=remount-ro 0       1" >> /etc/fstab
echo "UUID=${UUID_SDA2} none            swap    sw              0       0" >> /etc/fstab
cat /etc/fstab

echo | adduser --quiet --disabled-password mike
echo "mike:aaaaaa" | chpasswd

gpasswd -a mike sudo

df
apt-get clean && apt-get autoclean && apt-get autoremove
date +%Y%m%d%H%M%S
df


echo Leave $0
