#!/usr/bin/bash

# 安装Calico插件
source ./deploy_network_calico

# 安装DNS插件
mkdir -p dns
cd dns
git clone https://github.com/coredns/deployment.git
cd deployment/kubernetes
./deploy.sh -s -i ${CLUSTER_DNS_SVC_IP}| kubectl apply -f -


# 安装Metric插件
mkdir -p metrics
cd metrics/
wget https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.7/components.yaml

# vim components.yaml
……
apiVersion: apps/v1
kind: Deployment
……
spec:
  replicas: 3							#根据集群规模调整副本数
……
    spec:
      hostNetwork: true
……
      - name: metrics-server
        image: dotbalo/metrics-server:0.3.7
        imagePullPolicy: IfNotPresent
        args:
          - --cert-dir=/tmp
          - --secure-port=4443
          - --kubelet-insecure-tls
          - --kubelet-preferred-address-types=InternalIP,Hostname,InternalDNS,ExternalDNS,ExternalIP	#追加此args
……

# kubectl apply -f components.yaml



# 安装Dashboard插件
cd /opt/k8s/work/dashboard
kubectl label nodes master01 dashboard=yes
kubectl label nodes master02 dashboard=yes
kubectl label nodes master03 dashboard=yes

wget https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.1/aio/deploy/recommended.yaml



## 修改yaml文件
……
kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: dashboard-metrics-scraper
  name: dashboard-metrics-scraper
  namespace: kubernetes-dashboard
spec:
  type: NodePort				        #新增
  ports:
    - port: 8000
      targetPort: 8000
      nodePort: 30000				#新增
  selector:
    k8s-app: dashboard-metrics-scraper
……
   replicas: 3					#适当调整为3副本
……
      nodeSelector:
        "beta.kubernetes.io/os": linux
        "dashboard": "yes"			        #部署在master节点
……


## 部署
kubectl apply -f recommended.yaml

## 添加管理员账户
cat > dashboard-admin.yaml <<EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# 
kubectl apply -f dashboard-admin.yaml