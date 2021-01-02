#!/bin/bash
# 2020年12月12日
# Auto Deploy Master Nodes
# BY: Lucifer
########################################

#################################
#      部署kube-apiserver       #
#################################

if [ ${SCRIPTS_DIR} == "" ];then
        SCRIPTS_DIR=$(cd ..; pwd)
fi
source ${SCRIPTS_DIR}/env/directory_set.sh
K8S_WORK_CONF_DIR="${WORK_DIR}/conf/k8s"
K8S_WORK_SYSTEMD_DIR="${WORK_DIR}/service/k8s"

echo "#### Deploy kube-apiserver ####"

mkdir -p ${K8S_WORK_CONF_DIR} ${K8S_WORK_SYSTEMD_DIR}
cd ${K8S_WORK_SYSTEMD_DIR}

# 创建apiserver的systemd文件
cat > kube-apiserver.service.tpl <<EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
WorkingDirectory=${K8S_DIR}/kube-apiserver
ExecStart=${K8S_BIN_DIR}/kube-apiserver \\
  --v=2 \\
  --logtostderr=true \\
  --allow-privileged=true \\
  --bind-address=##MASTER_IP## \\
  --advertise-address=##MASTER_IP## \\
  --secure-port=6443 \\
  --insecure-port=0 \\
  --default-not-ready-toleration-seconds=360 \\
  --default-unreachable-toleration-seconds=360 \\
  --max-mutating-requests-inflight=2000 \\
  --max-requests-inflight=4000 \\
  --default-watch-cache-size=200 \\
  --delete-collection-workers=2 \\
  --encryption-provider-config=${K8S_CONF_DIR}/encryption-config.yaml \\
  --etcd-servers=${ETCD_ENDPOINTS} \\
  --etcd-cafile=${ETCD_CERT_DIR}/etcd-ca.pem \\
  --etcd-certfile=${ETCD_CERT_DIR}/etcd.pem \\
  --etcd-keyfile=${ETCD_CERT_DIR}/etcd-key.pem \\
  --tls-cert-file=${K8S_CERT_DIR}/kube-apiserver.pem \\
  --tls-private-key-file=${K8S_CERT_DIR}/kube-apiserver-key.pem \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-truncate-enabled=true \\
  --audit-log-path=${K8S_DIR}/kube-apiserver/audit.log \\
  --audit-policy-file=${K8S_CONF_DIR}/audit-policy.yaml \\
  --profiling \\
  --anonymous-auth=false \\
  --client-ca-file=${K8S_CERT_DIR}/ca.pem \\
  --enable-bootstrap-token-auth=true \\
  --requestheader-allowed-names=aggregator \\
  --requestheader-client-ca-file=${K8S_CERT_DIR}/front-proxy-ca.pem \\
  --requestheader-extra-headers-prefix=X-Remote-Extra- \\
  --requestheader-group-headers=X-Remote-Group \\
  --requestheader-username-headers=X-Remote-User \\
  --service-account-key-file=${K8S_CERT_DIR}/sa.pub \\
  --authorization-mode=Node,RBAC \\
  --runtime-config=api/all=true \\
  --enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,NodeRestriction,ResourceQuota  \\
  --apiserver-count=3 \\
  --event-ttl=168h \\
  --kubelet-certificate-authority=${K8S_CERT_DIR}/ca.pem \\
  --kubelet-client-certificate=${K8S_CERT_DIR}/kube-apiserver.pem \\
  --kubelet-client-key=${K8S_CERT_DIR}/kube-apiserver-key.pem \\
  --kubelet-https=true \\
  --kubelet-timeout=10s \\
  --proxy-client-cert-file=${K8S_CERT_DIR}/front-proxy-client.pem \\
  --proxy-client-key-file=${K8S_CERT_DIR}/front-proxy-client-key.pem \\
  --service-cluster-ip-range=${SERVICE_CIDR} \\
  --service-node-port-range=${NODE_PORT_RANGE}

Restart=on-failure
RestartSec=10
Type=notify
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

for (( i=0; i < 3; i++ ))
do
    sed -e "s/##MASTER_NAME##/${MASTER_NAMES[i]}/" -e "s/##MASTER_IP##/${MASTER_IPS[i]}/" kube-apiserver.service.tpl > kube-apiserver-${MASTER_IPS[i]}.service
done
rm -rf kube-apiserver.service.tpl

#################################
# 部署kube-controller-manager   #
#################################

echo "#### Deploy kube-controller-manager ####"

# 创建kube-controller-manager的systemd文件
cat > kube-controller-manager.service <<EOF
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
ExecStart=${K8S_BIN_DIR}/kube-controller-manager \\
  --v=2 \\
  --logtostderr=true \\
  --secure-port=10257 \\
  --bind-address=127.0.0.1 \\
  --profiling \\
  --cluster-name=kubernetes \\
  --controllers=*,bootstrapsigner,tokencleaner \\
  --kube-api-qps=1000 \\
  --kube-api-burst=2000 \\
  --leader-elect \\
  --use-service-account-credentials \\
  --concurrent-service-syncs=2 \\
  --tls-cert-file=${K8S_CERT_DIR}/kube-controller-manager.pem \\
  --tls-private-key-file=${K8S_CERT_DIR}/kube-controller-manager-key.pem \\
  --authentication-kubeconfig=${K8S_CONF_DIR}/kube-controller-manager.kubeconfig \\
  --authorization-kubeconfig=${K8S_CONF_DIR}/kube-controller-manager.kubeconfig \\
  --client-ca-file=${K8S_CERT_DIR}/ca.pem \\
  --requestheader-allowed-names="aggregator" \\
  --requestheader-client-ca-file=${K8S_CERT_DIR}/front-proxy-ca.pem \\
  --requestheader-extra-headers-prefix="X-Remote-Extra-" \\
  --requestheader-group-headers=X-Remote-Group \\
  --requestheader-username-headers=X-Remote-User \\
  --cluster-signing-cert-file=${K8S_CERT_DIR}/ca.pem \\
  --cluster-signing-key-file=${K8S_CERT_DIR}/ca-key.pem \\
  --experimental-cluster-signing-duration=87600h \\
  --horizontal-pod-autoscaler-sync-period=10s \\
  --concurrent-deployment-syncs=10 \\
  --concurrent-gc-syncs=30 \\
  --node-cidr-mask-size=24 \\
  --service-cluster-ip-range=${SERVICE_CIDR} \\
  --cluster-cidr=${CLUSTER_CIDR} \\
  --pod-eviction-timeout=6m \\
  --terminated-pod-gc-threshold=10000 \\
  --root-ca-file=${K8S_CERT_DIR}/ca.pem \\
  --service-account-private-key-file=${K8S_CERT_DIR}/sa.key \\
  --kubeconfig=${K8S_CONF_DIR}/kube-controller-manager.kubeconfig

Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF


#################################
#      部署kube-scheduler       #
#################################

echo "#### Deploy kube-scheduler ####"

cd ${K8S_WORK_CONF_DIR}
## 创建kube-scheduler 配置文件
cat > kube-scheduler.yaml <<EOF
apiVersion: kubescheduler.config.k8s.io/v1beta1
clientConnection:
  acceptContentTypes: ""
  burst: 100
  contentType: application/vnd.kubernetes.protobuf
  kubeconfig: /etc/kubernetes/kube-scheduler.kubeconfig
  qps: 50
enableContentionProfiling: true
enableProfiling: true
healthzBindAddress: 127.0.0.1:10251
kind: KubeSchedulerConfiguration
leaderElection:
  leaderElect: true
  leaseDuration: 15s
  renewDeadline: 10s
  resourceLock: endpointsleases
  resourceName: kube-scheduler
  resourceNamespace: kube-system
  retryPeriod: 2s
metricsBindAddress: 127.0.0.1:10251
percentageOfNodesToScore: 0
podInitialBackoffSeconds: 1
podMaxBackoffSeconds: 10
profiles:
- pluginConfig:
  - args:
      apiVersion: kubescheduler.config.k8s.io/v1beta1
      hardPodAffinityWeight: 1
      kind: InterPodAffinityArgs
    name: InterPodAffinity
  schedulerName: default-scheduler
EOF

cd ${K8S_WORK_SYSTEMD_DIR}
## 创建kube-scheduler的systemd文件
cat > kube-scheduler.service <<EOF
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
ExecStart=${K8S_BIN_DIR}/kube-scheduler \\
  --port=0 \\
  --secure-port=10259 \\
  --bind-address=127.0.0.1 \\
  --config=${K8S_CONF_DIR}/kube-scheduler.yaml \\
  --tls-cert-file=${K8S_CERT_DIR}/kube-scheduler.pem \\
  --tls-private-key-file=${K8S_CERT_DIR}/kube-scheduler-key.pem \\
  --authentication-kubeconfig=${K8S_CONF_DIR}/kube-scheduler.kubeconfig \\
  --client-ca-file=${K8S_CERT_DIR}/ca.pem \\
  --requestheader-allowed-names="aggregator" \\
  --requestheader-client-ca-file=${K8S_CERT_DIR}/front-proxy-ca.pem \\
  --requestheader-extra-headers-prefix="X-Remote-Extra-" \\
  --requestheader-group-headers=X-Remote-Group \\
  --requestheader-username-headers=X-Remote-User \\
  --authorization-kubeconfig=${K8S_CONF_DIR}/kube-scheduler.kubeconfig \\
  --logtostderr=true \\
  --v=2

Restart=always
RestartSec=5
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOF
