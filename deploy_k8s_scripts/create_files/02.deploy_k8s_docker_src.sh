#!/bin/bash
# 2020年12月28日
# Auto Deploy Docker with source
# BY: Lucifer
###################################

if [ ${SCRIPTS_DIR} == "" ];then
	SCRIPTS_DIR=$(cd ..; pwd)
fi
source ${SCRIPTS_DIR}/env/directory_set.sh
BIN_DIR="/usr/local/bin"
Docker_VER="19.03.14"
Docker_SRC="docker-${Docker_VER}.tgz"
Docker_URL="https://download.docker.com/linux/static/stable/x86_64"

yum remove -y docker*

# Download
mkdir -p ${WORK_DIR}/{src,bin,conf/docker,service/docker}
cd ${WORK_DIR}/src
wget -c -N ${Docker_URL}/${Docker_SRC}
tar xvf ${Docker_SRC} -C ${WORK_DIR}/bin

cd ${WORK_DIR}/service/docker
# Create docker.service
cat > docker.service <<"EOF"
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.io

[Service]
ExecStart=/usr/local/bin/dockerd
ExecReload=/bin/kill -s HUP $MAINPID
Restart=on-failure
RestartSec=5
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
Delegate=yes
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

# Create Docker Daemon.json
cd ${WORK_DIR}/conf/docker
cat > docker-daemon.json <<EOF
{
    "registry-mirrors": [
        "https://dbzucv6w.mirror.aliyuncs.com",
        "https://registry.docker-cn.com",
        "http://hub-mirror.c.163.com",
        "https://docker.mirrors.ustc.edu.cn"
    ],
    "exec-opts": ["native.cgroupdriver=systemd"],
    "data-root": "${Docker_DATA_DIR}",
    "exec-root": "${Docker_EXEC_DIR}",
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
