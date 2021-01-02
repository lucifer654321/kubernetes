#!/bin/bash
# 2020年12月12日
# Auto Deploy Worker Nodes
# BY: Lucifer
########################################

#################################
#          部署kubelet          #
#################################

if [ ${SCRIPTS_DIR} == "" ];then
        SCRIPTS_DIR=$(cd ..; pwd)
fi
source ${SCRIPTS_DIR}/env/directory_set.sh
K8S_WORK_SYSTEMD_DIR="${WORK_DIR}/service/k8s"
K8S_WORK_CONF_DIR="${WORK_DIR}/conf/k8s"

echo "#### Config kubelet ####"

mkdir -p ${K8S_WORK_SYSTEMD_DIR} ${K8S_WORK_CONF_DIR}

## 创建kubelet.service
cd ${K8S_WORK_SYSTEMD_DIR}
cat > kubelet.service.tpl <<EOF
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
ExecStart=${K8S_BIN_DIR}/kubelet \\
  --bootstrap-kubeconfig=${K8S_CONF_DIR}/kubelet-bootstrap.kubeconfig \\
  --kubeconfig=${K8S_CONF_DIR}/kubelet.kubeconfig \\
  --pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause-amd64:3.2 \\
  --config=${K8S_CONF_DIR}/kubelet-config.yaml \\
  --cert-dir=${K8S_CONF_DIR}/cert \\
  --root-dir=${K8S_DIR}/kubelet \\
  --network-plugin=cni \\
  --cni-conf-dir=${CNI_CONF_DIR} \\
  --cni-bin-dir=${CNI_BIN_DIR} \\
  --image-pull-progress-deadline=15m \\
  --hostname-override=##ALL_NAME## \\
  --node-labels=node.kubernetes.io/node='' \\
  --volume-plugin-dir=${K8S_DIR}/kubelet/kubelet-plugins/volume/exec/ \\
  --logtostderr=true \\
  --v=2

Restart=always
RestartSec=5
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOF

## 
for all_name in ${ALL_NAMES[@]}
do
    echo ">>> ${all_name}"
    sed -e "s/##ALL_NAME##/${all_name}/" kubelet.service.tpl > kubelet-${all_name}.service
done
rm -rf kubelet.service.tpl

cd ${K8S_WORK_CONF_DIR}
## 创建kubelet参数配置文件
cat > kubelet-config.yaml.tpl <<EOF
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
address: "##ALL_IP##"
staticPodPath: ""
syncFrequency: 1m
fileCheckFrequency: 20s
httpCheckFrequency: 20s
staticPodURL: ""
port: 10250
readOnlyPort: 0
rotateCertificates: true
serverTLSBootstrap: true
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
  x509:
    clientCAFile: "${K8S_CERT_DIR}/ca.pem"
authorization:
  mode: Webhook
kubeletCgroups: ""
systemCgroups: ""
cgroupRoot: ""
cgroupsPerQOS: true
cgroupDriver: systemd
clusterDomain: "${CLUSTER_DNS_DOMAIN}"
clusterDNS:
  - "${CLUSTER_DNS_SVC_IP}"
containerLogMaxSize: 20Mi
containerLogMaxFiles: 10
enableDebuggingHandlers: true
enableContentionProfiling: true
enforceNodeAllocatable: ["pods"]
eventRecordQPS: 0
eventBurst: 20
evictionHard:
  imagefs.available: 15%
  memory.available: 100Mi
  nodefs.available: 10%
  nodefs.inodesFree: 5%
hairpinMode: promiscuous-bridge
healthzBindAddress: "##ALL_IP##"
healthzPort: 10248
imageMinimumGCAge: 2m
imageGCHighThresholdPercent: 85
imageGCLowThresholdPercent: 80
maxOpenFiles: 1000000
kubeAPIQPS: 1000
kubeAPIBurst: 2000
maxPods: 220
nodeStatusUpdateFrequency: 10s
nodeStatusReportFrequency: 1m
podPidsLimit: -1
registryPullQPS: 0
registryBurst: 20
resolvConf: /etc/resolv.conf
volumeStatsAggPeriod: 1m
runtimeRequestTimeout: 10m
serializeImagePulls: false
podCIDR: "${CLUSTER_CIDR}"
enableControllerAttachDetach: true
EOF

## 
for all_ip in ${ALL_IPS[@]}
do
    echo ">>> ${all_ip}"
    sed -e "s/##ALL_IP##/${all_ip}/" kubelet-config.yaml.tpl > kubelet-config-${all_ip}.yaml
done
rm -rf kubelet-config.yaml.tpl


#################################
#        部署kube-proxy         #
#################################

K8S_WORK_CONF_DIR="${WORK_DIR}/conf/k8s"
K8S_WORK_SYSTEMD_DIR="${WORK_DIR}/service/k8s"

echo "#### Config kube-proxy ####"

cd ${K8S_WORK_CONF_DIR}
## 创建kube-proxy配置文件
### kube-proxy --write-config-to kube-proxy-config.yaml.tpl
cat > kube-proxy-config.yaml.tpl <<EOF
apiVersion: kubeproxy.config.k8s.io/v1alpha1
bindAddress: ##ALL_IP##
clientConnection:
  acceptContentTypes: ""
  burst: 10
  contentType: application/vnd.kubernetes.protobuf
  kubeconfig: "${K8S_CONF_DIR}/kube-proxy.kubeconfig"
  qps: 5
clusterCIDR: ${CLUSTER_CIDR}
configSyncPeriod: 15m0s
conntrack:
  maxPerCore: 32768
  min: 131072
  tcpCloseWaitTimeout: 1h0m0s
  tcpEstablishedTimeout: 24h0m0s
enableProfiling: false
healthzBindAddress: 127.0.0.1:10256
hostnameOverride: ##ALL_NAME##
iptables:
  masqueradeAll: false
  masqueradeBit: 14
  minSyncPeriod: 1s
  syncPeriod: 30s
ipvs:
  minSyncPeriod: 5s
  scheduler: "rr"
  syncPeriod: 30s
kind: KubeProxyConfiguration
metricsBindAddress: 127.0.0.1:10249
mode: "ipvs"
nodePortAddresses: null
oomScoreAdj: -999
portRange: ""
udpIdleTimeout: 250ms
EOF

for (( i=0; i < 5; i++ ))
do
    echo ">>> ${ALL_NAMES[i]}"
    sed -e "s/##ALL_NAME##/${ALL_NAMES[i]}/" -e "s/##ALL_IP##/${ALL_IPS[i]}/" kube-proxy-config.yaml.tpl > kube-proxy-config-${ALL_NAMES[i]}.yaml
done 
rm -rf kube-proxy-config.yaml.tpl

## 创建kube-proxy.service文件
cd ${K8S_WORK_SYSTEMD_DIR}
cat > kube-proxy.service <<EOF
[Unit]
Description=Kubernetes Kube-Proxy Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
ExecStart=${K8S_BIN_DIR}/kube-proxy \\
  --config=${K8S_CONF_DIR}/kube-proxy-config.yaml \\
  --logtostderr=true \\
  --v=2

Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
