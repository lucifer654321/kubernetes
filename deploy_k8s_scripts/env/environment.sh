#!/bin/sh
#****************************************************************#
# ScriptName: environment.sh
# Author: gxw
# Create Date: 2020-07-29 15:59
# Modify Author: gxw
# Modify Date: 2020-06-27 15:59
# Version:
#***************************************************************#
# 生成 EncryptionConfig 所需的加密 key
export ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
# 集群VIP
export VIP="192.168.49.200"
# 集群 MASTER 机器 IP 数组
export MASTER_IPS=(192.168.49.30 192.168.49.33 192.168.49.34)
# 集群 MASTER IP 对应的主机名数组
export MASTER_NAMES=(master01 master02 master03)
# 集群 NODE 机器 IP 数组
export NODE_IPS=(192.168.49.31 192.168.49.32)
# 集群 NODE IP 对应的主机名数组
export NODE_NAMES=(k8snode01 k8snode02)
# 集群所有机器 IP 数组
#export ALL_IPS=(192.168.49.30 192.168.49.33 192.168.49.34 192.168.49.31 192.168.49.32)
export ALL_IPS=(${MASTER_IPS[@]} ${NODE_IPS[@]})
# 集群所有IP 对应的主机名数组
#export ALL_NAMES=(master01 master02 master03 k8snode01 k8snode02)
export ALL_NAMES=(${MASTER_NAMES[@]} ${NODE_NAMES[@]})

ETCD_ENDPOINT=""
ETCD_NODE=""
ETCD_ENDPOINTS=""
ETCD_NODES=""
for i in `seq ${#MASTER_IPS[@]}`
do
    ETCD_ENDPOINT="https://${MASTER_IPS[i-1]}:2379"
    ETCD_NODE="${MASTER_NAMES[i-1]}=https://${MASTER_IPS[i-1]}:2380"
    ETCD_ENDPOINTS+=",${ETCD_ENDPOINT}"
    ETCD_NODES+=",${ETCD_NODE}"
done
# etcd 集群服务地址列表
#export ETCD_ENDPOINTS="https://192.168.49.30:2379,https://192.168.49.33:2379,https://192.168.49.34:2379"
export ETCD_ENDPOINTS=`echo ${ETCD_ENDPOINTS}|sed 's/^,//'`
# etcd 集群间通信的 IP 和端口
#export ETCD_NODES="master01=https://192.168.49.30:2380,master02=https://192.168.49.33:2380,master03=https://192.168.49.34:2380"
export ETCD_NODES=`echo ${ETCD_NODES}|sed 's/^,//'`
# kube-apiserver 的反向代理(kube-nginx)地址端口
export KUBE_APISERVER="https://${VIP}:16443"
# 节点间互联网络接口名称
export IFACE="ens32"
# etcd 数据目录
export ETCD_DATA_DIR="/data/kubernetes/etcd/data"
# etcd WAL 目录，建议是 SSD 磁盘分区，或者和 ETCD_DATA_DIR 不同的磁盘分区
export ETCD_WAL_DIR="/data/kubernetes/etcd/wal"
# k8s 各组件数据目录
export K8S_DIR="/data/kubernetes/k8s"
# docker 数据目录
export DOCKER_DIR="/data/kubernetes/docker"
## 以下参数一般不需要修改
# TLS Bootstrapping 使用的 Token，可以使用命令 head -c 16 /dev/urandom | od -An -t x | tr -d ' ' 生成
BOOTSTRAP_TOKEN="41f7e4ba8b7be874fcff18bf5cf41a7c"
# 最好使用 当前未用的网段 来定义服务网段和 Pod 网段
# 服务网段，部署前路由不可达，部署后集群内路由可达(kube-proxy 保证)
SERVICE_CIDR="10.20.0.0/16"
# Pod 网段，建议 /16 段地址，部署前路由不可达，部署后集群内路由可达(flanneld 保证)
CLUSTER_CIDR="10.244.0.0/16"
# 服务端口范围 (NodePort Range)
export NODE_PORT_RANGE="30000-32767"
# flanneld 网络配置前缀
# export FLANNEL_ETCD_PREFIX="/kubernetes/network"
# kubernetes 服务 IP (一般是 SERVICE_CIDR 中第一个IP)
export CLUSTER_KUBERNETES_SVC_IP="10.20.0.1"
# 集群 DNS 服务 IP (从 SERVICE_CIDR 中预分配，通常为第10个IP)
export CLUSTER_DNS_SVC_IP="10.20.0.10"
# 集群 DNS 域名（末尾不带点号）
export CLUSTER_DNS_DOMAIN="cluster.local"
# 将二进制目录 /opt/k8s/bin 加到 PATH 中
export PATH=/opt/k8s/bin:$PATH
