#!/usr/bin/env bash

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

    echo `basename ${0}`" v${VER} - Install Ubuntu 20.04."
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
    echo "  * -u <username>       : default: mike"
    echo "  * -p <password>       : default: aaaaaa"
    echo "  * -h                  : This help"
    echo
    echo "sudo ${0} -u mike -p aaaaaa"
}

function add_user() {
    ncecho " [x] Add user $USERNAME "
    echo | adduser --quiet --disabled-password $USERNAME >>"$log" 2>&1
    echo "$USERNAME:$PASSWORD" | chpasswd >>"$log" 2>&1
    gpasswd -a $USERNAME sudo >>"$log" 2>&1
    echo $USERNAME ALL=\(ALL\) NOPASSWD: ALL >> /etc/sudoers
    pid=$!;progress $pid
}

function change_apt_sources() {
    ncecho " [x] Change apt sources "
    sed -i 's/archive.ubuntu.com/mirror01.idc.hinet.net/g'  /etc/apt/sources.list
    sed -i 's/security.ubuntu.com/mirror01.idc.hinet.net/g' /etc/apt/sources.list
    apt-get update >>"$log" 2>&1 &
    pid=$!;progress $pid
}

function install_debootstrap() {
    ncecho " [x] Install debootstrap "
    apt-get -y install debootstrap >>"$log" 2>&1 &
    pid=$!;progress $pid
}

function install_openssh_server() {
    ncecho " [x] Install openssh server "
    apt-get install -y openssh-server >>"$log" 2>&1
    pid=$!;progress $pid
}

function start_openssh_server() {
    ncecho " [x] Start openssh server "
    service ssh restart >>"$log" 2>&1
    pid=$!;progress $pid
}

function install_openssh_keys() {
    ncecho " [x] Install openssh keys "
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOdfDL2rt6w7rwfT5NF8yYS/4fH9TEXGJIXpeuzDaRdKpNdQw9xwfhrTdH4UQdyu6roQfi0k9L/HWvoH93sIOjcXBf2+nKokqEQxQDVcJJ2eNVR2KsVddCseqkoOtiTK7of7fRI8vO0ZAIzrKu49Qw/jMIvujHKkx6rBSvrWxNqMuPkKrOzHrkM/EA+6kAPgcYtMOdc0DFytOFjIiLksMkthGGTcB0hr/Sfa9CxMIBP54M9jZtV4BqDuvFHrAbG23to8CDZB16MEJrKY47fdvjw2iQ5kAIgvmPYCsHb2YHjRpKEGkT77B/LOcVy5kCWFzW7Ox5ct15PQyF3X8uiCpd" >> authorized_keys
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAid5v0ud2Y5xJgwziGnETGc7b7dh55dmnMf+uFuLx0gREJTtIwoiUhgMffRhR5/3FEquoASQnY1yBHxQHnRF7FaD1xA+pJlUnx9KJNol+PdPIrnWHTS6pjuDe+0HUt85KU3lt6EikLRIjUbQnCFmIN4aHnYmsi2VUIpenJLMzSK6jMpbqHRTkY3nSS3D1QNyweyY3FkuDYGCNKuqcYvNRFGV140Zd3F7+zPi/Exl5rSf+iYM3ksrCm6DhtHDGOEYBba2XfxC067S97IhivbdGzSX2SCskWC4ee9ONgAcdiVA45bJB1k9nJRbg3MOo9FEX/auI0hEEw4hxjTxawMIakw==" >> authorized_keys

    chmod 644 authorized_keys >>"$log" 2>&1
    mkdir /home/$USERNAME/.ssh >>"$log" 2>&1
    chmod 711 /home/$USERNAME/.ssh >>"$log" 2>&1
    mv authorized_keys /home/$USERNAME/.ssh >>"$log" 2>&1
    chown -R mike.mike /home/$USERNAME/.ssh >>"$log" 2>&1

    pid=$!;progress $pid
}

function print_ip_addresses() {
    echo "------------------------------------------------------------------"
    ip a
}

copyright_msg

# Check we are running on a supported system in the correct way.
check_root
check_sudo
check_ubuntu "all"

# Init variables
USERNAME="mike"
PASSWORD="aaaaaa"

# Remove a pre-existing log file.
if [ -f $log ]; then
    rm -f $log 2>/dev/null
fi

# Parse the options
OPTSTRING=hu:p:
while getopts ${OPTSTRING} OPT
do
    case ${OPT} in
        h) usage;;
        u) USERNAME=$OPTARG;;
        p) PASSWORD=$OPTARG;;
        *) usage;;
    esac
done
shift "$(( $OPTIND - 1 ))"


cecho USERNAME=$USERNAME
cecho PASSWORD=$PASSWORD
cecho


add_user
change_apt_sources
install_debootstrap
install_openssh_server
start_openssh_server
install_openssh_keys
print_ip_addresses