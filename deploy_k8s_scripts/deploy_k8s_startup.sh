#!/bin/bash
# 2020年12月30日
# Auto Distribut The K8S Components and Startup
# By: Lucifer
#################################################

if [ ${SCRIPTS_DIR} == "" ];then
        SCRIPTS_DIR=$(cd ..; pwd)
fi
source ${SCRIPTS_DIR}/env/directory_set.sh
WORKER_NAMES=${ALL_NAMES[@]}

# Distribut Bin files
echo "#### Distribut Bin files ####"
cd ${WORK_DIR}/bin
for i in ${MASTER_NAMES[@]}
do
	echo ">>> $i"
	scp etcd{,ctl} $i:${K8S_BIN_DIR}
	scp kube{ctl,adm,-apiserver,-controller-manager,-scheduler} $i:${K8S_BIN_DIR}
done

for i in ${WORKER_NAMES[@]}
do
	echo ">>> $i"
	ssh $i "systemctl stop docker &> /dev/null"
	ssh $i "yum remove -y docker* ; rm -rf ${DOCKER_DIR} ${DOCKER_CONF_DIR} ${K8S_BIN_DIR}/docker* ${SYSTEMD_DIR}/docker.service"
	scp docker/* $i:${K8S_BIN_DIR}
	scp kube{let,-proxy} $i:${K8S_BIN_DIR}
done

# Distribut Certs
echo "#### Distribut Certs files ####"
cd ${WORK_DIR}/certs
for i in ${MASTER_NAMES[@]}
do
	echo ">>> $i"
	ssh $i "mkdir -p ${ETCD_CERT_DIR} ${K8S_CERT_DIR}"
	scp etcd/* $i:${ETCD_CERT_DIR}
	scp k8s/* $i:${K8S_CERT_DIR}
  	scp ${WORK_DIR}/kubeconfig/{admin,kube-{controller-manager,scheduler}}.kubeconfig $i:${K8S_CONF_DIR}
	ssh $i "mkdir -p /root/.kube && \cp ${K8S_CONF_DIR}/admin.kubeconfig /root/.kube/config"
done

for i in ${WORKER_NAMES[@]}
do
	echo ">>> $i"
	ssh $i "mkdir -p ${K8S_CERT_DIR}"
	scp k8s/{ca.pem,kube-proxy*.pem} $i:${K8S_CERT_DIR}
	scp ${WORK_DIR}/kubeconfig/kube-proxy.kubeconfig $i:${K8S_CONF_DIR}
done

# Distribut and Startup Docker
cd ${WORK_DIR}
echo "#### Distribut and Startup Docker ####"
for i in ${WORKER_NAMES[@]}
do
        echo ">>> $i"
        ssh $i "mkdir -p ${DOCKER_CONF_DIR}"
	scp service/docker/docker.service $i:${SYSTEMD_DIR}
	scp conf/docker/docker-daemon.json $i:${DOCKER_CONF_DIR}/daemon.json
	ssh $i "systemctl daemon-reload && systemctl enable --now docker"
done

echo ">>> Check Docker Status <<<"
for i in ${WORKER_NAMES[@]}
do
	echo ">>> $i"
	ssh $i "docker info"
	sleep 3
done

# Distribut and Startup ETCD
cd ${WORK_DIR}
echo "#### Distribut and Startup ETCD ####"
for i in ${MASTER_IPS[@]}
do
        echo ">>> $i"
	ssh $i "mkdir -p ${ETCD_DATA_DIR}"
        scp service/etcd/etcd-${i}.service $i:${SYSTEMD_DIR}/etcd.service
        ssh $i "systemctl daemon-reload && systemctl enable --now etcd"
done

echo ">>> Check ETCD Status <<<"
ETCDCTL_API=3 etcdctl \
	--endpoints="${ETCD_ENDPOINTS}" \
	--cacert=${ETCD_CERT_DIR}/etcd-ca.pem \
	--cert=${ETCD_CERT_DIR}/etcd.pem \
	--key=${ETCD_CERT_DIR}/etcd-key.pem endpoint status -w table
sleep 2

# Distribut and Startup Kube-apiserver
cd ${WORK_DIR}
echo "#### Distribut and Startup kube-apiserver ####"
for i in ${MASTER_IPS[@]}
do
        echo ">>> $i"
	ssh $i "mkdir -p ${K8S_DIR}/kube-apiserver"
	scp service/k8s/kube-apiserver-${i}.service $i:${SYSTEMD_DIR}/kube-apiserver.service
	scp conf/k8s/{audit-policy,encryption-config}.yaml $i:${K8S_CONF_DIR}
        ssh $i "systemctl daemon-reload && systemctl enable --now kube-apiserver"
done

echo ">>> Check kube-apiserver Status <<<"
for i in ${MASTER_NAMES[@]}
do
        echo ">>> $i"
	ssh $i "systemctl status kube-apiserver|grep Active"
	sleep 3
done

# Distribut and Startup HA
cd ${SCRIPTS_DIR}/startup
source ./61.Install_K8SHA_KH.sh

# Distribut and Startup Kube-controller-manager
cd ${WORK_DIR}
echo "#### Distribut and Startup kube-controller-manager ####"
for i in ${MASTER_IPS[@]}
do
        echo ">>> $i"
        ssh $i "mkdir -p ${K8S_DIR}/kube-controller-manager"
        scp service/k8s/kube-controller-manager.service $i:${SYSTEMD_DIR}
        ssh $i "systemctl daemon-reload && systemctl enable --now kube-controller-manager"
done

echo ">>> Check kube-controller-manager Status <<<"
for i in ${MASTER_NAMES[@]}
do
        echo ">>> $i"
        ssh $i "systemctl status kube-controller-manager|grep Active"
        sleep 3
done

# Distribut and Startup Kube-scheduler
cd ${WORK_DIR}
echo "#### Distribut and Startup kube-scheduler ####"
for i in ${MASTER_IPS[@]}
do
        echo ">>> $i"
        ssh $i "mkdir -p ${K8S_DIR}/kube-scheduler"
        scp service/k8s/kube-scheduler.service $i:${SYSTEMD_DIR}
	scp conf/k8s/kube-scheduler.yaml $i:${K8S_CONF_DIR}
        ssh $i "systemctl daemon-reload && systemctl enable --now kube-scheduler"
done

echo ">>> Check kube-scheduler Status <<<"
for i in ${MASTER_NAMES[@]}
do
        echo ">>> $i"
        ssh $i "systemctl status kube-scheduler|grep Active"
        sleep 3
done

# Create TLS Bootstrapping
cd ${SCRIPTS_DIR}/startup
source ./70.deploy_k8s_bootstrap.sh

# Distribut and Startup Kubelet
cd ${WORK_DIR}
echo "#### Distribut and Startup kubelet ####"
for (( i=0; i < 5; i++ ))
do
        echo ">>> ${ALL_NAMES[i]}"
		ssh ${ALL_NAMES[i]} "mkdir -p /etc/cni/net.d/ /opt/cni/bin/"
        scp service/k8s/kubelet-${ALL_NAMES[i]}.service ${ALL_NAMES[i]}:${SYSTEMD_DIR}/kubelet.service
        scp conf/k8s/kubelet-config-${ALL_IPS[i]}.yaml ${ALL_NAMES[i]}:${K8S_CONF_DIR}/kubelet-config.yaml
        ssh ${ALL_NAMES[i]} "systemctl daemon-reload && systemctl enable --now kubelet"
done

echo ">>> Check kubelet Status <<<"
for i in ${ALL_NAMES[@]}
do
        echo ">>> $i"
        ssh $i "systemctl status kubelet|grep Active"
        sleep 3
done

kubectl get nodes
sleep 4

# Distribut and Startup Kube-proxy
cd ${WORK_DIR}
echo "#### Distribut and Startup kube-proxy ####"
for i in ${ALL_NAMES[@]}
do
        echo ">>> ${i}"
        scp service/k8s/kube-proxy.service ${i}:${SYSTEMD_DIR}
        scp conf/k8s/kube-proxy-config-${i}.yaml ${i}:${K8S_CONF_DIR}/kube-proxy-config.yaml
        ssh $i "systemctl daemon-reload && systemctl enable --now kube-proxy"
done

echo ">>> Check kube-proxy Status <<<"
for i in ${ALL_NAMES[@]}
do
        echo ">>> $i"
        ssh $i "systemctl status kube-proxy|grep Active"
        sleep 3
done
