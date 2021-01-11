#!/bin/bash

SCRIPTS_DIR=$(cd "$(dirname "$0")"; pwd)
#################################
#        下载 k8s 文件          #
#################################
# download the etcd and kubernetes server pkg

cd ${SCRIPTS_DIR}/create_files
source ./01.deploy_k8s_download_files.sh

#################################
#          部署Docker           #
#################################
cd ${SCRIPTS_DIR}/create_files
# source ./02.deploy_k8s_docker.sh
source ./02.deploy_k8s_docker_src.sh

#################################
#            生成证书           #
#################################
cd ${SCRIPTS_DIR}/create_files
source ./03.deploy_k8s_certs.sh

#################################
#           部署ETCD            #
#################################
cd ${SCRIPTS_DIR}/create_files
source ./04.deploy_k8s_etcd.sh

#################################
#      部署 MASTER NODES        #
#################################
cd ${SCRIPTS_DIR}/create_files
source ./05.deploy_k8s_master.sh

#################################
#   部署 keepalived+haproxy     #
#################################
cd ${SCRIPTS_DIR}/create_files
source ./06.deploy_k8s_ha.sh

#################################
#    TLS Bootstrapping配置      #
#################################
cd ${SCRIPTS_DIR}/create_files
# source ./07.deploy_k8s_bootstrap.sh

#################################
#      部署 WORKER NODES        #
#################################
cd ${SCRIPTS_DIR}/create_files
source ./08.deploy_k8s_worker.sh
