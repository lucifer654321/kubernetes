#!/bin/bash
# 2020年12月2日
# Auto Install The Docker to All k8s nodes
# By: Lucifer
###########################################

#################################
#          部署 Docker          #
#################################

source ./directory_set.sh

Containerd_RPM='containerd.io-1.4.3-3.1.el7.x86_64.rpm'
PKG_Dir="${WORK_DIR}/pkg"
DOCKER_DIR="${K8S_DATA_DIR}/docker"
DOCKER_WORK_CONF_DIR="${WORK_DIR}/conf/docker"

echo "#### Deploy Docker ####"

yum remove -y docker*

mkdir -p ${DOCKER_WORK_CONF_DIR} ${PKG_Dir}
cd ${DOCKER_WORK_CONF_DIR}

# Create Docker Daemon.json
cat > docker-daemon.json <<EOF
{
    "registry-mirrors": [
        "https://dbzucv6w.mirror.aliyuncs.com",
        "https://registry.docker-cn.com",
        "http://hub-mirror.c.163.com",
        "https://docker.mirrors.ustc.edu.cn"
    ],
    "exec-opts": ["native.cgroupdriver=systemd"],
    "data-root": "${DOCKER_DIR}/data",
    "exec-root": "${DOCKER_DIR}/exec",
    "max-concurrent-downloads": 10,
    "max-concurrent-uploads": 5, 
    "log-driver": "json-file",
    "log-opts": {
      "max-size": "100m",
      "max-file": "5"
    },
    "live-restore": true,
    "storage-driver": "overlay2",
    "storage-opts": [
      "overlay2.override_kernel_check=true"
    ]
}
EOF

yum install -y docker-ce 2> err.log

if [ $? -ne 0 ];then
    Containerd_RPM="$(grep filtering err.log |awk '{print $3}').rpm"
    rm -rf ./err.log
else
    rm -rf ./err.log
    exit
fi
wget -c -N https://mirrors.aliyun.com/docker-ce/linux/centos/7/x86_64/stable/Packages/${Containerd_RPM} -P ${PKG_Dir}
