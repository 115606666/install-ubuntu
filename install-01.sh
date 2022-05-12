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
# https://blog.elleryq.idv.tw/2018/11/apt-mirror.html
# http://mirrors.ubuntu.com/mirrors.txt
#sudo sed -i 's/archive.ubuntu.com/ftp.yzu.edu.tw/g' /etc/apt/sources.list
#sudo sed -i 's/security.ubuntu.com/ftp.yzu.edu.tw/g' /etc/apt/sources.list
sudo apt-get update
sudo apt-get install -y openssh-server
sudo service ssh restart

#echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDOdfDL2rt6w7rwfT5NF8yYS/4fH9TEXGJIXpeuzDaRdKpNdQw9xwfhrTdH4UQdyu6roQfi0k9L/HWvoH93sIOjcXBf2+nKokqEQxQDVcJJ2eNVR2KsVddCseqkoOtiTK7of7fRI8vO0ZAIzrKu49Qw/jMIvujHKkx6rBSvrWxNqMuPkKrOzHrkM/EA+6kAPgcYtMOdc0DFytOFjIiLksMkthGGTcB0hr/Sfa9CxMIBP54M9jZtV4BqDuvFHrAbG23to8CDZB16MEJrKY47fdvjw2iQ5kAIgvmPYCsHb2YHjRpKEGkT77B/LOcVy5kCWFzW7Ox5ct15PQyF3X8uiCpd" >> authorized_keys

# ppk43
echo "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAid5v0ud2Y5xJgwziGnETGc7b7dh55dmnMf+uFuLx0gREJTtIwoiUhgMffRhR5/3FEquoASQnY1yBHxQHnRF7FaD1xA+pJlUnx9KJNol+PdPIrnWHTS6pjuDe+0HUt85KU3lt6EikLRIjUbQnCFmIN4aHnYmsi2VUIpenJLMzSK6jMpbqHRTkY3nSS3D1QNyweyY3FkuDYGCNKuqcYvNRFGV140Zd3F7+zPi/Exl5rSf+iYM3ksrCm6DhtHDGOEYBba2XfxC067S97IhivbdGzSX2SCskWC4ee9ONgAcdiVA45bJB1k9nJRbg3MOo9FEX/auI0hEEw4hxjTxawMIakw==" >> authorized_keys

chmod 644 authorized_keys
sudo mkdir /home/$USERNAME/.ssh
sudo chmod 711 /home/$USERNAME/.ssh
sudo mv authorized_keys /home/$USERNAME/.ssh
sudo chown -R mike.mike /home/$USERNAME/.ssh

echo $USERNAME ALL=\(ALL\) NOPASSWD: ALL >> /etc/sudoers

ip a
