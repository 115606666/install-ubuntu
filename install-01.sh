#!/bin/sh

echo "$# parameters"

if [ "$#" -ne 1 ]; then
    echo "$0 /home/lubuntu/install-02.sh"
    exit
fi

echo 0 $0
echo 1 $1

USERNAME=user
sudo chroot / $1 $USERNAME

sudo gpasswd -a $USERNAME sudo
sudo sed -i 's/archive.ubuntu.com/mirror.twds.com.tw/g' /etc/apt/sources.list
sudo sed -i 's/security.ubuntu.com/mirror.twds.com.tw/g' /etc/apt/sources.list
sudo apt-get update
sudo apt-get install -y openssh-server
sudo service ssh restart

echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKEjxVeq9BVYC4P0uiq9jcb4QztzlBjRMC+Ci1bIOTLo 202504161" >> authorized_keys

chmod 644 authorized_keys
sudo mkdir /home/$USERNAME/.ssh
sudo chmod 711 /home/$USERNAME/.ssh
sudo mv authorized_keys /home/$USERNAME/.ssh
sudo chown -R ${USERNAME}.${USERNAME} /home/$USERNAME/.ssh

echo $USERNAME ALL=\(ALL\) NOPASSWD: ALL | sudo tee -a /etc/sudoers

ip a
