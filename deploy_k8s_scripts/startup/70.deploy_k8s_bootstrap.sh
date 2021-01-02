#!/bin/bash
# 2020年12月12日
# Auto Deploy TLS Bootstrapping
# BY: Lucifer
########################################

#################################
#    TLS Bootstrapping配置      #
#################################

if [ ${SCRIPTS_DIR} == "" ];then
        SCRIPTS_DIR=$(cd ..; pwd)
fi
source ${SCRIPTS_DIR}/env/directory_set.sh
BOOTSTRAP_DIR="${WORK_DIR}/bootstrap"

mkdir -p ${BOOTSTRAP_DIR}
cd ${BOOTSTRAP_DIR}
echo "#### Config Bootstrap ####"

[ -d "/root/.kube" ] || mkdir -p /root/.kube
ADMIN_CONFIG="/root/.kube/config"

[ -f ${ADMIN_CONFIG} ] || cp ${K8S_CONF_DIR}/admin.kubeconfig ${ADMIN_CONFIG}

# 授予kube-apiserver访问kubelet API的权限
kubectl create clusterrolebinding kube-apiserver:kubelet-apis \
--clusterrole=system:kubelet-api-admin --user kube-apiserver

# 创建TLS Bootstrapping
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
      --certificate-authority=${K8S_CERT_DIR}/ca.pem \
      --embed-certs=true \
      --server=${KUBE_APISERVER} \
      --kubeconfig=kubelet-bootstrap-${all_name}.kubeconfig

    # 设置客户端认证参数
    kubectl config set-credentials kubelet-bootstrap \
      --token=${BOOTSTRAP_TOKEN} \
      --kubeconfig=kubelet-bootstrap-${all_name}.kubeconfig

    # 设置上下文参数
    kubectl config set-context default \
      --cluster=kubernetes \
      --user=kubelet-bootstrap \
      --kubeconfig=kubelet-bootstrap-${all_name}.kubeconfig

    # 设置默认上下文
    kubectl config use-context default \
      --kubeconfig=kubelet-bootstrap-${all_name}.kubeconfig
done

# 分发kubelet-bootstrap.kubeconfig
for all_name in ${ALL_NAMES[@]}
do
	echo ">>> ${all_name}"
	scp kubelet-bootstrap-${all_name}.kubeconfig ${all_name}:${K8S_CONF_DIR}/kubelet-bootstrap.kubeconfig
done

# 创建权限
kubectl create clusterrolebinding kubelet-bootstrap \
--clusterrole=system:node-bootstrapper \
--group=system:bootstrappers

# 创建自动approve csr配置文件
cat > csr-crb.yaml <<EOF
 # Approve all CSRs for the group "system:bootstrappers"
 kind: ClusterRoleBinding
 apiVersion: rbac.authorization.k8s.io/v1
 metadata:
   name: auto-approve-csrs-for-group
 subjects:
 - kind: Group
   name: system:bootstrappers
   apiGroup: rbac.authorization.k8s.io
 roleRef:
   kind: ClusterRole
   name: system:certificates.k8s.io:certificatesigningrequests:nodeclient
   apiGroup: rbac.authorization.k8s.io
---
 # To let a node of the group "system:nodes" renew its own credentials
 kind: ClusterRoleBinding
 apiVersion: rbac.authorization.k8s.io/v1
 metadata:
   name: node-client-cert-renewal
 subjects:
 - kind: Group
   name: system:nodes
   apiGroup: rbac.authorization.k8s.io
 roleRef:
   kind: ClusterRole
   name: system:certificates.k8s.io:certificatesigningrequests:selfnodeclient
   apiGroup: rbac.authorization.k8s.io
---
# A ClusterRole which instructs the CSR approver to approve a node requesting a
# serving cert matching its client cert.
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: approve-node-server-renewal-csr
rules:
- apiGroups: ["certificates.k8s.io"]
  resources: ["certificatesigningrequests/selfnodeserver"]
  verbs: ["create"]
---
 # To let a node of the group "system:nodes" renew its own server credentials
 kind: ClusterRoleBinding
 apiVersion: rbac.authorization.k8s.io/v1
 metadata:
   name: node-server-cert-renewal
 subjects:
 - kind: Group
   name: system:nodes
   apiGroup: rbac.authorization.k8s.io
 roleRef:
   kind: ClusterRole
   name: approve-node-server-renewal-csr
   apiGroup: rbac.authorization.k8s.io
EOF

# 
kubectl apply -f csr-crb.yaml
