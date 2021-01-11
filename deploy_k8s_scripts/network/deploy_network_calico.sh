#!/bin/bash
# 2020年12月12日
# Auto Deploy Network for Calico
# BY: Lucifer
########################################

#################################
#      部署network Calico       #
#################################

source directory_set.sh
K8S_CALICO_DIR="${WORK_DIR}/network/calico"


echo "#### Config Calico ####"

mkdir -p ${K8S_CALICO_DIR}
cd ${K8S_CALICO_DIR}

## Install Calico with Kubernetes API datastore, 50 nodes or less
curl https://docs.projectcalico.org/manifests/calico.yaml -O

### 将CALICO_IPV4POOL_CIDR及其value前的#去除，并修改value的值
cp calico.yaml calico.yaml.bak
# sed -i '/CALICO_IPV4POOL_CIDR/{s/# //;n;s/# \(  value: \).*/\1"10.244.0.0\/16"/}' calico.yaml
# sed -i "s#\/usr\/libexec\/kubernetes#${K8S_DIR}\/kubelet#" calico.yaml
sed -i "/CALICO_IPV4POOL_CIDR/{s/# //;n;s/# \(  value: \).*/\1'"'10.244.0.0\/16'"'/}; s@/usr/libexec/kubernetes@${K8S_DIR}/kubelet@" calico.yaml

kubectl apply -f calico.yaml

## Install Calico with Kubernetes API datastore, more than 50 nodes
# curl https://docs.projectcalico.org/manifests/calico-typha.yaml -o calico.yaml
### Modify the replica count to the desired number in the Deployment named, calico-typha.
# kubectl apply -f calico.yaml