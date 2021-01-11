#!/bin/bash

systemctl disable --now firewalld &> /dev/null 
systemctl disable --now dnsmasq &> /dev/null
setenforce 0 && sed -ri '/^SELINUX=/cSELINUX=disabled' /etc/selinux/conf
swapoff -a && sed -ri '/swap/s/^/# /' /etc/fstab
yum install -y chrony && systemctl enable --now chronyd


#########################################
#            Setting limits             #
#########################################
ulimit -SHn 65535
echo "#### Setting limits ####"

sed -i '/^# End of file/d' /etc/security/limits.conf
cat >> /etc/security/limits.conf <<EOF
*	soft	nofile	655360
*	hard	nofile	131072
*	soft	nproc	655350
*	hard	nproc	655350
*	soft	memlock	unlimited
*	hard	memlock	unlimited
# End of file
EOF

yum install wget jq psmisc vim net-tools yum-utils device-mapper-persistent-data lvm2 git -y
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-8.repo
yum makecache
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

yum update -y
