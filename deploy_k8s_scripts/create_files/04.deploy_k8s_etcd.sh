#!/bin/bash
# 2020年12月12日
# Auto Deploy ETCD Cluster
# BY: Lucifer
###################################

#################################
#           部署ETCD            #
#################################

if [ ${SCRIPTS_DIR} == "" ];then
        SCRIPTS_DIR=$(cd ..; pwd)
fi
source ${SCRIPTS_DIR}/env/directory_set.sh
ETCD_WORK_SYSTEMD_DIR="${WORK_DIR}/service/etcd"

echo "#### Install ETCD ####"

mkdir -p ${ETCD_WORK_SYSTEMD_DIR}
cd ${ETCD_WORK_SYSTEMD_DIR}

# 创建ETCD systemd文件
cat > etcd.service.tpl <<EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos

[Service]
Type=notify
WorkingDirectory=${ETCD_DATA_DIR}
ExecStart=${K8S_BIN_DIR}/etcd \\
  --data-dir=${ETCD_DATA_DIR} \\
  --wal-dir=${ETCD_WAL_DIR} \\
  --name=##MASTER_NAME## \\
  --cert-file=${ETCD_CERT_DIR}/etcd.pem \\
  --key-file=${ETCD_CERT_DIR}/etcd-key.pem \\
  --trusted-ca-file=${ETCD_CERT_DIR}/etcd-ca.pem \\
  --peer-cert-file=${ETCD_CERT_DIR}/etcd.pem \\
  --peer-key-file=${ETCD_CERT_DIR}/etcd-key.pem \\
  --peer-trusted-ca-file=${ETCD_CERT_DIR}/etcd-ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --listen-peer-urls=https://##MASTER_IP##:2380 \\
  --initial-advertise-peer-urls=https://##MASTER_IP##:2380 \\
  --listen-client-urls=https://##MASTER_IP##:2379,http://127.0.0.1:2379 \\
  --advertise-client-urls=https://##MASTER_IP##:2379 \\
  --initial-cluster-token=etcd-cluster-0 \\
  --initial-cluster=${ETCD_NODES} \\
  --initial-cluster-state=new \\
  --auto-compaction-mode=periodic \\
  --auto-compaction-retention=1 \\
  --max-request-bytes=33554432 \\
  --quota-backend-bytes=6442450944 \\
  --heartbeat-interval=250 \\
  --election-timeout=2000
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

## 修改systemd相应地址
for (( i=0; i < 3; i++ ))
do
    sed -e "s/##MASTER_NAME##/${MASTER_NAMES[i]}/" -e "s/##MASTER_IP##/${MASTER_IPS[i]}/" etcd.service.tpl > etcd-${MASTER_IPS[i]}.service
done
rm -rf etcd.service.tpl

