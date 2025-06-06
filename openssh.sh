#!/usr/bin/env bash
## CVE-2024-39894 and CVE-2024-39894

set -o pipefail
set -o nounset
set -o errexit

## OPENSSH VERSION SET HERE
OPENSSH_VERSION="10.0p1"

echo "OPENSSH SERVER VERSION TO BE INSTALLED IS: ${OPENSSH_VERSION}. INSTALLING DEPENDENT PACKAGES..."
sudo yum install gcc openssl11 openssl11-devel zlib-devel mlocate autoconf systemd-devel -y

echo "DOWNLOAD OPENSSH SERVER VERSION ${OPENSSH_VERSION} SOURCE FILES."
wget https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-${OPENSSH_VERSION}.tar.gz
tar zxvf openssh-${OPENSSH_VERSION}.tar.gz && cd openssh-${OPENSSH_VERSION}

echo "OPENSSH SERVER VERSION ${OPENSSH_VERSION} COMPILING FROM SOURCE..."
chmod +x configure
./configure --with-ssl-dir=/usr/include/openssl --with-selinux
sed -i '129a\#include <systemd/sd-daemon.h>' sshd.c
sed -i '2095a\        /* Signal systemd that we are ready to accept connections */' sshd.c
sed -i '2096a\        sd_notify (0, "READY=1");' sshd.c
sed -i 's#LIBS=-ldl -lutil  -lresolv -lselinux#LIBS =-ldl -lutil  -lresolv -lselinux -lsystemd#g' Makefile
make && sudo make install

echo "REMOVED OPENSSH SERVER VERSION ${OPENSSH_VERSION} SOURCE FILES..."
cd .. && rm -rf openssh-*

sed -i 's#/usr/sbin/sshd#/usr/local/sbin/sshd#g' /usr/lib/systemd/system/sshd.service
sed -i '/Ciphers and keying/a PIDFile=/var/run/sshd.pid' /usr/lib/systemd/system/sshd.service


echo "OPENSSH SERVER VERSION ${OPENSSH_VERSION} RELOADED..." && systemctl daemon-reload
## restart sshd
systemctl restart sshd.service

## check sshd status
echo "OPENSSH SERVER VERSION ${OPENSSH_VERSION} STATUS..." && systemctl status sshd.service

## Check installed version of sshd, versions of 9.7 or older this command fails but still shows version
echo "INSTALLED OPENSSH SERVER VERSION OF ${OPENSSH_VERSION} SHOULD MATCH..." && /usr/local/sbin/sshd -V || true
