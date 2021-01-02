# Version
docker-19.03.14
etcd-v3.4.13-linux-amd64.tar.gz
kubernetes v1.19.4

# 1. Initialization nodes

```sh
cd ~/deploy_k8s_scripts
sh init_k8s_nodes.sh
```



# 2.Create Kubernetes Cluster Files and Certs

```sh
cd ~/deploy_k8s_scripts
sh deploy_k8s_create_files.sh
```



# 3.Startup Kubernetes Componetes

```sh
cd ~/scriptscd ~/deploy_k8s_scripts
sh deploy_k8s_startup.sh
```



# 4.Deploy Kubernetes Plugins

```sh
cd ~/deploy_k8s_scripts
sh deploy_plugins.sh
```

