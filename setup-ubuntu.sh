#!/usr/bin/env bash
# 12.04 precise
# 14.04 trusty
# 16.04 xenial
# 18.04 bionic
# 20.04 focal

function usage() {
    cat << __EOF
$0 DISK_NAME HOST_NAME UBUNTU_VERSION PACKAGE_URL USERNAME PASSWORD
Example:
    DISK_NAME:         /dev/vda
    HOST_NAME:         box549
    UBUNTU_VERSION:    focal
    PACKAGE_URL:       http://mirror01.idc.hinet.net/ubuntu
    USERNAME:          mike
    PASSWORD:          aaaaaa
    NETWORK_INTERFACE: ens3 or enp1s0
    IP:                172.16.6.40
__EOF
}

function export_variables() {
    export DEBIAN_FRONTEND=noninteractive
}

function setup_language() {
    echo 'LANG="en_US.UTF-8"' > /etc/default/locale
    locale-gen en_US.UTF-8
}

function setup_time() {
    rm /etc/localtime
    ln -s /usr/share/zoneinfo/Asia/Taipei /etc/localtime
    echo 'Asia/Taipei' > /etc/timezone
    dpkg-reconfigure -f non-interactive tzdata
}

function add_user() {
    echo | adduser --quiet --disabled-password $USERNAME
    echo "$USERNAME:$PASSWORD" | chpasswd
}

function sudo_user() {
    gpasswd -a $USERNAME sudo
    echo $USERNAME ALL=\(ALL\) NOPASSWD: ALL >> /etc/sudoers
}

function setup_apt_sources() {
    if [ $UBUNTU_VERSION = "precise" ] ; then
        PACKAGE_URL="http://archive.ubuntu.com/ubuntu"
        SECURITY_PACKAGE_URL="http://security.ubuntu.com/ubuntu"
    else
        SECURITY_PACKAGE_URL=$PACKAGE_URL
    fi

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

    print_file /etc/apt/sources.list

    apt-get update
    apt-get -y dist-upgrade
}

function install_kernel() {
    local LATEST_KERNEL_IMAGES
    local LATEST_KERNEL_IMAGE
    local LATEST_KERNEL_IMAGE_EXTRA

    #################
    # precise 12.04 #
    #################
    if [ $UBUNTU_VERSION = "precise" ] ; then
        # below copy from install-04.sh
        LATEST_KERNEL_IMAGES=`apt-cache search linux-image | grep linux-image-3 | grep generic | sort -V | awk '{print $1}'`
        LATEST_KERNEL_IMAGE=`apt-cache search linux-image | grep linux-image-3 | grep generic | sort -V | awk '{print $1}' | tail -n1`
        LATEST_KERNEL_IMAGE_EXTRA=`apt-cache search linux-image-extra | grep linux-image-extra-3 | grep generic | sort -V | awk '{print $1}' | tail -n1`
        echo "grub-pc	grub-pc/install_devices_empty	boolean	false
grub-pc	grub2/kfreebsd_cmdline_default	string	quiet splash
grub-pc	grub2/linux_cmdline_default	string
grub-pc	grub-pc/postrm_purge_boot_grub	boolean	false
grub-pc	grub2/linux_cmdline	string
grub-pc	grub-pc/timeout	string	0
grub-pc	grub-pc/install_devices_disks_changed	multiselect    $DISK_NAME
grub-pc	grub-pc/kopt_extracted	boolean	false
grub-pc	grub-pc/mixed_legacy_and_grub2	boolean	true
grub-pc	grub-pc/chainload_from_menu.lst	boolean	true
grub-pc	grub-pc/hidden_timeout	boolean	true
grub-pc	grub-pc/install_devices	multiselect	$DISK_NAME
grub-pc	grub2/device_map_regenerated	note
grub-pc	grub-pc/install_devices_failed_upgrade	boolean	true
grub-pc	grub-pc/install_devices_failed	boolean	false
grub-pc	grub2/kfreebsd_cmdline	string" | debconf-set-selections
    ################
    # trusty 14.04 #
    ################
    elif [ $UBUNTU_VERSION = "trusty" ] ; then
        # below copy from install-04.sh
        LATEST_KERNEL_IMAGES=`apt-cache search linux-image | grep linux-image-3 | grep generic | sort -V | awk '{print $1}'`
        LATEST_KERNEL_IMAGE=`apt-cache search linux-image | grep linux-image-3 | grep generic | sort -V | awk '{print $1}' | tail -n1`
        LATEST_KERNEL_IMAGE_EXTRA=`apt-cache search linux-image-extra | grep linux-image-extra-3 | grep generic | sort -V | awk '{print $1}' | tail -n1`
        echo "grub-pc	grub-pc/install_devices_empty	boolean	false
grub-pc	grub2/kfreebsd_cmdline_default	string	quiet splash
grub-pc	grub2/linux_cmdline_default	string
grub-pc	grub-pc/postrm_purge_boot_grub	boolean	false
grub-pc	grub2/linux_cmdline	string
grub-pc	grub-pc/timeout	string	0
grub-pc	grub-pc/install_devices_disks_changed	multiselect    $DISK_NAME
grub-pc	grub-pc/kopt_extracted	boolean	false
grub-pc	grub-pc/mixed_legacy_and_grub2	boolean	true
grub-pc	grub-pc/chainload_from_menu.lst	boolean	true
grub-pc	grub-pc/hidden_timeout	boolean	true
grub-pc	grub-pc/install_devices	multiselect	$DISK_NAME
grub-pc	grub2/device_map_regenerated	note
grub-pc	grub-pc/install_devices_failed_upgrade	boolean	true
grub-pc	grub-pc/install_devices_failed	boolean	false
grub-pc	grub2/kfreebsd_cmdline	string" | debconf-set-selections
    ################
    # xenial 16.04 #
    ################
    elif [ $UBUNTU_VERSION = "xenial" ] ; then
        # Bug in kernel 4.13 HWE for change display resolution https://goo.gl/5RCPMP
        LATEST_KERNEL_IMAGE=linux-image-generic-lts-xenial
        LATEST_KERNEL_IMAGE_EXTRA=linux-image-extra-virtual-lts-xenial
        # Can't shutdown without dbus
        # Failed to connect to bus: No such file or directory
        apt-get install -y dbus
        # Below dump from box43 by below
        # sudo apt-get install debconf-utils
        # sudo debconf-get-selections | grep grub-pc
        echo "grub-pc grub-pc/mixed_legacy_and_grub2  boolean true
grub-pc grub-pc/kopt_extracted  boolean false
grub-pc grub2/kfreebsd_cmdline  string
grub-pc grub2/linux_cmdline_default     string
grub-pc grub-pc/timeout string 0
grub-pc grub-pc/install_devices_disks_changed   multiselect
grub-pc grub-pc/postrm_purge_boot_grub  boolean false
grub-pc grub2/update_nvram      boolean true
grub-pc grub2/force_efi_extra_removable boolean false
grub-pc grub2/linux_cmdline     string
grub-pc grub-pc/install_devices_failed_upgrade  boolean true
grub-pc grub-pc/install_devices multiselect     $DISK_NAME
grub-pc grub2/device_map_regenerated    note
grub-pc grub-pc/chainload_from_menu.lst boolean true
grub-pc grub-pc/install_devices_failed  boolean false
grub-pc grub-pc/hidden_timeout  boolean false
grub-pc grub-pc/install_devices_empty   boolean false
grub-pc grub2/kfreebsd_cmdline_default  string  quiet splash" | debconf-set-selections
    ################
    # bionic 18.04 #
    ################
    elif [ $UBUNTU_VERSION = "bionic" ] ; then
        LATEST_KERNEL_IMAGES=`apt-cache search linux-image | grep linux-image-4 | grep generic | sort -V | awk '{print $1}'`
        LATEST_KERNEL_IMAGE=`apt-cache search linux-image | grep linux-image-4 | grep generic | sort -V | awk '{print $1}' | tail -n1`
        LATEST_KERNEL_IMAGE_EXTRA=`apt-cache search linux-modules-extra | grep linux-modules-extra-4 | grep generic | sort -V | awk '{print $1}' | tail -n1`
        # Below dump from box571 by below
        # sudo apt-get install debconf-utils
        # sudo debconf-get-selections | grep grub-pc
        # below only one space is allow between string and 0
        # otherwise will become GRUB_TIMEOUT=" 0"
        echo "grub-pc grub-pc/timeout string 0
grub-pc grub2/kfreebsd_cmdline_default  string  quiet splash
grub-pc grub-pc/kopt_extracted  boolean false
grub-pc grub2/no_efi_extra_removable    boolean false
grub-pc grub-pc/install_devices_failed  boolean false
grub-pc grub-pc/chainload_from_menu.lst boolean true
grub-pc grub-pc/install_devices multiselect     $DISK_NAME
grub-pc grub2/linux_cmdline     string
grub-pc grub-pc/hidden_timeout  boolean true
grub-pc grub2/kfreebsd_cmdline  string
grub-pc grub-pc/mixed_legacy_and_grub2  boolean true
grub-pc grub-pc/postrm_purge_boot_grub  boolean false
grub-pc grub2/linux_cmdline_default     string
grub-pc grub2/device_map_regenerated    note
grub-pc grub-pc/install_devices_failed_upgrade  boolean true
grub-pc grub2/unsigned_kernels  note
grub-pc grub-pc/install_devices_empty   boolean false
grub-pc grub2/update_nvram      boolean true
grub-pc grub-pc/install_devices_disks_changed   multiselect        $DISK_NAME"  | debconf-set-selections
    ###############
    # focal 20.04 #
    # jammy 22.04 #
    ###############
    elif [ $UBUNTU_VERSION = "focal" ] || [ $UBUNTU_VERSION = "jammy" ] ; then
        LATEST_KERNEL_IMAGES=`apt-cache search linux-image | grep linux-image-5 | grep generic | sort -V | awk '{print $1}'`
        LATEST_KERNEL_IMAGE=`apt-cache search linux-image | grep linux-image-5 | grep generic | sort -V | awk '{print $1}' | tail -n1`
        LATEST_KERNEL_IMAGE_EXTRA=`apt-cache search linux-modules-extra | grep linux-modules-extra-5 | grep generic | sort -V | awk '{print $1}' | tail -n1`
        # Below dump from box110 by below
        # sudo apt-get install debconf-utils
        # sudo debconf-get-selections | grep grub-pc
        echo "grub-pc grub2/unsigned_kernels  note
grub-pc grub2/linux_cmdline     string
grub-pc grub-pc/timeout string 0
grub-pc grub-efi/install_devices        multiselect
grub-pc grub-efi/install_devices_disks_changed  multiselect
grub-pc grub-pc/postrm_purge_boot_grub  boolean false
grub-pc grub2/kfreebsd_cmdline  string
grub-pc grub2/linux_cmdline_default     string
grub-pc grub-pc/install_devices_empty   boolean false
grub-pc grub2/kfreebsd_cmdline_default  string  quiet splash
grub-pc grub2/update_nvram      boolean true
grub-pc grub-pc/hidden_timeout  boolean true
grub-pc grub2/device_map_regenerated    note
grub-pc grub2/no_efi_extra_removable    boolean false
grub-pc grub-pc/install_devices_disks_changed   multiselect        $DISK_NAME
grub-pc grub-efi/install_devices_empty  boolean false
grub-pc grub-pc/install_devices multiselect     $DISK_NAME
grub-pc grub-pc/chainload_from_menu.lst boolean true
grub-pc grub-pc/install_devices_failed  boolean false
grub-pc grub-efi/install_devices_failed boolean false
grub-pc grub-pc/install_devices_failed_upgrade  boolean true
grub-pc grub-pc/mixed_legacy_and_grub2  boolean true
grub-pc grub-pc/kopt_extracted  boolean false" | debconf-set-selections
    else
        echo "install_kernel() not support $UBUNTU_VERSION yet."
        return
    fi

    echo LATEST_KERNEL_IMAGES=$LATEST_KERNEL_IMAGES
    echo LATEST_KERNEL_IMAGE=$LATEST_KERNEL_IMAGE
    echo LATEST_KERNEL_IMAGE_EXTRA=$LATEST_KERNEL_IMAGE_EXTRA

    apt-get -y install $LATEST_KERNEL_IMAGE \
                       $LATEST_KERNEL_IMAGE_EXTRA  \
                       linux-firmware

    grub-install --boot-directory=/boot $DISK_NAME
}

function install_openssh() {
    apt-get -y install openssh-server

    HOME_DIR=/home/$USERNAME
    ls -la ${HOME_DIR}

    mkdir -p ${HOME_DIR}/.ssh

    echo ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOdfDL2rt6w7rwfT5NF8yYS/4fH9TEXGJIXpeuzDaRdKpNdQw9xwfhrTdH4UQdyu6roQfi0k9L/HWvoH93sIOjcXBf2+nKokqEQxQDVcJJ2eNVR2KsVddCseqkoOtiTK7of7fRI8vO0ZAIzrKu49Qw/jMIvujHKkx6rBSvrWxNqMuPkKrOzHrkM/EA+6kAPgcYtMOdc0DFytOFjIiLksMkthGGTcB0hr/Sfa9CxMIBP54M9jZtV4BqDuvFHrAbG23to8CDZB16MEJrKY47fdvjw2iQ5kAIgvmPYCsHb2YHjRpKEGkT77B/LOcVy5kCWFzW7Ox5ct15PQyF3X8uiCpd  > ${HOME_DIR}/.ssh/authorized_keys
    echo ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAid5v0ud2Y5xJgwziGnETGc7b7dh55dmnMf+uFuLx0gREJTtIwoiUhgMffRhR5/3FEquoASQnY1yBHxQHnRF7FaD1xA+pJlUnx9KJNol+PdPIrnWHTS6pjuDe+0HUt85KU3lt6EikLRIjUbQnCFmIN4aHnYmsi2VUIpenJLMzSK6jMpbqHRTkY3nSS3D1QNyweyY3FkuDYGCNKuqcYvNRFGV140Zd3F7+zPi/Exl5rSf+iYM3ksrCm6DhtHDGOEYBba2XfxC067S97IhivbdGzSX2SCskWC4ee9ONgAcdiVA45bJB1k9nJRbg3MOo9FEX/auI0hEEw4hxjTxawMIakw== >> ${HOME_DIR}/.ssh/authorized_keys
    echo ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+Fv10NIVr0NTfieYWk/Dbi01eBCb340VSCsrSWaUstXqOSuw4dTfnmkrIAlWDzSw3MeSlAdorrIoGcA0FpDfjhd9E7MDxJwaHZ0J8t8/sKLXxYQRroCK+jj57/rU85ghJkUACvultTgrofHjKcTIcwFVtQnEeBJ5570w4Q/1riHOyJKACKRZP/jq2eBdMnQWVub/5fcVHOvdr9+POrxhmXmxmLIEgNvs/DvjPX+cr6mlQJla788G9er8iz/5+gmRWK5wqsMpsRsWeShg+0lr3s4Nw3Rb4ltDT/wE/Spcb8xca/CwTnNqubIDHErhsCZJk0tvpAUkwGley6rMuckgH >> ${HOME_DIR}/.ssh/authorized_keys
    echo ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDObRDtR0Tw+iSL3pIVNR01meTSSyOt5qIJ+qs7Mug38jF0RptdcDUoDxbUuA7hQzf1d9MdqjlVbtnLwa7ODvjpwP0cuN5hlWWw4Vhz+DyefRdMLSGJQj9S4x+GkKSfD3ZOUbNnVpVbGPr1ia0Z7JsjnNm2vgOzJKYxUI6hYfYcR+/BGseRb62nJlgM4K3Swz1LXQUhngaM3m9oZQRr8TnqvXy5I43fKwAtKYDkBRZUC4JPJ/GzD66yukigSxxOtptt7Crh70Bfi8aX5E3B5mkgcLbrvrHP05mP7ltL4wQORYprtGgQOcHvLa1MJfO2tF0k0BDEopo6tl2RAK6Q6uokBiIwqVlAdSEpNM04Irtwu1qqJhOyRvbyFRtueFLKVG3ZoBjJLITZ96gPEQV2dZLH0JaR5wfMLi06cWQKDS79iU3kbMjKhtQ5Omm7z93D1m/UeysM/86NGnPKjVW69VmNwrLB3gR+FNiA9GIp4xZRTag6JKF7uiQsVn9DLs2sLNs= >> ${HOME_DIR}/.ssh/authorized_keys

    chmod go-w ${HOME_DIR}
    chmod 700 ${HOME_DIR}/.ssh
    chmod 600 ${HOME_DIR}/.ssh/authorized_keys
    chown -R mike.mike ${HOME_DIR}/.ssh

    echo StrictHostKeyChecking no >> /etc/ssh/ssh_config
}

function install_extra_packages() {
    apt-get -y install vim tmux
}

function setup_network() {
    # setup network setting file
    local method
    if [ $UBUNTU_VERSION = "precise" ] ; then
        method="interfaces"
    elif [ $UBUNTU_VERSION = "trusty" ] ; then
        method="interfaces"
    elif [ $UBUNTU_VERSION = "xenial" ] ; then
        method="interfaces"
    elif [ $UBUNTU_VERSION = "bionic" ] ; then
        method="netplan"
    elif [ $UBUNTU_VERSION = "focal" ] ; then
        method="netplan"
    else
        echo "setup_network() not support $UBUNTU_VERSION yet."
        return
    fi

    if [ $method = "interfaces" ]; then
        cat > /etc/network/interfaces << __EOF
# interfaces(5) file used by ifup(8) and ifdown(8)
auto lo
iface lo inet loopback

auto ${NETWORK_INTERFACE}
iface ${NETWORK_INTERFACE} inet dhcp
__EOF
    elif [ $method = "netplan" ]; then
        cat > /etc/netplan/01-netcfg.yaml << __EOF
network:
  version: 2
  ethernets:
    ${NETWORK_INTERFACE}:
__EOF
        if [ -z "$IP" ]; then
            cat >> /etc/netplan/01-netcfg.yaml << __EOF
      dhcp4: true
__EOF
        else
            # todo: add gateway
            cat >> /etc/netplan/01-netcfg.yaml << __EOF
      dhcp4: no
      addresses: [${IP}/16]
      gateway4: 172.16.0.1
      nameservers:
        addresses: [172.16.0.1]
__EOF
        fi
        print_file /etc/netplan/01-netcfg.yaml
    fi

    cat >> /etc/hosts << __EOF
127.0.1.1       ${HOST_NAME}.localdomain ${HOST_NAME}
__EOF
    print_file /etc/hosts

    cat > /etc/hostname << __EOF
${HOST_NAME}
__EOF
    print_file /etc/hostname
}

function print_file() {
    echo ---=== Below is content of $1 ===---
    cat $1
}

function apt_clean() {
    apt-get clean
    apt-get autoclean
    apt-get -y autoremove
}

function apt_upgrade() {
    apt-get update
    apt-get dist-upgrade
}

function setup_grub() {
    print_file /etc/default/grub
    if [ $UBUNTU_VERSION = "bionic" ] ; then
        # default GRUB_TIMEOUT=" 10"
        sed -i 's/GRUB_TIMEOUT=\" 10\"/GRUB_TIMEOUT=0/' /etc/default/grub
    elif [ $UBUNTU_VERSION = "focal" ] ; then
        sed -i 's/GRUB_TIMEOUT=10/GRUB_TIMEOUT=0/' /etc/default/grub
    fi
    print_file /etc/default/grub
    update-grub
}

function setup_fstab() {
    blkid
    UUID_DISK1=`blkid | grep ${DISK_NAME}1 | awk '{print $2}' | cut -c7- | cut -c-36`
    echo "proc            /proc           proc    nodev,noexec,nosuid 0       0" >> /etc/fstab
    echo "UUID=${UUID_DISK1} /               ext4    errors=remount-ro 0       1" >> /etc/fstab
    echo "/swapfile       none            swap    sw              0       0"     >> /etc/fstab
    print_file /etc/fstab
}

# Init variables
DISK_NAME=""
HOST_NAME=""
UBUNTU_VERSION=""
PACKAGE_URL=""

# init_parameters
echo
echo "$# parameters"
echo argv[0]=$0
echo argv[1]=$1
echo argv[2]=$2
echo argv[3]=$3
echo argv[4]=$4
echo argv[5]=$5
echo argv[6]=$6
echo argv[7]=$7
echo argv[8]=$8

DISK_NAME=$1
HOST_NAME=$2
UBUNTU_VERSION=$3
PACKAGE_URL=$4
USERNAME=$5
PASSWORD=$6
NETWORK_INTERFACE=$7
IP=$8

echo DISK_NAME=$DISK_NAME
echo HOST_NAME=$HOST_NAME
echo UBUNTU_VERSION=$UBUNTU_VERSION
echo PACKAGE_URL=$PACKAGE_URL
echo USERNAME=$USERNAME
echo PASSWORD=$PASSWORD
echo NETWORK_INTERFACE=$NETWORK_INTERFACE
echo IP=$IP

if [ "$#" -lt 7 ]; then
    usage && exit
fi


export_variables
setup_language
setup_time
add_user
setup_apt_sources
setup_network
setup_fstab
install_openssh
install_extra_packages
install_kernel
setup_grub
apt_upgrade
apt_clean
sudo_user
