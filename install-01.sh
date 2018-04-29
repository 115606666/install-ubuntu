#!/bin/sh

echo "$# parameters"

if [ "$#" -ne 1 ]; then
    echo "$0 /home/lubuntu/install-02.sh"
    exit
fi

echo 0 $0
echo 1 $1

USERNAME=mike
sudo chroot / $1 $USERNAME

sudo gpasswd -a mike sudo
sudo sed -i 's/archive.ubuntu.com/mirror01.idc.hinet.net/g' /etc/apt/sources.list
sudo sed -i 's/security.ubuntu.com/mirror01.idc.hinet.net/g' /etc/apt/sources.list
#sudo sed -i 's/archive.ubuntu.com/free.nchc.org.tw/g' /etc/apt/sources.list
#sudo sed -i 's/security.ubuntu.com/free.nchc.org.tw/g' /etc/apt/sources.list
sudo apt-get update
sudo apt-get install -y openssh-server
sudo service ssh restart

echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOdfDL2rt6w7rwfT5NF8yYS/4fH9TEXGJIXpeuzDaRdKpNdQw9xwfhrTdH4UQdyu6roQfi0k9L/HWvoH93sIOjcXBf2+nKokqEQxQDVcJJ2eNVR2KsVddCseqkoOtiTK7of7fRI8vO0ZAIzrKu49Qw/jMIvujHKkx6rBSvrWxNqMuPkKrOzHrkM/EA+6kAPgcYtMOdc0DFytOFjIiLksMkthGGTcB0hr/Sfa9CxMIBP54M9jZtV4BqDuvFHrAbG23to8CDZB16MEJrKY47fdvjw2iQ5kAIgvmPYCsHb2YHjRpKEGkT77B/LOcVy5kCWFzW7Ox5ct15PQyF3X8uiCpd" > authorized_keys
chmod 644 authorized_keys
sudo mkdir /home/$USERNAME/.ssh
sudo chmod 711 /home/$USERNAME/.ssh
sudo mv authorized_keys /home/$USERNAME/.ssh
sudo chown -R mike.mike /home/$USERNAME/.ssh

echo $USERNAME ALL=\(ALL\) NOPASSWD: ALL >> /etc/sudoers

ifconfig
