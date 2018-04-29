#!/bin/sh

echo "$# parameters"

if [ "$#" -ne 1 ]; then
    echo "$0 username"
    exit
fi

echo 0 $0
echo 1 $1


echo | adduser --quiet --disabled-password $1

echo $1 ALL=\(ALL\) NOPASSWD: ALL >> /etc/sudoers
