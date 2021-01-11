#!/bin/bash

if [ ${SCRIPTS_DIR} == "" ];then
	SCRIPTS_DIR=$(cd ..; pwd)
fi

source ${SCRIPTS_DIR}/env/environment.sh
# 目录规划
WORK_DIR="/opt/k8s/work"
K8S_DATA_DIR="/data/kubernetes"
K8S_BIN_DIR="/usr/local/bin"
SYSTEMD_DIR="/usr/lib/systemd/system"


# ETCD
ETCD_DATA_DIR="/data/kubernetes/etcd/data"
ETCD_WAL_DIR="/data/kubernetes/etcd/wal"
ETCD_CONF_DIR="/etc/etcd"
ETCD_CERT_DIR="/etc/etcd/ssl"

# Docker
DOCKER_CONF_DIR="/etc/docker"
Docker_DATA_DIR="/data/kubernetes/docker/data"
Docker_EXEC_DIR="/data/kubernetes/docker/exec"

# Kubernetes
K8S_DIR="/data/kubernetes/k8s"
K8S_CONF_DIR="/etc/kubernetes"
K8S_CERT_DIR="/etc/kubernetes/pki"

# Calico
## PAMA
#  --network-plugin=cni
#  --cni-conf-dir=/etc/cni/net.d
#  --cni-bin-dir=/opt/cni/bin
#  --volume-plugin-dir=/usr/libexec/kubernetes/kubelet-plugins/volume/exec
  
CNI_CONF_DIR="/etc/cni/net.d"
CNI_BIN_DIR="/opt/cni/bin"

#mkdir -p /opt/k8s/{work/{cert,bin,src,conf,kubeconfig},bin}
#mkdir -p /data/kubernetes/{k8s,etcd/{data,wal},docker/{data,exec}}
#mkdir -p /etc/kubernetes/cert
#mkdir -p /etc/etcd/cert

#mkdir -p /var/lib/kubelet /var/log/kubernetes /etc/systemd/system/kubelet.service.d /etc/kubernetes/manifests/
