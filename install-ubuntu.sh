#!/usr/bin/env bash
# 12.04 precise
# 14.04 trusty
# 16.04 xenial
# 18.04 bionic
# 20.04 focal

# Version
VER="0.0.1-dev"

# check the --fqdn version, if it's absent fall back to hostname
HOSTNAME=$(hostname --fqdn 2>/dev/null)
if [[ $HOSTNAME == "" ]]; then
  HOSTNAME=$(hostname)
fi

# common ############################################################### START #
if [ ! -v SPINNER ]; then
    SPINNER="/-\|"
fi
log="${PWD}/`basename ${0}`.log"

function error_msg() {
    local MSG="${1}"
    echo "${MSG}"
    exit 1
}

function cecho() {
    echo -e "$1"
    echo -e "$1" >>"$log"
    tput sgr0;
}

function ncecho() {
    echo -ne "$1"
    echo -ne "$1" >>"$log"
    tput sgr0
}

function spinny() {
    if [ -n "$SPINNER" ]; then
        echo -ne "\b${SPINNER:i++%${#SPINNER}:1}"
    fi
}

function progress() {
    ncecho "  ";
    while [ /bin/true ]; do
        kill -0 $pid 2>/dev/null;
        if [[ $? = "0" ]]; then
            spinny
            sleep 0.25
        else
            ncecho "\b\b";
            wait $pid
            retcode=$?
            echo "$pid's retcode: $retcode" >> "$log"
            if [[ $retcode = "0" ]] || [[ $retcode = "255" ]]; then
                cecho success
            else
                cecho failed
                echo -e " [i] Showing the last 5 lines from the logfile ($log)...";
                tail -n5 "$log"
                exit 1;
            fi
            break 2;
        fi
    done
}

function progress_loop() {
    ncecho "  ";
    while [ /bin/true ]; do
        kill -0 $pid 2>/dev/null;
        if [[ $? = "0" ]]; then
            spinny
            sleep 0.25
        else
            ncecho "\b\b";
            wait $pid
            retcode=$?
            echo "$pid's retcode: $retcode" >> "$log"
            if [[ $retcode = "0" ]] || [[ $retcode = "255" ]]; then
                cecho success
            else
                cecho failed
                echo -e " [i] Showing the last 5 lines from the logfile ($log)...";
                tail -n5 "$log"
                exit 1;
            fi
            break 1;
        fi
    done
}

function progress_can_fail() {
    ncecho "  ";
    while [ /bin/true ]; do
        kill -0 $pid 2>/dev/null;
        if [[ $? = "0" ]]; then
            spinny
            sleep 0.25
        else
            ncecho "\b\b";
            wait $pid
            retcode=$?
            echo "$pid's retcode: $retcode" >> "$log"
            cecho success
            break 2;
        fi
    done
}

function check_root() {
    if [ "$(id -u)" != "0" ]; then
        error_msg "ERROR! You must execute the script as the 'root' user."
    fi
}

function check_sudo() {
    if [ ! -n ${SUDO_USER} ]; then
        error_msg "ERROR! You must invoke the script using 'sudo'."
    fi
}

function check_ubuntu() {
    if [ "${1}" != "" ]; then
        SUPPORTED_CODENAMES="${1}"
    else
        SUPPORTED_CODENAMES="all"
    fi

    # Source the lsb-release file.
    lsb

    # Check if this script is supported on this version of Ubuntu.
    if [ "${SUPPORTED_CODENAMES}" == "all" ]; then
        SUPPORTED=1
    else
        SUPPORTED=0
        for CHECK_CODENAME in `echo ${SUPPORTED_CODENAMES}`
        do
            if [ "${LSB_CODE}" == "${CHECK_CODENAME}" ]; then
                SUPPORTED=1
            fi
        done
    fi

    if [ ${SUPPORTED} -eq 0 ]; then
        error_msg "ERROR! ${0} is not supported on this version of Ubuntu."
    fi
}

function lsb() {
    local CMD_LSB_RELEASE=`which lsb_release`
    if [ "${CMD_LSB_RELEASE}" == "" ]; then
        error_msg "ERROR! 'lsb_release' was not found. I can't identify your distribution."
    fi
    LSB_ID=`lsb_release -i | cut -f2 | sed 's/ //g'`
    LSB_REL=`lsb_release -r | cut -f2 | sed 's/ //g'`
    LSB_CODE=`lsb_release -c | cut -f2 | sed 's/ //g'`
    LSB_DESC=`lsb_release -d | cut -f2`
    LSB_ARCH=`dpkg --print-architecture`
    LSB_MACH=`uname -m`
    LSB_NUM=`echo ${LSB_REL} | sed s'/\.//g'`
}

function apt_update() {
    ncecho " [x] Update package list "
    apt-get -y update >>"$log" 2>&1 &
    pid=$!;progress $pid
}
# common ################################################################# END #

function copyright_msg() {

    echo `basename ${0}`" v${VER} - Install Ubuntu."
    echo
}

function usage() {
    local MODE=${1}
    echo "## Usage"
    echo
    echo "    sudo ${0}"
    echo
    echo "Optional parameters"
    echo
    echo "  * -m <machine-name>      : Machine name."
    echo "  * -d </dev/vdx>          : Install disk device."
    echo "  * -k </dev/vdxn>         : Install disk partition."
    echo "  * -s <swap-size-M>       : SWAP size in mega bytes."
    echo "  * -a <arch>              : i386, amd64, armhf, ..."
    echo "  * -u <ubuntu-version>    : lucid, precise, trusty, xenial, bionic, focal"
    echo "  * -p <package-url>       : http://mirror01.idc.hinet.net/ubuntu"
    echo "  * -e <username>          : user"
    echo "  * -o <password>          : pass"
    echo "  * -n <network-interface> : ens3 for kvm, enp1s0 for real machine"
    echo "  * -i <ip-address>        : IP address"
    echo "  * -h                     : This help"
    echo
    echo "sudo ./install.sh -m box549 -d /dev/vdb -s 4096 -a amd64 -u focal -p http://mirror01.idc.hinet.net/ubuntu -e user -o pass -n enp1s0 -i 172.16.5.49"
}

function check_tools() {
    ncecho " [x] Install parted "
    local CHECK=`which parted`
    if [ -z "$CHECK" ]; then
        apt-get -y install parted >>"$log" 2>&1 &
    fi
    pid=$!;progress $pid
}

function clean_disk() {
    ncecho " [x] Clean disk "
    dd if=/dev/zero of=$DISK_NAME bs=512 count=1 >>"$log" 2>&1 &
    pid=$!;progress $pid
}

function partition_disk() {
    ncecho " [x] Partition disk "
    parted $DISK_NAME -s "mklabel msdos mkpart primary ext4 1 -1 set 1 boot on print" >>"$log" 2>&1 &
    pid=$!;progress $pid
}

function mkfs_ext4() {
    ncecho " [x] Make ext4 file system "
    mkfs.ext4 ${DISK_NAME}1 >>"$log" 2>&1 &
    pid=$!;progress $pid
}

function umount_disk() {
    local CHECK
    ncecho " [x] Unmount disk "

    CHECK=`mount | grep $INSTALLER_PATH/sys`
    [ -z "$CHECK" ] || umount ${INSTALLER_PATH}/sys >>"$log" 2>&1

    CHECK=`mount | grep ${INSTALLER_PATH}/proc`
    [ -z "$CHECK" ] || umount ${INSTALLER_PATH}/proc >>"$log" 2>&1

    CHECK=`mount | grep $INSTALLER_PATH/dev/pts`
    [ -z "$CHECK" ] || umount ${INSTALLER_PATH}/dev/pts >>"$log" 2>&1

    CHECK=`mount | grep $INSTALLER_PATH/dev`
    [ -z "$CHECK" ] || umount ${INSTALLER_PATH}/dev >>"$log" 2>&1

    CHECK=`mount | grep ${INSTALLER_PATH}`
    [ -z "$CHECK" ] || umount ${INSTALLER_PATH} >>"$log" 2>&1 &

    pid=$!;progress $pid
}

function mount_installer_disk() {
    ncecho " [x] Mount disk "
    mkdir -p $INSTALLER_PATH >>"$log" 2>&1
    [ ! -z $DISK_NAME ] && mount ${DISK_NAME}1 $INSTALLER_PATH >>"$log" 2>&1
    [ ! -z $PART_NAME ] && mount ${PART_NAME}  $INSTALLER_PATH >>"$log" 2>&1
    df >>"$log" 2>&1
    pid=$!;progress $pid
}

function do_debootstrap() {
    ncecho " [x] Do debootstrap "
    debootstrap --arch=${ARCH} ${UBUNTU_VERSION} $INSTALLER_PATH ${PACKAGE_URL} >>"$log" 2>&1 &
    pid=$!;progress $pid
    df >>"$log" 2>&1
}

function create_swap_file() {
    ncecho " [x] Create swap file "
    #local DD_BS=64
    #local DD_COUNT=`echo $SWAP_SIZE / $DD_BS | bc`
    #dd if=/dev/zero of=$INSTALLER_PATH/swapfile bs=${DD_BS}M count=$DD_COUNT >>"$log" 2>&1 &
    fallocate -l ${SWAP_SIZE}M ${INSTALLER_PATH}/swapfile >>"$log" 2>&1 &
    pid=$!;progress $pid

    mkswap $INSTALLER_PATH/swapfile >>"$log" 2>&1
    ls -la $INSTALLER_PATH >>"$log" 2>&1
    df >>"$log" 2>&1
}

function mount_for_setup_machine() {
    mount --bind /dev     ${INSTALLER_PATH}/dev     >>"$log" 2>&1
    mount --bind /dev/pts ${INSTALLER_PATH}/dev/pts >>"$log" 2>&1
    mount -t proc proc    ${INSTALLER_PATH}/proc    >>"$log" 2>&1
    mount -t sysfs sys    ${INSTALLER_PATH}/sys     >>"$log" 2>&1
    mount >>"$log" 2>&1
}

function setup_machine() {
    local disk_name
    ncecho " [x] Setup machine "
    cp setup-ubuntu.sh ${INSTALLER_PATH} >>"$log" 2>&1
    chmod +x setup-ubuntu.sh ${INSTALLER_PATH} >>"$log" 2>&1
    [ ! -z $DISK_NAME ] && disk_name=$DISK_NAME
    [ -z $DISK_NAME ] && disk_name=${PART_NAME//[0-9]/}
    chroot $INSTALLER_PATH ./setup-ubuntu.sh $disk_name $VM_NAME $UBUNTU_VERSION $PACKAGE_URL $USERNAME $PASSWORD $NETWORK_INTERFACE $IP>>"$log" 2>&1 &
    pid=$!;progress $pid
    df >>"$log" 2>&1
    rm ${INSTALLER_PATH}/setup-ubuntu.sh
}

function copy_log() {
    # copy log to install disk before umount
    cp "$log" ${INSTALLER_PATH}
}

copyright_msg

# Check we are running on a supported system in the correct way.
check_root
check_sudo
check_ubuntu "all"

# Init variables
INSTALLER_PATH="/mnt/installer"
VM_NAME=""
DISK_NAME=""
SWAP_SIZE=0
ARCH=""
UBUNTU_VERSION=""
PACKAGE_URL=""
NETWORK_INTERFACE="ens3"
IP=""

# Remove a pre-existing log file.
if [ -f $log ]; then
    rm -f $log 2>/dev/null
fi

# Parse the options
OPTSTRING=a:d:e:hi:k:m:n:o:p:s:u:
while getopts ${OPTSTRING} OPT
do
    case ${OPT} in
        a) ARCH=$OPTARG;;
        d) DISK_NAME=$OPTARG;;
        e) USERNAME=$OPTARG;;
        h) usage;;
        n) NETWORK_INTERFACE=$OPTARG;;
        k) PART_NAME=$OPTARG;;
        m) VM_NAME=$OPTARG;;
        o) PASSWORD=$OPTARG;;
        p) PACKAGE_URL=$OPTARG;;
        s) SWAP_SIZE=$OPTARG;;
        u) UBUNTU_VERSION=$OPTARG;;
        i) IP=$OPTARG;;
        *) usage;;
    esac
done
shift "$(( $OPTIND - 1 ))"


cecho VM_NAME=$VM_NAME
cecho DISK_NAME=$DISK_NAME
cecho PART_NAME=$PART_NAME
cecho SWAP_SIZE=$SWAP_SIZE
cecho ARCH=$ARCH
cecho UBUNTU_VERSION=$UBUNTU_VERSION
cecho PACKAGE_URL=$PACKAGE_URL
cecho USERNAME=$USERNAME
cecho PASSWORD=$PASSWORD
cecho NETWORK_INTERFACE=$NETWORK_INTERFACE
cecho IP=$IP
cecho

if [ -z $DISK_NAME ] && [ -z $PART_NAME ]; then
    usage && exit
fi

check_tools
umount_disk
if [ ! -z $DISK_NAME ]; then
    clean_disk
    partition_disk
    mkfs_ext4
fi
mount_installer_disk
do_debootstrap
create_swap_file
mount_for_setup_machine
setup_machine
copy_log
umount_disk
