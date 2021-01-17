#!/bin/bash
echo "#### Config Bootstrap ####"

[ -d "/root/.kube" ] || mkdir -p /root/.kube
ADMIN_CONFIG="/root/.kube/config"

[ -f ${ADMIN_CONFIG} ] || cp /etc/kubernetes/admin.kubeconfig ${ADMIN_CONFIG}

ALL_NAMES=( master01  master02  master03  k8snode01  k8snode02 )

for all_name in ${ALL_NAMES[@]}
do
    echo ">>> ${all_name}"

    # 创建 token
    export BOOTSTRAP_TOKEN=$(kubeadm token create \
      --description kubelet-bootstrap-token \
      --groups system:bootstrappers:${all_name} \
      --kubeconfig ~/.kube/config)

    # 设置集群参数
    kubectl config set-cluster kubernetes \
      --certificate-authority=/etc/kubernetes/pki/ca.pem \
      --embed-certs=true \
      --server=https://192.168.49.200:16443 \
      --kubeconfig=bootstrap/kubelet-bootstrap-${all_name}.kubeconfig

    # 设置客户端认证参数
    kubectl config set-credentials kubelet-bootstrap \
      --token=${BOOTSTRAP_TOKEN} \
      --kubeconfig=bootstrap/kubelet-bootstrap-${all_name}.kubeconfig

    # 设置上下文参数
    kubectl config set-context default \
      --cluster=kubernetes \
      --user=kubelet-bootstrap \
      --kubeconfig=bootstrap/kubelet-bootstrap-${all_name}.kubeconfig

    # 设置默认上下文
    kubectl config use-context default \
      --kubeconfig=bootstrap/kubelet-bootstrap-${all_name}.kubeconfig
done

# 分发bootstrap.kubeconfig
for i in  ${ALL_NAMES[@]}
do
    echo ">>> $i"
    ssh $i "mkdir -p /etc/kubernetes"
    scp bootstrap/kubelet-bootstrap-${i}.kubeconfig $i:/etc/kubernetes/kubelet-bootstrap.kubeconfig
done
