#!/bin/bash
# 2020年12月12日
# Auto SYNC kubernetes bin files to cluster nodes
# BY: Lucifer
##################################################

if [ ${SCRIPTS_DIR} == "" ];then
	SCRIPTS_DIR=$(cd ..; pwd)
fi

#################################
#      同步 k8s 命令文件        #
#################################
# download the etcd and kubernetes server pkg

source ${SCRIPTS_DIR}/env/directory_set.sh

ETCD_Version='v3.4.13'
ETCD_PKG="etcd-${ETCD_Version}-linux-amd64.tar.gz"
ETCD_URL="https://github.com/etcd-io/etcd/releases/download"
K8S_Version='v1.19.4'
K8S_Server_PKG='kubernetes-server-linux-amd64.tar.gz'
K8S_URL="https://dl.k8s.io"


K8S_Bin_Dir="kubernetes/server/bin"
ETCD_Bin_Dir="etcd-v3.4.13-linux-amd64"

mkdir -p ${WORK_DIR}/{src,bin}

echo "#### SYNC K8S command files ####"

# 建议下载后上传


cd ${WORK_DIR}/src

# 建议下载后上传
wget -c -N ${ETCD_URL}/${ETCD_Version}/${ETCD_PKG}
wget -c -N ${K8S_URL}/${K8S_Version}/${K8S_Server_PKG}

# 解压
tar xf ${K8S_Server_PKG} --strip-components=3 -C ${WORK_DIR}/bin ${K8S_Bin_Dir}/kube{adm,ctl,let,-apiserver,-controller-manager,-proxy,-scheduler}
tar xf ${ETCD_PKG} --strip-components=1 -C ${WORK_DIR}/bin ${ETCD_Bin_Dir}/etcd{,ctl}

cp ${WORK_DIR}/bin/kube{adm,ctl} /usr/local/bin
