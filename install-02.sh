#!/bin/sh

echo "$# parameters"

if [ "$#" -ne 2 ]; then
    echo "$0 username password"
    exit
fi

echo 0 $0
echo 1 $1
echo 2 $2


echo | adduser --quiet --disabled-password $1
echo "$1:$2" | chpasswd

echo $1 ALL=\(ALL\) NOPASSWD: ALL >> /etc/sudoers
