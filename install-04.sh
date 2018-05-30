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
export DEBIAN_FRONTEND=noninteractive



echo 'LANG="en_US.UTF-8"' >  /etc/default/locale
locale-gen en_US.UTF-8

rm /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Taipei /etc/localtime
echo 'Asia/Taipei' > /etc/timezone
dpkg-reconfigure -f non-interactive tzdata

echo HERE03


if [ $UBUNTU_VERSION = "precise" ] ; then
    PACKAGE_URL=http://archive.ubuntu.com/ubuntu
    SECURITY_PACKAGE_URL=http://security.ubuntu.com/ubuntu
else
    PACKAGE_URL=http://mirror01.idc.hinet.net/ubuntu
    SECURITY_PACKAGE_URL=http://mirror01.idc.hinet.net/ubuntu
fi
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

if [ $UBUNTU_VERSION = "xenial" ] ; then
    NETWORK_INTERFACE=ens3
else
    NETWORK_INTERFACE=eth0
fi
cat > /etc/network/interfaces << __EOF
# interfaces(5) file used by ifup(8) and ifdown(8)
auto lo
iface lo inet loopback

auto ${NETWORK_INTERFACE}
iface ${NETWORK_INTERFACE} inet dhcp
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
grub-pc	grub-pc/install_devices_disks_changed	multiselect    ${DISK}
grub-pc	grub-pc/kopt_extracted	boolean	false
grub-pc	grub-pc/mixed_legacy_and_grub2	boolean	true
grub-pc	grub-pc/chainload_from_menu.lst	boolean	true
grub-pc	grub-pc/hidden_timeout	boolean	true
grub-pc	grub-pc/install_devices	multiselect	${DISK}
grub-pc	grub2/device_map_regenerated	note
grub-pc	grub-pc/install_devices_failed_upgrade	boolean	true
grub-pc	grub-pc/install_devices_failed	boolean	false
grub-pc	grub2/kfreebsd_cmdline	string" | debconf-set-selections

#echo "!!!!!! HERE01"
#apt-get -y install grub-pc
#echo "!!!!!! HERE02"
#grub-install ${DISK}
#echo "!!!!!! HERE03"
#update-gurb
#echo "!!!!!! HERE04"


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

# Extra packages
apt-get install -y openssh-server vim

echo ------------------------------------------------------------------
echo blkid
blkid
UUID_SDx1=`blkid | grep ${DISK}1 | awk '{print $2}' | cut -c7- | cut -c-36`
UUID_SDx2=`blkid | grep ${DISK}2 | awk '{print $2}' | cut -c7- | cut -c-36`
echo UUID_SDx1=${UUID_SDx1}
echo UUID_SDx2=${UUID_SDx2}
echo ------------------------------------------------------------------
echo Before
cat /etc/fstab
echo ------------------------------------------------------------------
echo "proc            /proc           proc    nodev,noexec,nosuid 0       0" >> /etc/fstab
echo "UUID=${UUID_SDx1} /               ext4    errors=remount-ro 0       1" >> /etc/fstab
echo "UUID=${UUID_SDx2} none            swap    sw              0       0" >> /etc/fstab
echo After
cat /etc/fstab
echo ------------------------------------------------------------------

echo | adduser --quiet --disabled-password mike
echo "mike:aaaaaa" | chpasswd

HOME_DIR=/home/mike
ls -la ${HOME_DIR}
mkdir -p ${HOME_DIR}/.ssh
echo ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOdfDL2rt6w7rwfT5NF8yYS/4fH9TEXGJIXpeuzDaRdKpNdQw9xwfhrTdH4UQdyu6roQfi0k9L/HWvoH93sIOjcXBf2+nKokqEQxQDVcJJ2eNVR2KsVddCseqkoOtiTK7of7fRI8vO0ZAIzrKu49Qw/jMIvujHKkx6rBSvrWxNqMuPkKrOzHrkM/EA+6kAPgcYtMOdc0DFytOFjIiLksMkthGGTcB0hr/Sfa9CxMIBP54M9jZtV4BqDuvFHrAbG23to8CDZB16MEJrKY47fdvjw2iQ5kAIgvmPYCsHb2YHjRpKEGkT77B/LOcVy5kCWFzW7Ox5ct15PQyF3X8uiCpd mike@box43 > ${HOME_DIR}/.ssh/authorized_keys
echo ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAid5v0ud2Y5xJgwziGnETGc7b7dh55dmnMf+uFuLx0gREJTtIwoiUhgMffRhR5/3FEquoASQnY1yBHxQHnRF7FaD1xA+pJlUnx9KJNol+PdPIrnWHTS6pjuDe+0HUt85KU3lt6EikLRIjUbQnCFmIN4aHnYmsi2VUIpenJLMzSK6jMpbqHRTkY3nSS3D1QNyweyY3FkuDYGCNKuqcYvNRFGV140Zd3F7+zPi/Exl5rSf+iYM3ksrCm6DhtHDGOEYBba2XfxC067S97IhivbdGzSX2SCskWC4ee9ONgAcdiVA45bJB1k9nJRbg3MOo9FEX/auI0hEEw4hxjTxawMIakw== >> ${HOME_DIR}/.ssh/authorized_keys

chmod go-w ${HOME_DIR}
chmod 700 ${HOME_DIR}/.ssh
chmod 600 ${HOME_DIR}/.ssh/authorized_keys
chown -R mike.mike ${HOME_DIR}/.ssh

echo StrictHostKeyChecking no >> /etc/ssh/ssh_config

gpasswd -a mike sudo
echo mike ALL=\(ALL\) NOPASSWD: ALL >> /etc/sudoers

df
apt-get clean && apt-get autoclean && apt-get -y autoremove
date +%Y%m%d%H%M%S
df


echo Leave $0
