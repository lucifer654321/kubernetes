#!/bin/bash
# 2020年12月5日
# Auto Create The PKI certificates For K8S Cluster
# By：Lucifer
####################################################

if [ ${SCRIPTS_DIR} == "" ];then
        SCRIPTS_DIR=$(cd ..; pwd)
fi
source ${SCRIPTS_DIR}/env/directory_set.sh
Cert_Dir="${WORK_DIR}/certs"
K8S_WORK_CERT_DIR="${WORK_DIR}/certs/k8s"
ETCD_WORK_CERT_DIR="${WORK_DIR}/certs/etcd"
KUBECONFIG_DIR="${WORK_DIR}/kubeconfig"
CFSSL_BIN_DIR="/usr/local/bin"


mkdir -p ${WORK_DIR}/{certs/{k8s,etcd},kubeconfig,conf/k8s}


#############################
#       下载cfssl软件       #
#############################

CFSSL_URL="https://pkg.cfssl.org/R1.2"
CFSSL_BIN="${CFSSL_BIN_DIR}/cfssl"
CFSSLJSON_BIN="${CFSSL_BIN_DIR}/cfssljson"
CFSSL_CERT_BIN="${CFSSL_BIN_DIR}/cfssl-certinfo"

# 下载cfssl软件
[ -f ${CFSSL_BIN} ] || curl -L ${CFSSL_URL}/cfssl_linux-amd64 -o ${CFSSL_BIN}

# 下载json模板
[ -f ${CFSSLJSON_BIN} ] || curl -L ${CFSSL_URL}/cfssljson_linux-amd64 -o ${CFSSLJSON_BIN}
[ -f ${CFSSL_CERT_BIN} ] || curl -L ${CFSSL_URL}/cfssl-certinfo_linux-amd64 -o ${CFSSL_CERT_BIN}

chmod a+x ${CFSSL_BIN_DIR}/cfssl*

#############################
#       创建CSR文件         #
#############################

echo "######################################################"
echo "#### Create CSR Files with k8s cluster Components ####"
echo "######################################################"
echo
echo

cd ${Cert_Dir}
## 创建etcd-ca-csr.json
echo "#### Create etcd-ca-csr.json ####"
echo

cat > etcd-ca-csr.json <<EOF
{
    "CN": "etcd",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "Shanghai",
            "L": "Shanghai",
            "O": "etcd",
            "OU": "Etcd-manual"
        }
    ],
    "ca": {
        "expiry": "876000h"
    }
}
EOF

## 创建etcd-csr.json
echo "#### Create etcd-csr.json ####"
echo

cat > etcd-csr.json <<EOF
{
    "CN": "etcd",
    "hosts": [
        "127.0.0.1",
        "${MASTER_NAMES[0]}",
        "${MASTER_NAMES[1]}",
        "${MASTER_NAMES[2]}",
        "${MASTER_IPS[0]}",
        "${MASTER_IPS[1]}",
        "${MASTER_IPS[2]}"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "Shanghai",
            "L": "Shanghai",
            "O": "etcd",
            "OU": "Etcd-manual"
        }
    ]
}
EOF

## 创建ca-config.json
echo "#### Create ca-config.json ####"
echo

cat > ca-config.json <<EOF
{
    "signing": {
        "default": {
            "expiry": "876000h"
        },
        "profiles": {
            "kubernetes": {
                "expiry": "876000h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            }
        }
    }
}
EOF

## 创建ca-csr.json
echo "#### Create ca-csr.json ####"
echo

cat > ca-csr.json <<EOF
{
    "CN": "kubernetes",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "Shanghai",
            "L": "Shanghai",
            "O": "Kubernetes",
            "OU": "Kubernetes-manual"
        }
    ],
    "ca": {
        "expiry": "876000h"
    }
}
EOF


## 创建admin-csr.json(kubectl)
echo "#### Create admin-csr.json (kubectl) ####"
echo

cat > admin-csr.json <<EOF
{
    "CN": "admin",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "Shanghai",
            "L": "Shanghai",
            "O": "system:masters",
            "OU": "Kubernetes-manual"
        }
    ]
}
EOF


## 创建apiserver-csr.json
echo "#### Create kube-apiserver-csr.json ####"
echo


cat > kube-apiserver-csr.json <<EOF
{
  "CN": "kube-apiserver",
  "hosts": [
    "127.0.0.1",
    "${MASTER_IPS[0]}",
    "${MASTER_IPS[1]}",
    "${MASTER_IPS[2]}",
    "${VIP}",
    "${CLUSTER_KUBERNETES_SVC_IP}",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "Shanghai",
      "L": "Shanghai",
      "O": "Kubernetes",
      "OU": "Kubernetes-manual"
    }
  ]
}
EOF


## 创建front-proxy-ca-csr.json(apiserver聚合)
echo "#### Create front-proxy-ca-csr.json(apiserver聚合) ####"
echo

cat > front-proxy-ca-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
     "algo": "rsa",
     "size": 2048
  }
}
EOF


## 创建front-proxy-client-csr.json(apiserver聚合)
echo "#### Create front-proxy-client-csr.json(apiserver聚合) ####"
echo

cat > front-proxy-client-csr.json <<EOF
{
  "CN": "aggregator",
  "key": {
     "algo": "rsa",
     "size": 2048
  }
}
EOF


## 创建kube-controller-manager-csr.json
echo "#### Create kube-controller-manager-csr.json ####"
echo

cat > kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "hosts": [
    "127.0.0.1",
    "${MASTER_IPS[0]}",
    "${MASTER_IPS[1]}",
    "${MASTER_IPS[2]}",
	"${VIP}"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "Shanghai",
      "L": "Shanghai",
      "O": "system:kube-controller-manager",
      "OU": "Kubernetes-manual"
    }
  ]
}
EOF


## 创建kube-scheduler-csr.json
echo "#### Create kube-scheduler-csr.json ####"
echo

cat > kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "hosts": [
    "127.0.0.1",
    "${MASTER_IPS[0]}",
    "${MASTER_IPS[1]}",
    "${MASTER_IPS[2]}",
	"${VIP}"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "Shanghai",
      "L": "Shanghai",
      "O": "system:kube-scheduler",
      "OU": "Kubernetes-manual"
    }
  ]
}
EOF


## 创建kube-proxy-csr.json
echo "#### Create kube-proxy-csr.json ####"
echo

cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "Shanghai",
      "L": "Shanghai",
      "O": "system:kube-proxy",
      "OU": "Kubernetes-manual"
    }
  ]
}
EOF


#############################
#       创建PEM证书         #
#############################

K8S_COMPONENTES=(etcd admin kube-apiserver kube-controller-manager kube-scheduler kube-proxy front-proxy)
CONFIG="${Cert_Dir}/ca-config.json"


echo "######################################################"
echo "#### Create PEM Files with k8s cluster Components ####"
echo "######################################################"
echo
echo

for COM in ${K8S_COMPONENTES[@]}
do
	if [ $COM == "etcd" ];then
		[ -f "${ETCD_WORK_CERT_DIR}/etcd-ca.pem" ] && F_CODE=0 || F_CODE=1
		CA_CSR="${Cert_Dir}/${COM}-ca-csr.json"
		CA_PEM_NAME="${ETCD_WORK_CERT_DIR}/${COM}-ca"
		CA="${ETCD_WORK_CERT_DIR}/${COM}-ca.pem"
		CA_KEY="${ETCD_WORK_CERT_DIR}/${COM}-ca-key.pem"
		CSR_JSON="${Cert_Dir}/${COM}-csr.json"
		PEM_NAME="${ETCD_WORK_CERT_DIR}/${COM}"
	elif [ $COM  == "front-proxy" ];then
		[ -f "${K8S_WORK_CERT_DIR}/front-proxy-ca.pem" ] && F_CODE=0 || F_CODE=1
		CA_CSR="${Cert_Dir}/${COM}-ca-csr.json"
		CA_PEM_NAME="${K8S_WORK_CERT_DIR}/${COM}-ca"
		CA="${K8S_WORK_CERT_DIR}/${COM}-ca.pem"
		CA_KEY="${K8S_WORK_CERT_DIR}/${COM}-ca-key.pem"
		CSR_JSON="${Cert_Dir}/${COM}-client-csr.json"
		PEM_NAME="${K8S_WORK_CERT_DIR}/${COM}-client"
	else
		[ -f "${K8S_WORK_CERT_DIR}/ca.pem" ] && F_CODE=0 || F_CODE=1
		CA_CSR="${Cert_Dir}/ca-csr.json"
		CA_PEM_NAME="${K8S_WORK_CERT_DIR}/ca"
		CA="${K8S_WORK_CERT_DIR}/ca.pem"
		CA_KEY="${K8S_WORK_CERT_DIR}/ca-key.pem"
		CSR_JSON="${Cert_Dir}/${COM}-csr.json"
		PEM_NAME="${K8S_WORK_CERT_DIR}/${COM}"
	fi

	# 判断各类CA证书是否存在，不存在则创建
	if [ ${F_CODE} -ne 0 ];then
		cfssl gencert -initca ${CA_CSR} | cfssljson -bare ${CA_PEM_NAME} &> /dev/null
		[ $? ] && echo -e "\n\n#######################\nCreate ${CA_PEM_NAME} Done!\n#######################\n\n"
	fi
	
	# 生成个组件证书
	echo ${PEM_NAME}
	cfssl gencert \
		-ca=${CA} \
		-ca-key=${CA_KEY} \
		-config=${CONFIG} \
		-profile=kubernetes ${CSR_JSON} | cfssljson -bare ${PEM_NAME} &> /dev/null
	[ $? ] && echo -e "\n\n###########################\n#### Create $COM Done! ####\n###########################\n\n"
done

####################################
#       创建kubeconfig证书         #
####################################

KUBE_COMPONENTES=(kubectl kube-controller-manager kube-scheduler kube-proxy)
CLUSTER_NAME="kubernetes"

echo "############################################################"
echo "#### Create kubeconfig Files with k8s master Components ####"
echo "############################################################"
echo
echo

cd ${KUBECONFIG_DIR}
for COM in ${KUBE_COMPONENTES[@]}
do
	if [ ${COM} == "kubectl" ];then
		PEM_NAME="admin"
		USER_NAME="admin"
	else
		PEM_NAME=${COM}
		USER_NAME="system:${COM}"
	fi

	# 设置集群项
	kubectl config set-cluster ${CLUSTER_NAME} \
	  --certificate-authority=${K8S_WORK_CERT_DIR}/ca.pem \
	  --embed-certs=true \
	  --server=${KUBE_APISERVER} \
	  --kubeconfig=${PEM_NAME}.kubeconfig

	# 设置用户项
	kubectl config set-credentials ${USER_NAME} \
	  --client-certificate=${K8S_WORK_CERT_DIR}/${PEM_NAME}.pem \
	  --client-key=${K8S_WORK_CERT_DIR}/${PEM_NAME}-key.pem \
	  --embed-certs=true \
	  --kubeconfig=${PEM_NAME}.kubeconfig

	# 设置环境项
	kubectl config set-context ${USER_NAME}@${CLUSTER_NAME} \
	  --cluster=${CLUSTER_NAME} \
	  --user=${USER_NAME} \
	  --kubeconfig=${PEM_NAME}.kubeconfig

	# 设置默认上下文
	kubectl config use-context ${USER_NAME}@${CLUSTER_NAME} \
  	  --kubeconfig=${PEM_NAME}.kubeconfig
done


####################################
#           创建SA密钥             #
####################################

echo "############################################################"
echo "####    Create SA Files with k8s master Components      ####"
echo "############################################################"
echo
echo

openssl genrsa -out ${K8S_WORK_CERT_DIR}/sa.key 2048
openssl rsa -in ${K8S_WORK_CERT_DIR}/sa.key -pubout -out ${K8S_WORK_CERT_DIR}/sa.pub

rm -rf ${K8S_WORK_CERT_DIR}/*.csr ${ETCD_WORK_CERT_DIR}/*.csr ${Cert_Dir}/*-csr.json 


####################################
#       创建加密配置文件           #
####################################

cd ${WORK_DIR}/conf/k8s
echo "############################################################"
echo "####              Create encryption-config              ####"
echo "############################################################"
echo
echo

cat > encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF


####################################
#       创建审计策略文件           #
####################################
echo "############################################################"
echo "####              Create audit-policy.yaml              ####"
echo "############################################################"
echo
echo

cat > audit-policy.yaml <<EOF
apiVersion: audit.k8s.io/v1beta1
kind: Policy
rules:
  # The following requests were manually identified as high-volume and low-risk, so drop them.
  - level: None
    resources:
      - group: ""
        resources:
          - endpoints
          - services
          - services/status
    users:
      - 'system:kube-proxy'
    verbs:
      - watch

  - level: None
    resources:
      - group: ""
        resources:
          - nodes
          - nodes/status
    userGroups:
      - 'system:nodes'
    verbs:
      - get

  - level: None
    namespaces:
      - kube-system
    resources:
      - group: ""
        resources:
          - endpoints
    users:
      - 'system:kube-controller-manager'
      - 'system:kube-scheduler'
      - 'system:serviceaccount:kube-system:endpoint-controller'
    verbs:
      - get
      - update

  - level: None
    resources:
      - group: ""
        resources:
          - namespaces
          - namespaces/status
          - namespaces/finalize
    users:
      - 'system:apiserver'
    verbs:
      - get

  # Don't log HPA fetching metrics.
  - level: None
    resources:
      - group: metrics.k8s.io
    users:
      - 'system:kube-controller-manager'
    verbs:
      - get
      - list

  # Don't log these read-only URLs.
  - level: None
    nonResourceURLs:
      - '/healthz*'
      - /version
      - '/swagger*'

  # Don't log events requests.
  - level: None
    resources:
      - group: ""
        resources:
          - events

  # node and pod status calls from nodes are high-volume and can be large, don't log responses for expected updates from nodes
  - level: Request
    omitStages:
      - RequestReceived
    resources:
      - group: ""
        resources:
          - nodes/status
          - pods/status
    users:
      - kubelet
      - 'system:node-problem-detector'
      - 'system:serviceaccount:kube-system:node-problem-detector'
    verbs:
      - update
      - patch

  - level: Request
    omitStages:
      - RequestReceived
    resources:
      - group: ""
        resources:
          - nodes/status
          - pods/status
    userGroups:
      - 'system:nodes'
    verbs:
      - update
      - patch

  # deletecollection calls can be large, don't log responses for expected namespace deletions
  - level: Request
    omitStages:
      - RequestReceived
    users:
      - 'system:serviceaccount:kube-system:namespace-controller'
    verbs:
      - deletecollection

  # Secrets, ConfigMaps, and TokenReviews can contain sensitive & binary data,
  # so only log at the Metadata level.
  - level: Metadata
    omitStages:
      - RequestReceived
    resources:
      - group: ""
        resources:
          - secrets
          - configmaps
      - group: authentication.k8s.io
        resources:
          - tokenreviews
  # Get repsonses can be large; skip them.
  - level: Request
    omitStages:
      - RequestReceived
    resources:
      - group: ""
      - group: admissionregistration.k8s.io
      - group: apiextensions.k8s.io
      - group: apiregistration.k8s.io
      - group: apps
      - group: authentication.k8s.io
      - group: authorization.k8s.io
      - group: autoscaling
      - group: batch
      - group: certificates.k8s.io
      - group: extensions
      - group: metrics.k8s.io
      - group: networking.k8s.io
      - group: policy
      - group: rbac.authorization.k8s.io
      - group: scheduling.k8s.io
      - group: settings.k8s.io
      - group: storage.k8s.io
    verbs:
      - get
      - list
      - watch

  # Default level for known APIs
  - level: RequestResponse
    omitStages:
      - RequestReceived
    resources:
      - group: ""
      - group: admissionregistration.k8s.io
      - group: apiextensions.k8s.io
      - group: apiregistration.k8s.io
      - group: apps
      - group: authentication.k8s.io
      - group: authorization.k8s.io
      - group: autoscaling
      - group: batch
      - group: certificates.k8s.io
      - group: extensions
      - group: metrics.k8s.io
      - group: networking.k8s.io
      - group: policy
      - group: rbac.authorization.k8s.io
      - group: scheduling.k8s.io
      - group: settings.k8s.io
      - group: storage.k8s.io

  # Default level for all other requests.
  - level: Metadata
    omitStages:
      - RequestReceived
EOF
