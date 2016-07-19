#!/bin/sh

echo "$# parameters"

if [ "$#" -ne 1 ]; then
    echo "$0 /home/lubuntu/install-02.sh"
    exit
fi

echo 0 $0
echo 1 $1

USERNAME=mike
PASSWORD=aaaaaa
sudo chroot / $1 $USERNAME $PASSWORD

sudo gpasswd -a mike sudo
sudo sed -i 's/archive.ubuntu.com/mirror01.idc.hinet.net/g' /etc/apt/sources.list
sudo sed -i 's/security.ubuntu.com/mirror01.idc.hinet.net/g' /etc/apt/sources.list
#sudo sed -i 's/archive.ubuntu.com/free.nchc.org.tw/g' /etc/apt/sources.list
#sudo sed -i 's/security.ubuntu.com/free.nchc.org.tw/g' /etc/apt/sources.list
sudo apt-get update
sudo apt-get install -y openssh-server
sudo service ssh restart

echo "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIBov/V1m4uuqc4Sl4ZxmibN5g94YvBFGLGVHnmRdkmn2g+pfpsxl9jfwdRFPprzUdzp/jROihKBRA3JmInoMh55b9P2Ak4iPeUuGsQHweaBlgtqnWoukoDh5X0Q6atBXs44QAxeuc8fckm6JWq2uhYIrbbKegtNHN2VRAeAekmVCQ== AVNET" > authorized_keys
chmod 644 authorized_keys
sudo mkdir /home/$USERNAME/.ssh
sudo chmod 711 /home/$USERNAME/.ssh
sudo mv authorized_keys /home/$USERNAME/.ssh
sudo chown -R mike.mike /home/$USERNAME/.ssh

ifconfig
