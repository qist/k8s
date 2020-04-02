#!/bin/bash
#export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/usr/local/sbin:root/bin"
#################################################################################################################################################
################docker:        wget https://download.docker.com/linux/static/stable/x86_64/docker-19.03.7.tgz
################lxcfs:         wget https://github.com/qist/lxcfs/releases/download/3.1.2/lxcfs-3.1.2.tar.gz 
################cni:           wget https://github.com/containernetworking/plugins/releases/download/v0.8.5/cni-plugins-linux-amd64-v0.8.5.tgz
################etcd:          wget https://github.com/etcd-io/etcd/releases/download/v3.4.4/etcd-v3.4.4-linux-amd64.tar.gz
################kubernetes:    wget https://storage.googleapis.com/kubernetes-release/release/v1.15.10/kubernetes-server-linux-amd64.tar.gz
################haproxy:       wget https://www.haproxy.org/download/2.1/src/haproxy-2.1.1.tar.gz
################automake:      wget https://ftp.gnu.org/gnu/automake/automake-1.15.1.tar.gz
################keepalived:    wget https://www.keepalived.org/software/keepalived-2.0.19.tar.gz
################iptables:      wget https://www.netfilter.org/projects/iptables/files/iptables-1.8.4.tar.bz2
##################################################################################################################################################
##################################################################################################################################################
###############cfssl签名工具下载  wget https://github.com/qist/lxcfs/releases/download/cfssl/cfssl.tar.gz # 解压二进制放到/usr/bin 目录
###############kubectl下载  https://storage.googleapis.com/kubernetes-release/release/v1.15.7/kubernetes-client-linux-amd64.tar.gz 解压到/usr/bin
############### ansible 安装 dnf -y install ansible ##yum -y install ansible ##apt -y install ansible
############### 记得修改下面的配置参数！！！！！！！！
##################################################################################################################################################
# 检查是否安装 cffsl 与 kubectl
which kubectl
if [ $? -ne 0  ];then
echo "download kubectl"
exit
fi 
which cfssl
if [ $? -ne 0  ];then
echo "download cfssl"
exit
fi 
# 应用部署目录
TOTAL_PATH=/apps
ETCD_PATH=$TOTAL_PATH/etcd
# 大规模集群部署时建议分开存储，WAL 最好ssd
ETCD_DATA_DIR=$TOTAL_PATH/etcd/data/default.etcd
ETCD_WAL_DIR=$TOTAL_PATH/etcd/data/default.etcd
K8S_PATH=$TOTAL_PATH/k8s
POD_MANIFEST_PATH=$TOTAL_PATH/work
DOCKER_PATH=$TOTAL_PATH/docker
#DOCKER_BIN_PATH=$TOTAL_PATH/docker/bin #ubuntu 18 版本必须设置在/usr/bin 目录下面
DOCKER_BIN_PATH=/usr/bin
CNI_PATH=$TOTAL_PATH/cni
SOURCE_PATH=/usr/local/src # 远程服务器源码存放目录
KEEPALIVED_PATH=$TOTAL_PATH/keepalived
HAPROXY_PATH=$TOTAL_PATH/haproxy
# 设置工作端目录
HOST_PATH=`pwd`
# 设置工作端压缩包所在目录
TEMP_PATH=/tmp
#应用版本号
ETCD_VERSION=v3.4.4
K8S_VERSION=v1.15.10
LXCFS_VERSION=3.1.2
DOCKER_VERSION=19.03.7
CNI_VERSION=v0.8.5
IPTABLES_VERSION=1.8.4 #centos7,ubuntu18,centos8 版本需要升级 ubuntu19 不用升级
KEEPALIVED_VERSION=2.0.19
AUTOMAKE_VERSION=1.15.1 #KEEPALIVED 编译依赖使用
HAPROXY_VERSION=2.1.1
# 网络插件 选择 1、kube-router 2、kube-proxy+flannel
NET_PLUG=1
# 节点间互联网络接口名称flannel 指定网络接口
IFACE="eth0"
# K8S api 网络互联接口 多网卡请指定接口ansible_网卡接口名字.ipv4.address
API_IPV4=ansible_default_ipv4.address
# kubelet pod 网络互联接口 ansible_${IFACE}.ipv4.address 单网卡使用ansible_default_ipv4.address 多个网卡请指定使用的网卡名字
KUBELET_IPV4=ansible_default_ipv4.address 
# 证书相关配置
CERT_ST="GuangDong"
CERT_L="GuangZhou"
CERT_O="k8s"
CERT_OU="Qist"
CERT_PROFILE="kubernetes"
#数字证书时间及kube-controller-manager 签发证书时间
EXPIRY_TIME="87600h"
# K8S ETCD存储 目录名字
ETCD_PREFIX="/registry" 
# 配置etcd集群参数
#ETCD_SERVER_HOSTNAMES="\"k8s-master-01\",\"k8s-master-02\",\"k8s-master-03\""
#ETCD_SERVER_IPS="\"192.168.2.247\",\"192.168.2.248\",\"192.168.2.249\""
ETCD_MEMBER_1_IP="192.168.2.247"
ETCD_MEMBER_1_HOSTNAMES="k8s-master-01"
ETCD_MEMBER_2_IP="192.168.2.248"
ETCD_MEMBER_2_HOSTNAMES="k8s-master-02"
ETCD_MEMBER_3_IP="192.168.2.249"
ETCD_MEMBER_3_HOSTNAMES="k8s-master-03"
ETCD_SERVER_HOSTNAMES="\"${ETCD_MEMBER_1_HOSTNAMES}\",\"${ETCD_MEMBER_2_HOSTNAMES}\",\"${ETCD_MEMBER_3_HOSTNAMES}\""
ETCD_SERVER_IPS="\"${ETCD_MEMBER_1_IP}\",\"${ETCD_MEMBER_2_IP}\",\"${ETCD_MEMBER_3_IP}\""
# etcd 集群间通信的 IP 和端口
INITIAL_CLUSTER="${ETCD_MEMBER_1_HOSTNAMES}=https://${ETCD_MEMBER_1_IP}:2380,${ETCD_MEMBER_2_HOSTNAMES}=https://${ETCD_MEMBER_2_IP}:2380,${ETCD_MEMBER_3_HOSTNAMES}=https://${ETCD_MEMBER_3_IP}:2380"
# etcd 集群服务地址列表
ENDPOINTS=https://${ETCD_MEMBER_1_IP}:2379,https://${ETCD_MEMBER_2_IP}:2379,https://${ETCD_MEMBER_3_IP}:2379
#K8S events 存储ETCD 集群 1开启 默认关闭0
K8S_EVENTS=0
if [ ${K8S_EVENTS} == 1 ]; then
# etcd events集群配置
#ETCD_EVENTS_HOSTNAMES="\"k8s-node-01\",\"k8s-node-02\",\"k8s-node-03\""
#ETCD_EVENTS_IPS="\"192.168.2.250\",\"192.168.2.251\",\"192.168.2.252\""
ETCD_EVENTS_MEMBER_1_IP="192.168.2.250"
ETCD_EVENTS_MEMBER_1_HOSTNAMES="k8s-node-01"
ETCD_EVENTS_MEMBER_2_IP="192.168.2.251"
ETCD_EVENTS_MEMBER_2_HOSTNAMES="k8s-node-02"
ETCD_EVENTS_MEMBER_3_IP="192.168.2.252"
ETCD_EVENTS_MEMBER_3_HOSTNAMES="k8s-node-03"
ETCD_EVENTS_HOSTNAMES="\"${ETCD_EVENTS_MEMBER_1_HOSTNAMES}\",\"${ETCD_EVENTS_MEMBER_2_HOSTNAMES}\",\"${ETCD_EVENTS_MEMBER_3_HOSTNAMES}\""
ETCD_EVENTS_IPS="\"${ETCD_EVENTS_MEMBER_1_IP}\",\"${ETCD_EVENTS_MEMBER_2_IP}\",\"${ETCD_EVENTS_MEMBER_3_IP}\""
# etcd 集群间通信的 IP 和端口
INITIAL_EVENTS_CLUSTER="${ETCD_EVENTS_MEMBER_1_HOSTNAMES}=https://${ETCD_EVENTS_MEMBER_1_IP}:2380,${ETCD_EVENTS_MEMBER_2_HOSTNAMES}=https://${ETCD_EVENTS_MEMBER_2_IP}:2380,${ETCD_EVENTS_MEMBER_3_HOSTNAMES}=https://${ETCD_EVENTS_MEMBER_3_IP}:2380"
ENDPOINTS="${ENDPOINTS} --etcd-servers-overrides=/events#https://${ETCD_EVENTS_MEMBER_1_IP}:2379;https://${ETCD_EVENTS_MEMBER_2_IP}:2379;https://${ETCD_EVENTS_MEMBER_3_IP}:2379"
fi
#是否开启docker0 网卡 参数: doakcer0 none k8s集群建议不用开启，单独部署请设置值为docker0
NET_BRIDGE="none"
# 配置K8S集群参数
# 最好使用 当前未用的网段 来定义服务网段和 Pod 网段
# 服务网段，部署前路由不可达，部署后集群内路由可达(kube-proxy 保证)
SERVICE_CIDR="10.66.0.0/16"
# Pod 网段，建议 /12 段地址，部署前路由不可达，部署后集群内路由可达(网络插件 保证)
CLUSTER_CIDR="10.80.0.0/12"
# 服务端口范围 (NodePort Range)
NODE_PORT_RANGE="30000-65535"
# kubernetes 服务 IP (一般是 SERVICE_CIDR 中第一个IP)
CLUSTER_KUBERNETES_SVC_IP="10.66.0.1"
# 集群名字
CLUSTER_NAME=kubernetes
#集群域名
CLUSTER_DNS_DOMAIN="cluster.local"
#集群DNS
CLUSTER_DNS_SVC_IP="10.66.0.2"
# k8s vip ip
K8S_VIP_1_IP="192.168.3.12"
K8S_VIP_2_IP="192.168.3.13"
K8S_VIP_3_IP="192.168.3.14"
K8S_VIP_DOMAIN="api.k8s.niuke.tech"
#kube-apiserver port
SECURE_PORT=5443
# kube-apiserver vip port # 如果配置vip IP 请设置
K8S_VIP_PORT=6443
# kube-apiserver vip ip
KUBE_APISERVER="https://${K8S_VIP_DOMAIN}:${K8S_VIP_PORT}"
# RUNTIME_CONFIG v1.16 版本设置 低于v1.16 RUNTIME_CONFIG="api/all=true" 即可
RUNTIME_CONFIG="api/all=true"
#开启插件enable-admission-plugins #AlwaysPullImages 启用istio 不能自动注入需要手动执行注入
ENABLE_ADMISSION_PLUGINS="DefaultStorageClass,DefaultTolerationSeconds,LimitRanger,NamespaceExists,NamespaceLifecycle,NodeRestriction,OwnerReferencesPermissionEnforcement,PodNodeSelector,PersistentVolumeClaimResize,PodPreset,PodTolerationRestriction,ResourceQuota,ServiceAccount,StorageObjectInUseProtection,MutatingAdmissionWebhook,ValidatingAdmissionWebhook"
#禁用插件disable-admission-plugins 
DISABLE_ADMISSION_PLUGINS="DenyEscalatingExec,ExtendedResourceToleration,ImagePolicyWebhook,LimitPodHardAntiAffinityTopology,NamespaceAutoProvision,Priority,EventRateLimit,PodSecurityPolicy"
# 设置api 副本数
APISERVER_COUNT="3"
# 设置输出日志级别
LEVEL_LOG="2"
# api 突变请求最大数
MAX_MUTATING_REQUESTS_INFLIGHT="500"
# api 非突变请求的最大数目
MAX_REQUESTS_INFLIGHT="1500"
# 内存配置选项和node数量的关系，单位是MB： target-ram-mb=node_nums * 60
TARGET_RAM_MB="6000"
# kube-api-qps 默认50
KUBE_API_QPS="100"
#kube-api-burst 默认30
KUBE_API_BURST="100"
# pod-infra-container-image 地址
POD_INFRA_CONTAINER_IMAGE="docker.io/juestnow/pause-amd64:3.1"
# max-pods node 节点启动最多pod 数量
MAX_PODS=100
#每1核cpu最多运行pod数 默认0 关闭 
PODS_PER_CORE=0
# 生成 EncryptionConfig 所需的加密 key
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
#kube-apiserver 服务器IP列表 有更多的节点时请添加IP K8S_APISERVER_VIP="\"192.168.2.247\",\"192.168.2.248\",\"192.168.2.249\",\"192.168.2.250\",\"192.168.2.251\""
K8S_APISERVER_VIP="\"192.168.2.247\",\"192.168.2.248\",\"192.168.2.249\""
# 创建bootstrap配置
TOKEN_ID=$(head -c 16 /dev/urandom | od -An -t x | tr -dc a-f3-9|cut -c 1-6)
TOKEN_SECRET=$(head -c 16 /dev/urandom | md5sum | head -c 16)
BOOTSTRAP_TOKEN=${TOKEN_ID}.${TOKEN_SECRET}
#######################################################################################################################################################################
########################                                      以上参数请详细查看并修改                                              ###################################
#######################################################################################################################################################################
# 创建证书签发配置
# 删除旧数据
#rm -rf ${HOST_PATH}/cfssl
# 创建etcd K8S 证书json 存放目录
mkdir -p ${HOST_PATH}/cfssl/{k8s,etcd}
# 创建签发证书存放目录
mkdir -p ${HOST_PATH}/cfssl/pki/{k8s,etcd}
# CA 配置文件用于配置根证书的使用场景 (profile) 和具体参数 (usage，过期时间、服务端认证、客户端认证、加密等)，后续在签名其它证书时需要指定特定场景。
cat << EOF | tee ${HOST_PATH}/cfssl/ca-config.json
{
  "signing": {
    "default": {
      "expiry": "${EXPIRY_TIME}"
    },
    "profiles": {
      "${CERT_PROFILE}": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "${EXPIRY_TIME}"
      }
    }
  }
}
EOF
# 创建 ETCD CA 配置文件
cat << EOF | tee ${HOST_PATH}/cfssl/etcd/etcd-ca-csr.json
{
    "CN": "etcd",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "$CERT_ST",
            "L": "$CERT_L",
            "O": "$CERT_O",
            "OU": "$CERT_OU"
    }
  ],
    "ca": {
        "expiry": "${EXPIRY_TIME}"
    }
}
EOF
# 创建 ETCD Server 配置文件
cat << EOF | tee ${HOST_PATH}/cfssl/etcd/etcd-server.json
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    ${ETCD_SERVER_IPS},
    ${ETCD_SERVER_HOSTNAMES}
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
            "C": "CN",
            "ST": "$CERT_ST",
            "L": "$CERT_L",
            "O": "$CERT_O",
            "OU": "$CERT_OU"
    }
  ]
}
EOF
# 创建 ETCD Member 1 配置文件
cat << EOF | tee ${HOST_PATH}/cfssl/etcd/${ETCD_MEMBER_1_HOSTNAMES}.json
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "${ETCD_MEMBER_1_IP}",
    "${ETCD_MEMBER_1_HOSTNAMES}"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
            "C": "CN",
            "ST": "$CERT_ST",
            "L": "$CERT_L",
            "O": "$CERT_O",
            "OU": "$CERT_OU"
    }
  ]
}
EOF
# 创建 ETCD Member 2 配置文件
cat << EOF | tee ${HOST_PATH}/cfssl/etcd/${ETCD_MEMBER_2_HOSTNAMES}.json
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "${ETCD_MEMBER_2_IP}",
    "${ETCD_MEMBER_2_HOSTNAMES}"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
            "C": "CN",
            "ST": "$CERT_ST",
            "L": "$CERT_L",
            "O": "$CERT_O",
            "OU": "$CERT_OU"
    }
  ]
}
EOF
# 创建 ETCD Member 3 配置文件
cat << EOF | tee ${HOST_PATH}/cfssl/etcd/${ETCD_MEMBER_3_HOSTNAMES}.json
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "${ETCD_MEMBER_3_IP}",
    "${ETCD_MEMBER_3_HOSTNAMES}"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
            "C": "CN",
            "ST": "$CERT_ST",
            "L": "$CERT_L",
            "O": "$CERT_O",
            "OU": "$CERT_OU"
    }
  ]
}
EOF
# 创建etcd k8s EVENTS 集群证书配置
if [ ${K8S_EVENTS} == 1 ]; then
# 创建 ETCD EVENTS Server 配置文件
cat << EOF | tee ${HOST_PATH}/cfssl/etcd/etcd-events.json
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    ${ETCD_EVENTS_IPS},
    ${ETCD_EVENTS_HOSTNAMES}
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
            "C": "CN",
            "ST": "$CERT_ST",
            "L": "$CERT_L",
            "O": "$CERT_O",
            "OU": "$CERT_OU"
    }
  ]
}
EOF
# 创建 ETCD EVENTS Member 1 配置文件
cat << EOF | tee ${HOST_PATH}/cfssl/etcd/${ETCD_EVENTS_MEMBER_1_HOSTNAMES}.json
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "${ETCD_EVENTS_MEMBER_1_IP}",
    "${ETCD_EVENTS_MEMBER_1_HOSTNAMES}"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
            "C": "CN",
            "ST": "$CERT_ST",
            "L": "$CERT_L",
            "O": "$CERT_O",
            "OU": "$CERT_OU"
    }
  ]
}
EOF
# 创建 ETCD EVENTS Member 2 配置文件
cat << EOF | tee ${HOST_PATH}/cfssl/etcd/${ETCD_EVENTS_MEMBER_2_HOSTNAMES}.json
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "${ETCD_EVENTS_MEMBER_2_IP}",
    "${ETCD_EVENTS_MEMBER_2_HOSTNAMES}"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
            "C": "CN",
            "ST": "$CERT_ST",
            "L": "$CERT_L",
            "O": "$CERT_O",
            "OU": "$CERT_OU"
    }
  ]
}
EOF
# 创建 ETCD EVENTS Member 3 配置文件
cat << EOF | tee ${HOST_PATH}/cfssl/etcd/${ETCD_EVENTS_MEMBER_3_HOSTNAMES}.json
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "${ETCD_EVENTS_MEMBER_3_IP}",
    "${ETCD_EVENTS_MEMBER_3_HOSTNAMES}"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
            "C": "CN",
            "ST": "$CERT_ST",
            "L": "$CERT_L",
            "O": "$CERT_O",
            "OU": "$CERT_OU"
    }
  ]
}
EOF
fi
## 创建 ETCD Client 配置文件
cat << EOF | tee ${HOST_PATH}/cfssl/etcd/etcd-client.json
{
  "CN": "client",
  "hosts": [""], 
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
            "C": "CN",
            "ST": "$CERT_ST",
            "L": "$CERT_L",
            "O": "$CERT_O",
            "OU": "$CERT_OU"
    }
  ]
}
EOF
# 创建 Kubernetes CA 配置文件
cat << EOF | tee ${HOST_PATH}/cfssl/k8s/k8s-ca-csr.json
{
  "CN": "$CLUSTER_NAME",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
            "C": "CN",
            "ST": "$CERT_ST",
            "L": "$CERT_L",
            "O": "$CERT_O",
            "OU": "$CERT_OU"
    }
  ],
 "ca": {
  "expiry": "${EXPIRY_TIME}"
  }
}
EOF
# # 创建 Kubernetes API Server 配置文件
cat << EOF | tee ${HOST_PATH}/cfssl/k8s/k8s-apiserver.json
{
  "CN": "$CLUSTER_NAME",
  "hosts": [
    "127.0.0.1",
    ${K8S_APISERVER_VIP},
    "${CLUSTER_KUBERNETES_SVC_IP}", 
    "${K8S_VIP_DOMAIN}",
    "${K8S_VIP_1_IP}",
    "${K8S_VIP_2_IP}",
    "${K8S_VIP_3_IP}",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.${CLUSTER_DNS_DOMAIN}"    
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
            "C": "CN",
            "ST": "$CERT_ST",
            "L": "$CERT_L",
            "O": "$CERT_O",
            "OU": "$CERT_OU"
    }
  ]
}
EOF
# 创建 Kubernetes webhook 证书配置文件
cat << EOF | tee ${HOST_PATH}/cfssl/k8s/aggregator.json
{
  "CN": "aggregator",
  "hosts": [""], 
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
            "C": "CN",
            "ST": "$CERT_ST",
            "L": "$CERT_L",
            "O": "$CERT_O",
            "OU": "$CERT_OU"
    }
  ]
}
EOF
# 创建 Kubernetes Controller Manager 配置文件
cat << EOF | tee ${HOST_PATH}/cfssl/k8s/k8s-controller-manager.json
{
  "CN": "system:kube-controller-manager",
  "hosts": [""], 
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
            "ST": "$CERT_ST",
            "L": "$CERT_L",
      "O": "system:kube-controller-manager",
      "OU": "Kubernetes-manual"
    }
  ]
}
EOF
# 创建 Kubernetes Scheduler 配置文件
cat << EOF | tee ${HOST_PATH}/cfssl/k8s/k8s-scheduler.json
{
  "CN": "system:kube-scheduler",
  "hosts": [""], 
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
            "ST": "$CERT_ST",
            "L": "$CERT_L",
      "O": "system:kube-scheduler",
      "OU": "Kubernetes-manual"
    }
  ]
}
EOF
# 创建admin管理员 配置文件
cat << EOF | tee ${HOST_PATH}/cfssl/k8s/k8s-apiserver-admin.json
{
  "CN": "admin",
  "hosts": [""], 
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
            "ST": "$CERT_ST",
            "L": "$CERT_L",
      "O": "system:masters",
      "OU": "Kubernetes-manual"
    }
  ]
}
EOF
# etcd ca 证书签发
cfssl gencert -initca ${HOST_PATH}/cfssl/etcd/etcd-ca-csr.json | \
      cfssljson -bare ${HOST_PATH}/cfssl/pki/etcd/etcd-ca
## 生成 ETCD Server 证书和私钥
cfssl gencert \
    -ca=${HOST_PATH}/cfssl/pki/etcd/etcd-ca.pem \
    -ca-key=${HOST_PATH}/cfssl/pki/etcd/etcd-ca-key.pem \
    -config=${HOST_PATH}/cfssl/ca-config.json \
    -profile=${CERT_PROFILE} \
    ${HOST_PATH}/cfssl/etcd/etcd-server.json | \
    cfssljson -bare ${HOST_PATH}/cfssl/pki/etcd/etcd-server
# 生成 ETCD Member 1 证书和私钥
cfssl gencert \
    -ca=${HOST_PATH}/cfssl/pki/etcd/etcd-ca.pem \
    -ca-key=${HOST_PATH}/cfssl/pki/etcd/etcd-ca-key.pem \
    -config=${HOST_PATH}/cfssl/ca-config.json \
    -profile=${CERT_PROFILE} \
    ${HOST_PATH}/cfssl/etcd/${ETCD_MEMBER_1_HOSTNAMES}.json | \
    cfssljson -bare ${HOST_PATH}/cfssl/pki/etcd/etcd-member-${ETCD_MEMBER_1_HOSTNAMES}
# 生成 ETCD Member 2 证书和私钥
cfssl gencert \
    -ca=${HOST_PATH}/cfssl/pki/etcd/etcd-ca.pem \
    -ca-key=${HOST_PATH}/cfssl/pki/etcd/etcd-ca-key.pem \
    -config=${HOST_PATH}/cfssl/ca-config.json \
    -profile=${CERT_PROFILE} \
    ${HOST_PATH}/cfssl/etcd/${ETCD_MEMBER_2_HOSTNAMES}.json | \
    cfssljson -bare ${HOST_PATH}/cfssl/pki/etcd/etcd-member-${ETCD_MEMBER_2_HOSTNAMES}
# 生成 ETCD Member 3 证书和私钥
cfssl gencert \
    -ca=${HOST_PATH}/cfssl/pki/etcd/etcd-ca.pem \
    -ca-key=${HOST_PATH}/cfssl/pki/etcd/etcd-ca-key.pem \
    -config=${HOST_PATH}/cfssl/ca-config.json \
    -profile=${CERT_PROFILE} \
    ${HOST_PATH}/cfssl/etcd/${ETCD_MEMBER_3_HOSTNAMES}.json | \
    cfssljson -bare ${HOST_PATH}/cfssl/pki/etcd/etcd-member-${ETCD_MEMBER_3_HOSTNAMES}
if [ ${K8S_EVENTS} == 1 ]; then
## 生成 ETCD EVENTS Server 证书和私钥
cfssl gencert \
    -ca=${HOST_PATH}/cfssl/pki/etcd/etcd-ca.pem \
    -ca-key=${HOST_PATH}/cfssl/pki/etcd/etcd-ca-key.pem \
    -config=${HOST_PATH}/cfssl/ca-config.json \
    -profile=${CERT_PROFILE} \
    ${HOST_PATH}/cfssl/etcd/etcd-events.json | \
    cfssljson -bare ${HOST_PATH}/cfssl/pki/etcd/etcd-events
# 生成 ETCD EVENTS Member 1 证书和私钥
cfssl gencert \
    -ca=${HOST_PATH}/cfssl/pki/etcd/etcd-ca.pem \
    -ca-key=${HOST_PATH}/cfssl/pki/etcd/etcd-ca-key.pem \
    -config=${HOST_PATH}/cfssl/ca-config.json \
    -profile=${CERT_PROFILE} \
    ${HOST_PATH}/cfssl/etcd/${ETCD_EVENTS_MEMBER_1_HOSTNAMES}.json | \
    cfssljson -bare ${HOST_PATH}/cfssl/pki/etcd/etcd-events-${ETCD_EVENTS_MEMBER_1_HOSTNAMES}
# 生成 ETCD EVENTS  Member 2 证书和私钥
cfssl gencert \
    -ca=${HOST_PATH}/cfssl/pki/etcd/etcd-ca.pem \
    -ca-key=${HOST_PATH}/cfssl/pki/etcd/etcd-ca-key.pem \
    -config=${HOST_PATH}/cfssl/ca-config.json \
    -profile=${CERT_PROFILE} \
    ${HOST_PATH}/cfssl/etcd/${ETCD_EVENTS_MEMBER_2_HOSTNAMES}.json | \
    cfssljson -bare ${HOST_PATH}/cfssl/pki/etcd/etcd-events-${ETCD_EVENTS_MEMBER_2_HOSTNAMES}
# 生成 ETCD EVENTS Member 3 证书和私钥
cfssl gencert \
    -ca=${HOST_PATH}/cfssl/pki/etcd/etcd-ca.pem \
    -ca-key=${HOST_PATH}/cfssl/pki/etcd/etcd-ca-key.pem \
    -config=${HOST_PATH}/cfssl/ca-config.json \
    -profile=${CERT_PROFILE} \
    ${HOST_PATH}/cfssl/etcd/${ETCD_EVENTS_MEMBER_3_HOSTNAMES}.json | \
    cfssljson -bare ${HOST_PATH}/cfssl/pki/etcd/etcd-events-${ETCD_EVENTS_MEMBER_3_HOSTNAMES}
 fi
# 生成 ETCD Client 证书和私钥
cfssl gencert \
    -ca=${HOST_PATH}/cfssl/pki/etcd/etcd-ca.pem \
    -ca-key=${HOST_PATH}/cfssl/pki/etcd/etcd-ca-key.pem \
    -config=${HOST_PATH}/cfssl/ca-config.json \
    -profile=${CERT_PROFILE} \
    ${HOST_PATH}/cfssl/etcd/etcd-client.json | \
    cfssljson -bare ${HOST_PATH}/cfssl/pki/etcd/etcd-client
# 生成 Kubernetes CA 证书和私钥
cfssl gencert -initca ${HOST_PATH}/cfssl/k8s/k8s-ca-csr.json | \
    cfssljson -bare ${HOST_PATH}/cfssl/pki/k8s/k8s-ca	
# 生成 Kubernetes API Server 证书和私钥
cfssl gencert \
    -ca=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
    -ca-key=${HOST_PATH}/cfssl/pki/k8s/k8s-ca-key.pem \
    -config=${HOST_PATH}/cfssl/ca-config.json \
    -profile=${CERT_PROFILE} \
    ${HOST_PATH}/cfssl/k8s/k8s-apiserver.json | \
    cfssljson -bare ${HOST_PATH}/cfssl/pki/k8s/k8s-server
# 生成 Kubernetes webhook 证书和私钥
cfssl gencert \
    -ca=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
    -ca-key=${HOST_PATH}/cfssl/pki/k8s/k8s-ca-key.pem \
    -config=${HOST_PATH}/cfssl/ca-config.json \
    -profile=${CERT_PROFILE} \
    ${HOST_PATH}/cfssl/k8s/aggregator.json | \
    cfssljson -bare ${HOST_PATH}/cfssl/pki/k8s/aggregator
# 生成 Kubernetes Controller Manager 证书和私钥
cfssl gencert \
    -ca=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
    -ca-key=${HOST_PATH}/cfssl/pki/k8s/k8s-ca-key.pem \
    -config=${HOST_PATH}/cfssl/ca-config.json \
    -profile=${CERT_PROFILE} \
    ${HOST_PATH}/cfssl/k8s/k8s-controller-manager.json | \
    cfssljson -bare ${HOST_PATH}/cfssl/pki/k8s/k8s-controller-manager
# 生成 Kubernetes Scheduler 证书和私钥
cfssl gencert \
    -ca=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
    -ca-key=${HOST_PATH}/cfssl/pki/k8s/k8s-ca-key.pem \
    -config=${HOST_PATH}/cfssl/ca-config.json \
    -profile=${CERT_PROFILE} \
    ${HOST_PATH}/cfssl/k8s/k8s-scheduler.json | \
    cfssljson -bare ${HOST_PATH}/cfssl/pki/k8s/k8s-scheduler
# 生成 Kubernetes admin管理员证书	
cfssl gencert -ca=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
      -ca-key=${HOST_PATH}/cfssl/pki/k8s/k8s-ca-key.pem \
      -config=${HOST_PATH}/cfssl/ca-config.json \
      -profile=${CERT_PROFILE} \
	  ${HOST_PATH}/cfssl/k8s/k8s-apiserver-admin.json | \
	  cfssljson -bare ${HOST_PATH}/cfssl/pki/k8s/k8s-apiserver-admin
	
if [ ${NET_PLUG} == 1 ]; then
cat << EOF | tee ${HOST_PATH}/cfssl/k8s/kube-router.json
{
  "CN": "kube-router",
  "hosts": [""], 
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
            "C": "CN",
            "ST": "$CERT_ST",
            "L": "$CERT_L",
      "O": "system:masters",
      "OU": "Kubernetes-manual"
    }
  ]
}
EOF
# 生成 kube-router 证书和私钥
cfssl gencert -ca=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
      -ca-key=${HOST_PATH}/cfssl/pki/k8s/k8s-ca-key.pem \
      -config=${HOST_PATH}/cfssl/ca-config.json \
      -profile=${CERT_PROFILE} \
	  ${HOST_PATH}/cfssl/k8s/kube-router.json | \
	  cfssljson -bare ${HOST_PATH}/cfssl/pki/k8s/kube-router
elif [ ${NET_PLUG} == 2 ]; then 
# 创建kube-proxy 证书配置
cat << EOF | tee ${HOST_PATH}/cfssl/k8s/kube-proxy.json
{
  "CN": "system:kube-proxy",
  "hosts": [""], 
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
            "C": "CN",
            "ST": "$CERT_ST",
            "L": "$CERT_L",
      "O": "system:masters",
      "OU": "Kubernetes-manual"
    }
  ]
}
EOF
# 生成 kube-proxy 证书和私钥
cfssl gencert \
        -ca=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
        -ca-key=${HOST_PATH}/cfssl/pki/k8s/k8s-ca-key.pem \
        -config=${HOST_PATH}/cfssl/ca-config.json \
        -profile=${CERT_PROFILE} \
         ${HOST_PATH}/cfssl/k8s/kube-proxy.json | \
         cfssljson -bare ${HOST_PATH}/cfssl/pki/k8s/kube-proxy
fi
#创建 kubeconfig 文件
# 删除旧数据
#rm -rf ${HOST_PATH}/kubeconfig
mkdir -p ${HOST_PATH}/kubeconfig
# 创建admin管理员登录kubeconfig
# 设置集群参数
kubectl config set-cluster ${CLUSTER_NAME} \
--certificate-authority=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
--embed-certs=true  \
--server=${KUBE_APISERVER} \
--kubeconfig=${HOST_PATH}/kubeconfig/admin.kubeconfig
# 设置客户端认证参数
kubectl config set-credentials admin \
 --client-certificate=${HOST_PATH}/cfssl/pki/k8s/k8s-apiserver-admin.pem \
 --client-key=${HOST_PATH}/cfssl/pki/k8s/k8s-apiserver-admin-key.pem \
 --embed-certs=true \
 --kubeconfig=${HOST_PATH}/kubeconfig/admin.kubeconfig
# 设置上下文参数 
kubectl config set-context ${CLUSTER_NAME} \
--cluster=${CLUSTER_NAME} \
--user=admin \
--namespace=kube-system \
--kubeconfig=${HOST_PATH}/kubeconfig/admin.kubeconfig
# 设置默认上下文
kubectl config use-context ${CLUSTER_NAME} --kubeconfig=${HOST_PATH}/kubeconfig/admin.kubeconfig
# 创建kube-scheduler kubeconfig 配置文件
# 设置集群参数
kubectl config set-cluster ${CLUSTER_NAME} \
--certificate-authority=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
--embed-certs=true \
--server=${KUBE_APISERVER} \
--kubeconfig=${HOST_PATH}/kubeconfig/kube-scheduler.kubeconfig
# 设置客户端认证参数
kubectl config set-credentials system:kube-scheduler \
--client-certificate=${HOST_PATH}/cfssl/pki/k8s/k8s-scheduler.pem \
--embed-certs=true \
--client-key=${HOST_PATH}/cfssl/pki/k8s/k8s-scheduler-key.pem \
--kubeconfig=${HOST_PATH}/kubeconfig/kube-scheduler.kubeconfig
 # 设置上下文参数
kubectl config set-context ${CLUSTER_NAME} \
--cluster=${CLUSTER_NAME} \
--user=system:kube-scheduler \
--kubeconfig=${HOST_PATH}/kubeconfig/kube-scheduler.kubeconfig
# 设置默认上下文
kubectl config use-context ${CLUSTER_NAME} --kubeconfig=${HOST_PATH}/kubeconfig/kube-scheduler.kubeconfig
# 创建kube-controller-manager kubeconfig 配置文件
# 设置集群参数
kubectl config set-cluster ${CLUSTER_NAME} \
--certificate-authority=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
--embed-certs=true \
--server=${KUBE_APISERVER} \
--kubeconfig=${HOST_PATH}/kubeconfig/kube-controller-manager.kubeconfig
# 设置客户端认证参数
kubectl config set-credentials system:kube-controller-manager \
--client-certificate=${HOST_PATH}/cfssl/pki/k8s/k8s-controller-manager.pem \
--embed-certs=true \
--client-key=${HOST_PATH}/cfssl/pki/k8s/k8s-controller-manager-key.pem \
--kubeconfig=${HOST_PATH}/kubeconfig/kube-controller-manager.kubeconfig
# 设置上下文参数
kubectl config set-context ${CLUSTER_NAME} \
--cluster=${CLUSTER_NAME} \
--user=system:kube-controller-manager \
--kubeconfig=${HOST_PATH}/kubeconfig/kube-controller-manager.kubeconfig
# 设置默认上下文
kubectl config use-context ${CLUSTER_NAME} --kubeconfig=${HOST_PATH}/kubeconfig/kube-controller-manager.kubeconfig
if [ ${NET_PLUG} == 1 ]; then
# 创建kube-router kubeconfig 配置文件
# 设置集群参数
kubectl config set-cluster ${CLUSTER_NAME} \
--certificate-authority=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
--embed-certs=true \
--server=${KUBE_APISERVER} \
--kubeconfig=${HOST_PATH}/kubeconfig/kube-router.kubeconfig
# 设置客户端认证参数    
kubectl config set-credentials kube-router \
--client-certificate=${HOST_PATH}/cfssl/pki/k8s/kube-router.pem \
--client-key=${HOST_PATH}/cfssl/pki/k8s/kube-router-key.pem \
--embed-certs=true \
--kubeconfig=${HOST_PATH}/kubeconfig/kube-router.kubeconfig
# 设置上下文参数  
kubectl config set-context default \
--cluster=${CLUSTER_NAME} \
--user=kube-router \
--kubeconfig=${HOST_PATH}/kubeconfig/kube-router.kubeconfig
# 设置默认上下文  
kubectl config use-context default --kubeconfig=${HOST_PATH}/kubeconfig/kube-router.kubeconfig
elif [ ${NET_PLUG} == 2 ]; then 
# 创建kube-proxy kubeconfig 配置文件
# 设置集群参数
kubectl config set-cluster ${CLUSTER_NAME} \
  --certificate-authority=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=${HOST_PATH}/kubeconfig/kube-proxy.kubeconfig 
# 设置客户端认证参数
    kubectl config set-credentials system:kube-proxy \
  --client-certificate=${HOST_PATH}/cfssl/pki/k8s/kube-proxy.pem \
  --client-key=${HOST_PATH}/cfssl/pki/k8s/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=${HOST_PATH}/kubeconfig/kube-proxy.kubeconfig 
# 设置上下文参数
    kubectl config set-context default \
  --cluster=${CLUSTER_NAME} \
  --user=system:kube-proxy \
  --kubeconfig=${HOST_PATH}/kubeconfig/kube-proxy.kubeconfig 
# 设置默认上下文
kubectl config use-context default --kubeconfig=${HOST_PATH}/kubeconfig/kube-proxy.kubeconfig 
fi
# 创建bootstrap  kubeconfig 配置
# 设置集群参数
kubectl config set-cluster ${CLUSTER_NAME} \
  --certificate-authority=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=${HOST_PATH}/kubeconfig/bootstrap.kubeconfig
# 设置客户端认证参数
kubectl config set-credentials system:bootstrap:${TOKEN_ID} \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=${HOST_PATH}/kubeconfig/bootstrap.kubeconfig
# 设置上下文参数
kubectl config set-context default \
  --cluster=${CLUSTER_NAME} \
  --user=system:bootstrap:${TOKEN_ID} \
  --kubeconfig=${HOST_PATH}/kubeconfig/bootstrap.kubeconfig
# 设置默认上下文
kubectl config use-context default --kubeconfig=${HOST_PATH}/kubeconfig/bootstrap.kubeconfig
# 创建ansibe playbook
# 创建 playbook 目录
mkdir -p roles/{docker,cni,etcd,kube-apiserver,kube-controller-manager,kubelet,kube-scheduler,package,lxcfs,haproxy,keepalived,iptables}/{files,tasks,templates}
#创建etcd playbook
cat << EOF | tee ${HOST_PATH}/roles/etcd/tasks/main.yml
- name: create groupadd etcd
  group: name=etcd
- name: create name etcd
  user: name=etcd shell="/sbin/nologin etcd" group=etcd
- name: mkdir ${ETCD_PATH}
  raw: mkdir -p ${ETCD_PATH}/{conf,ssl,bin} 
- name: mkdir ${ETCD_WAL_DIR}
  raw: mkdir -p ${ETCD_WAL_DIR}/wal && mkdir -p ${ETCD_DATA_DIR}
- name: copy etcd
  copy: src=bin dest=${ETCD_PATH}/ owner=etcd group=etcd mode=755
- name: copy etcd ssl
  copy: src=ssl dest=${ETCD_PATH}/
- name: src=etcd dest=${ETCD_PATH}/conf
  template: src=etcd dest=${ETCD_PATH}/conf
- name: copy etcd.service
  template: src=etcd.service  dest=/lib/systemd/system/
- name: chown -R etcd:etcd ${ETCD_PATH}/
  shell: chown -R etcd:etcd ${ETCD_PATH}/ && chown -R etcd:etcd ${ETCD_DATA_DIR} && chown -R etcd:etcd ${ETCD_WAL_DIR}/
- name: Reload service daemon-reload
  shell: systemctl daemon-reload
- name: Enable service etcd, and not touch the state
  service:
    name: etcd
    enabled: yes
- name: Start service etcd, if not started
  service:
    name: etcd
    state: started
EOF
# 创建etcd 启动配置文件
cat << EOF | tee ${HOST_PATH}/roles/etcd/templates/etcd
ETCD_OPTS="--name={{ ansible_hostname }} \\
           --data-dir=${ETCD_DATA_DIR}\\
           --wal-dir=${ETCD_WAL_DIR}/wal \\
           --listen-peer-urls=https://{{ $API_IPV4 }}:2380 \\
           --listen-client-urls=https://{{ $API_IPV4 }}:2379,https://127.0.0.1:2379 \\
           --advertise-client-urls=https://{{ $API_IPV4 }}:2379 \\
           --initial-advertise-peer-urls=https://{{ $API_IPV4 }}:2380 \\
           --initial-cluster={{ INITIAL_CLUSTER }} \\
           --initial-cluster-token={{ INITIAL_CLUSTER }} \\
           --initial-cluster-state=new \\
           --heartbeat-interval=6000 \\
           --election-timeout=30000 \\
           --snapshot-count=5000 \\
           --auto-compaction-retention=1 \\
           --max-request-bytes=33554432 \\
           --quota-backend-bytes=17179869184 \\
           --trusted-ca-file=${ETCD_PATH}/ssl/{{ ca }}.pem \\
           --cert-file=${ETCD_PATH}/ssl/{{ cert_file }}.pem \\
           --key-file=${ETCD_PATH}/ssl/{{ cert_file }}-key.pem \\
           --peer-cert-file=${ETCD_PATH}/ssl/{{ ETCD_MEMBER }}-{{ ansible_hostname }}.pem \\
           --peer-key-file=${ETCD_PATH}/ssl/{{ ETCD_MEMBER }}-{{ ansible_hostname }}-key.pem \\
           --peer-client-cert-auth \\
           --peer-trusted-ca-file=${ETCD_PATH}/ssl/{{ ca }}.pem"
EOF
# 创建etcd 启动文件
cat << EOF | tee ${HOST_PATH}/roles/etcd/templates/etcd.service
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/etcd-io/etcd
[Service]
Type=notify
LimitNOFILE=1024000
LimitNPROC=1024000
LimitCORE=infinity
LimitMEMLOCK=infinity
User=etcd
Group=etcd
WorkingDirectory=${ETCD_DATA_DIR}
EnvironmentFile=-${ETCD_PATH}/conf/etcd
ExecStart=${ETCD_PATH}/bin/etcd \$ETCD_OPTS
Restart=on-failure


[Install]
WantedBy=multi-user.target
EOF

cat << EOF | tee ${HOST_PATH}/etcd.yml
- hosts: all
  user: root
  vars:
    cert_file: etcd-server
    ca: etcd-ca
    ETCD_MEMBER: etcd-member
    INITIAL_CLUSTER: ${INITIAL_CLUSTER}
  roles:
    - etcd
EOF
if [ ${K8S_EVENTS} == 1 ]; then
cat << EOF | tee ${HOST_PATH}/events-etcd.yml
- hosts: all
  user: root
  vars:
    cert_file: etcd-events
    ca: etcd-ca
    ETCD_MEMBER: etcd-events
    INITIAL_CLUSTER: ${INITIAL_EVENTS_CLUSTER}
  roles:
    - etcd
EOF
fi
# cp 二进制文件及ssl 文件到 ansible 目录
tar -xf ${TEMP_PATH}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz -C ${TEMP_PATH}
mkdir -p ${HOST_PATH}/roles/etcd/files/{ssl,bin}
\cp -pdr ${TEMP_PATH}/etcd-${ETCD_VERSION}-linux-amd64/{etcd,etcdctl} ${HOST_PATH}/roles/etcd/files/bin
\cp -pdr ${HOST_PATH}/cfssl/pki/etcd/*.pem ${HOST_PATH}/roles/etcd/files/ssl
# 创建kube-apiserver playbook
cat << EOF | tee ${HOST_PATH}/roles/kube-apiserver/tasks/main.yml
- name: create groupadd k8s
  group: name=k8s
- name: create name k8s
  user: name=k8s shell="/sbin/nologin k8s" group=k8s
- name:  mkdir ${K8S_PATH}
  raw: mkdir -p ${K8S_PATH}/{log,kubelet-plugins,conf} && mkdir -p ${K8S_PATH}/kubelet-plugins/volume
- name: copy kube-apiserver
  copy: src=bin dest=${K8S_PATH}/ owner=k8s group=root mode=755
- name: copy config
  copy: src={{ item }} dest=${K8S_PATH}/ owner=k8s group=root
  with_items:
      - config
      - ssl
- name: kube-apiservice conf
  template: src=kube-apiserver dest=${K8S_PATH}/conf owner=k8s group=root
- name: copy kube-apiserver.service
  template: src=kube-apiserver.service  dest=/lib/systemd/system/
- name: chown -R k8s
  shell: chown -R k8s:root ${K8S_PATH}/
- name: Reload service daemon-reload
  shell: systemctl daemon-reload
- name: Enable service kube-apiserver, and not touch the state
  service:
    name: kube-apiserver
    enabled: yes
- name: Start service kube-apiserver, if not started
  service:
    name: kube-apiserver
    state: started
EOF
# 创建 kube-apiserver 启动配置文件
cat << EOF | tee ${HOST_PATH}/roles/kube-apiserver/templates/kube-apiserver
KUBE_APISERVER_OPTS="--logtostderr=false \\
        --bind-address={{ $API_IPV4 }} \\
        --advertise-address={{ $API_IPV4 }} \\
        --secure-port=${SECURE_PORT} \\
        --insecure-port=0 \\
        --service-cluster-ip-range=${SERVICE_CIDR} \\
        --service-node-port-range=${NODE_PORT_RANGE} \\
        --etcd-cafile=${K8S_PATH}/ssl/etcd/etcd-ca.pem \\
        --etcd-certfile=${K8S_PATH}/ssl/etcd/etcd-client.pem \\
        --etcd-keyfile=${K8S_PATH}/ssl/etcd/etcd-client-key.pem \\
        --etcd-prefix=${ETCD_PREFIX} \\
        --etcd-servers=${ENDPOINTS} \\
        --client-ca-file=${K8S_PATH}/ssl/k8s/k8s-ca.pem \\
        --tls-cert-file=${K8S_PATH}/ssl/k8s/k8s-server.pem \\
        --tls-private-key-file=${K8S_PATH}/ssl/k8s/k8s-server-key.pem \\
        --kubelet-client-certificate=${K8S_PATH}/ssl/k8s/k8s-server.pem \\
        --kubelet-client-key=${K8S_PATH}/ssl/k8s/k8s-server-key.pem \\
        --service-account-key-file=${K8S_PATH}/ssl/k8s/k8s-ca.pem \\
        --requestheader-client-ca-file=${K8S_PATH}/ssl/k8s/k8s-ca.pem \\
        --proxy-client-cert-file=${K8S_PATH}/ssl/k8s/aggregator.pem \\
        --proxy-client-key-file=${K8S_PATH}/ssl/k8s/aggregator-key.pem \\
        --requestheader-allowed-names=aggregator \\
        --requestheader-group-headers=X-Remote-Group \\
        --requestheader-extra-headers-prefix=X-Remote-Extra- \\
        --requestheader-username-headers=X-Remote-User \\
        --enable-aggregator-routing=true \\
        --anonymous-auth=false \\
        --experimental-encryption-provider-config=${K8S_PATH}/config/encryption-config.yaml \\
        --enable-admission-plugins=${ENABLE_ADMISSION_PLUGINS} \\
        --disable-admission-plugins=${DISABLE_ADMISSION_PLUGINS} \\
        --cors-allowed-origins=.* \\
        --enable-swagger-ui \\
        --runtime-config=${RUNTIME_CONFIG} \\
        --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname \\
        --authorization-mode=Node,RBAC \\
        --allow-privileged=true \\
        --apiserver-count=${APISERVER_COUNT} \\
        --audit-dynamic-configuration \\
        --audit-log-maxage=30 \\
        --audit-log-maxbackup=3 \\
        --audit-log-maxsize=100 \\
        --audit-log-truncate-enabled \\
        --audit-policy-file=${K8S_PATH}/config/audit-policy.yaml \\
        --audit-log-path=${K8S_PATH}/log/api-server-audit.log \\
        --profiling \\
        --kubelet-https \\
        --event-ttl=1h \\
        --feature-gates=RotateKubeletServerCertificate=true,RotateKubeletClientCertificate=true,DynamicAuditing=true \\
        --enable-bootstrap-token-auth=true \\
        --alsologtostderr=true \\
        --log-dir=${K8S_PATH}/log \\
        --v=${LEVEL_LOG} \\
        --endpoint-reconciler-type=lease \\
        --max-mutating-requests-inflight=${MAX_MUTATING_REQUESTS_INFLIGHT} \\
        --max-requests-inflight=${MAX_REQUESTS_INFLIGHT} \\
        --target-ram-mb=${TARGET_RAM_MB}"
EOF
# 创建 kube-apiserver 启动文件
cat << EOF | tee ${HOST_PATH}/roles/kube-apiserver/templates/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
Type=notify
LimitNOFILE=1024000
LimitNPROC=1024000
LimitCORE=infinity
LimitMEMLOCK=infinity

EnvironmentFile=-${K8S_PATH}/conf/kube-apiserver
ExecStart=${K8S_PATH}/bin/kube-apiserver \$KUBE_APISERVER_OPTS
Restart=on-failure
RestartSec=5
User=k8s 
[Install]
WantedBy=multi-user.target
EOF
# cp 二进制文件及ssl 文件到 ansible 目录
tar -xf ${TEMP_PATH}/kubernetes-server-linux-amd64.tar.gz -C ${TEMP_PATH}
mkdir -p ${HOST_PATH}/roles/kube-apiserver/files/{ssl,bin,config}
mkdir -p ${HOST_PATH}/roles/kube-apiserver/files/ssl/{etcd,k8s}
\cp -pdr ${TEMP_PATH}/kubernetes/server/bin/kube-apiserver ${HOST_PATH}/roles/kube-apiserver/files/bin
\cp -pdr ${HOST_PATH}/cfssl/pki/etcd/{etcd-client*.pem,etcd-ca.pem} ${HOST_PATH}/roles/kube-apiserver/files/ssl/etcd
\cp -pdr ${HOST_PATH}/cfssl/pki/k8s/{k8s-server*.pem,k8s-ca.pem,aggregator*.pem} ${HOST_PATH}/roles/kube-apiserver/files/ssl/k8s
# 生成encryption-config.yaml
cat << EOF | tee ${HOST_PATH}/roles/kube-apiserver/files/config/encryption-config.yaml
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
# 创建审计策略文件
cat << EOF | tee ${HOST_PATH}/roles/kube-apiserver/files/config/audit-policy.yaml
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
# 
cat << EOF | tee ${HOST_PATH}/kube-apiserver.yml
- hosts: all
  user: root
  roles:
    - kube-apiserver
EOF
# 创建haproxy playbook
cat << EOF | tee ${HOST_PATH}/roles/haproxy/tasks/main.yml
- name: centos8 enabled CentOS-PowerTools.repo
  raw: sed -i "s/enabled=0/enabled=1/" /etc/yum.repos.d/CentOS-PowerTools.repo
  when: ansible_pkg_mgr == "dnf"
- name: centos8 dnf Install
  dnf: 
    name:  
      - epel-release
    state: latest
  when: ansible_pkg_mgr == "dnf"
- name: centos8 dnf Install
  dnf: 
    name:
      - pcre-devel
      - ipvsadm
      - bzip2-devel
      - gcc
      - gcc-c++
      - make
      - systemd-devel
      - openssl-devel
      - libnfnetlink-devel
      - popt-devel
      - libnfnetlink
      - kernel-devel
      - autoconf
      - perl
      - rsyslog
    state: latest
  when: ansible_pkg_mgr == "dnf"
- name: centos7 yum Install
  yum: 
    name:  
      - epel-release
      - yum-plugin-fastestmirror
    state: latest
  when: ansible_pkg_mgr == "yum"
- name: centos7 yum Install
  yum: 
    name:
      - pcre-devel
      - ipvsadm
      - bzip2-devel
      - gcc
      - gcc-c++
      - make
      - systemd-devel
      - openssl-devel
      - libnfnetlink-devel
      - popt-devel
      - libnfnetlink
      - kernel-devel
      - autoconf
      - perl
      - rsyslog
    state: latest
  when: ansible_pkg_mgr == "yum"
- name: Only run "update_cache=yes" 
  apt:
    update_cache: yes
  when: ansible_pkg_mgr == "apt"  
- name: ubuntu apt Install
  apt: 
    name:
      - ipvsadm
      - libssl-dev
      - libnfnetlink-dev
      - libpopt-dev
      - linux-libc-dev
      - kernel-package
      - autoconf
      - perl
      - libsystemd-dev
      - make
      - gcc 
      - libbz2-dev
      - libpcre3-dev
      - zlib1g-dev
      - rsyslog
    state: latest
  when: ansible_pkg_mgr == "apt"
- name: create groupadd haproxy
  group: name=haproxy
- name: create name haproxy
  user: name=haproxy shell="/sbin/nologin haproxy" group=haproxy
- name: copy to haproxy
  copy: src=haproxy-${HAPROXY_VERSION}.tar.gz dest=${SOURCE_PATH}/
- name: tar haproxy-${HAPROXY_VERSION}.tar.gz
  raw: tar -xvf  ${SOURCE_PATH}/haproxy-${HAPROXY_VERSION}.tar.gz -C  ${SOURCE_PATH}/
- name: make to haproxy
  shell: cd  ${SOURCE_PATH}/haproxy-${HAPROXY_VERSION}/ && make CPU="generic" TARGET=os USE_SYSTEMD=1 USE_PCRE=1 USE_PCRE_JIT=1 USE_OPENSSL=1 USE_ZLIB=1 USE_REGPARM=1 USE_LINUX_TPROXY=1 USE_CPU_AFFINITY=1 DEFINE=-DTCP_USER_TIMEOUT=18  PREFIX=${HAPROXY_PATH}
- name: make install
  shell: cd  ${SOURCE_PATH}/haproxy-${HAPROXY_VERSION}/ && make install PREFIX=${HAPROXY_PATH}
- name: mkdir ${HAPROXY_PATH}/{run,log}
  raw: mkdir -pv ${HAPROXY_PATH}/{conf,run,log}
- name: copy to haproxy
  template: src=haproxy.conf dest=${HAPROXY_PATH}/conf/haproxy.conf
- name: copy to haproxy
  template: src=haproxy dest=/etc/logrotate.d/haproxy
- name: copy init haproxy
  template: src=haproxy.service dest=/lib/systemd/system/haproxy.service
- name: rsyslog
  template: src=49-haproxy.conf dest=/etc/rsyslog.d/49-haproxy.conf
- name: Restart service rsyslog, in all cases
  service:
    name: rsyslog
    state: restarted
- name: Reload service daemon-reload
  shell: systemctl daemon-reload
- name: Enable service haproxy, and not touch the state
  service:
    name: haproxy
    enabled: yes
- name: Start service haproxy, if not started
  service:
    name: haproxy
    state: started
EOF
# 创建 haproxy 日志分割配置文件
cat << EOF | tee ${HOST_PATH}/roles/haproxy/templates/haproxy
${HAPROXY_PATH}/log/*.log {
    rotate 14
    daily
    missingok
    compress
    dateext
    size 50M
    notifempty
    copytruncate
}
EOF
# 创建 haproxy 日志收集配置
cat << EOF | tee ${HOST_PATH}/roles/haproxy/templates/49-haproxy.conf
\$ModLoad imudp
\$UDPServerAddress 127.0.0.1
\$UDPServerRun 514

\$template HAProxy,"%syslogtag%%msg:::drop-last-lf%\n"
\$template TraditionalFormatWithPRI,"%pri-text%: %timegenerated% %syslogtag%%msg:::drop-last-lf%\n"

local2.=info     ${HAPROXY_PATH}/log/access.log;HAProxy
local2.=notice;local2.=warning    ${HAPROXY_PATH}/log/status.log;TraditionalFormatWithPRI
local2.error    ${HAPROXY_PATH}/log/error.log;TraditionalFormatWithPRI
local2.* stop
EOF
# haproxy 配置文件
cat << EOF | tee ${HOST_PATH}/roles/haproxy/templates/haproxy.conf
global  
                maxconn 100000  
                chroot ${HAPROXY_PATH}
                user haproxy

                group haproxy 

                daemon  
                pidfile ${HAPROXY_PATH}/run/haproxy.pid  
                #debug  
                #quiet 
                stats socket ${HAPROXY_PATH}/run/haproxy.sock mode 600 level admin
                log             127.0.0.1 local2 
                # CPU 个数绑定 4核配置
                nbproc 4
                cpu-map 1 0
                cpu-map 2 1
                cpu-map 3 2
                cpu-map 4 3
                stats bind-process 4

defaults  
                log     global
                mode    tcp
                option  tcplog
                option  dontlognull
                option  redispatch  
                retries 3 
                maxconn 100000
                timeout connect     30000 
                timeout client      50000  
                timeout server 50000  

resolvers  dns1
        nameserver dns1  114.114.114.114:53
        nameserver dns2  8.8.8.8:53
        resolve_retries 3
        timeout resolve 10s
        timeout retry 10s
        hold other 30s
        hold refused 30s
        hold nx 30s
        hold timeout 30s
        hold valid 10s
        hold obsolete 30s

listen admin_stat  
        # 监听端口  
        bind 0.0.0.0:57590 
        # http的7层模式  
        mode http  
        #log global  
        # 统计页面自动刷新时间  
        stats refresh 30s  
        # 统计页面URL  
        stats uri /admin?stats  
        # 统计页面密码框上提示文本  
        stats realm Haproxy\ Statistics  
        # 统计页面用户名和密码设置  
        stats auth admin:123456admin
        # 隐藏统计页面上HAProxy的版本信息  
        #stats hide-version  
        stats enable
        # cpu 绑定 nbproc 4 值确定
        bind-process 4
frontend kube-apiserver-https
  mode tcp
  bind :${K8S_VIP_PORT}
  default_backend kube-apiserver-backend
backend kube-apiserver-backend
  mode tcp
EOF
# 添加kube-apiserver 节点ip 到 haproxy.conf 配置文件
K8S_APISERVER_IP=`echo $K8S_APISERVER_VIP| sed  -e "s/\"//g"`
array=(${K8S_APISERVER_IP//,/ })

for var in ${array[@]}
do
#       echo kube-apiserver IP $var
       sed  -r -i -e "\$a\ \ server\ $var-api\ $var:$SECURE_PORT\ check" ${HOST_PATH}/roles/haproxy/templates/haproxy.conf

   done
# haproxy 启动文件
cat << EOF | tee ${HOST_PATH}/roles/haproxy/templates/haproxy.service
[Unit]
Description=HAProxy Load Balancer
Documentation=man:haproxy(1)
After=syslog.target network.target

[Service]
LimitCORE=infinity
LimitNOFILE=1024000
LimitNPROC=1024000
EnvironmentFile=-/etc/sysconfig/haproxy
Environment="CONFIG=${HAPROXY_PATH}/conf/haproxy.conf" "PIDFILE=${HAPROXY_PATH}/run/haproxy.pid"
ExecStartPre=${HAPROXY_PATH}/sbin/haproxy -f \$CONFIG -c -q
ExecStart=${HAPROXY_PATH}/sbin/haproxy -Ws -f \$CONFIG -p \$PIDFILE
ExecReload=${HAPROXY_PATH}/sbin/haproxy -f \$CONFIG -c -q
ExecReload=/bin/kill -USR2 \$MAINPID
KillMode=mixed
Restart=always
Type=notify

[Install]
WantedBy=multi-user.target
EOF
# 复制haproxy 源码zip 到playbook
\cp -pdr ${TEMP_PATH}/haproxy-${HAPROXY_VERSION}.tar.gz ${HOST_PATH}/roles/haproxy/files/haproxy-${HAPROXY_VERSION}.tar.gz
cat << EOF | tee ${HOST_PATH}/haproxy.yml
- hosts: all
  user: root
  roles:
    - haproxy
EOF

# 创建keepalived playbook
cat << EOF | tee ${HOST_PATH}/roles/keepalived/tasks/main.yml
- name: centos8 enabled CentOS-PowerTools.repo
  raw: sed -i "s/enabled=0/enabled=1/" /etc/yum.repos.d/CentOS-PowerTools.repo
  when: ansible_pkg_mgr == "dnf"
- name: centos8 dnf Install
  dnf: 
    name:  
      - epel-release
    state: latest
  when: ansible_pkg_mgr == "dnf"
- name: centos8 dnf Install
  dnf: 
    name:
      - pcre-devel
      - ipvsadm
      - bzip2-devel
      - gcc
      - gcc-c++
      - make
      - systemd-devel
      - openssl-devel
      - libnfnetlink-devel
      - popt-devel
      - libnfnetlink
      - kernel-devel
      - autoconf
      - perl
      - rsyslog
    state: latest
  when: ansible_pkg_mgr == "dnf"
- name: centos7 yum Install
  yum: 
    name:  
      - epel-release
      - yum-plugin-fastestmirror
    state: latest
  when: ansible_pkg_mgr == "yum"
- name: centos7 yum Install
  yum: 
    name:
      - pcre-devel
      - ipvsadm
      - bzip2-devel
      - gcc
      - gcc-c++
      - make
      - systemd-devel
      - openssl-devel
      - libnfnetlink-devel
      - popt-devel
      - libnfnetlink
      - kernel-devel
      - autoconf
      - perl-Thread-Queue
      - perl
      - rsyslog
    state: latest
  when: ansible_pkg_mgr == "yum"
- name: Only run "update_cache=yes" if the last one is more than 3600 seconds ago
  apt:
    update_cache: yes
    cache_valid_time: 3600
  when: ansible_pkg_mgr == "apt"  
- name: ubuntu apt Install
  apt: 
    name:
      - ipvsadm
      - libssl-dev
      - libnfnetlink-dev
      - libpopt-dev
      - linux-libc-dev
      - kernel-package
      - autoconf 
      - perl
      - libsystemd-dev
      - make
      - gcc 
      - libbz2-dev
      - libpcre3-dev
      - zlib1g-dev
      - rsyslog
    state: latest
  when: ansible_pkg_mgr == "apt"
- name: copy to keepalived and automake
  copy: src={{ item }}  dest=${SOURCE_PATH}/
  with_items:
      - automake-${AUTOMAKE_VERSION}.tar.gz
      - keepalived-${KEEPALIVED_VERSION}.tar.gz      
- name: tar -xvf automake-${AUTOMAKE_VERSION}.tar.gz
  raw: tar -xvf ${SOURCE_PATH}/automake-${AUTOMAKE_VERSION}.tar.gz -C  ${SOURCE_PATH}/
- name: make to automake
  raw: cd  ${SOURCE_PATH}/automake-${AUTOMAKE_VERSION} && ./configure  
- name: make automake
  raw: cd  ${SOURCE_PATH}/automake-${AUTOMAKE_VERSION}  && make && make install 
- name: tar -xvf keepalived-${KEEPALIVED_VERSION}.tar.gz 
  raw: tar -xvf  ${SOURCE_PATH}/keepalived-${KEEPALIVED_VERSION}.tar.gz -C  ${SOURCE_PATH}/
- name: make to keepalived 
  raw: cd  ${SOURCE_PATH}/keepalived-${KEEPALIVED_VERSION} && /usr/local/bin/automake --add-missing  && /usr/local/bin/automake && ./configure --prefix=${KEEPALIVED_PATH} && make && make install
- name: copy to keepalived
  template: src=keepalived dest=${KEEPALIVED_PATH}/etc/sysconfig/
- name: copy to keepalived.conf
  template: src=keepalived.conf dest=${KEEPALIVED_PATH}/etc/keepalived/
- name: copy systemd keepalived
  template: src=keepalived.service dest=/lib/systemd/system/keepalived.service
- name: Reload service daemon-reload
  shell: systemctl daemon-reload
- name: Enable service keepalived, and not touch the state
  service:
    name: keepalived
    enabled: yes
- name: Start service keepalived, if not started
  service:
    name: keepalived
    state: started
EOF
# 创建  keepalived 启动文件配置
cat << EOF | tee ${HOST_PATH}/roles/keepalived/templates/keepalived
KEEPALIVED_OPTIONS="-D \
                    --use-file=${KEEPALIVED_PATH}/etc/keepalived/keepalived.conf"
EOF
# 创建 keepalived 配置文件
cat << EOF | tee ${HOST_PATH}/roles/keepalived/templates/keepalived.conf
\# keepalived configure 

global_defs {
   router_id                                 {{ ROUTER_ID }}
}
############################### VRRP-SCRIPT ####################################

vrrp_script check_haproxy {
  script "killall -0 haproxy"
  interval 3
  weight -2
  fall 10
  rise 2
}
############################### HAPROXY-HA ########################################
vrrp_instance HAPROXY_HA1 {
    state                                  {{ STATE_1 }}
   interface                              {{ IFACE }}
   virtual_router_id                          55
   priority                                {{ HA1_ID }}
   advert_int                                1

    authentication {
       auth_type                             PASS
       auth_pass                             99ce6e3381dc326633737ddaf5d904d2
    }
    virtual_ipaddress {
       ${K8S_VIP_1_IP}                           label {{ IFACE }}:HA1
    }
    track_script {
       check_haproxy
    }
}

vrrp_instance HAPROXY_HA2 {
    state                                   {{ STATE_2 }}
   interface                              {{ IFACE }}
   virtual_router_id                          56
   priority                                {{ HA2_ID }}
   advert_int                                1

    authentication {
       auth_type                             PASS
       auth_pass                             99ce6e3381dc326633737ddaf5d904d2
    }
    virtual_ipaddress {
        ${K8S_VIP_2_IP}                           label {{ IFACE }}:HA2
    }
    track_script {
       check_haproxy
    }
}    
    
vrrp_instance HAPROXY_HA3 {
    state                                 {{ STATE_3 }}
   interface                              {{ IFACE }}
   virtual_router_id                          57
   priority                               {{ HA3_ID }}
   advert_int                                1

    authentication {
       auth_type                             PASS
       auth_pass                             99ce6e3381dc326633737ddaf5d904d2
    }
    virtual_ipaddress {
        ${K8S_VIP_3_IP}                           label {{ IFACE }}:HA3
    }
    track_script {
       check_haproxy
    }
}
EOF
# 创建keepalived 启动文件
cat << EOF | tee ${HOST_PATH}/roles/keepalived/templates/keepalived.service

[Install]
WantedBy=multi-user.target
 [Unit]
Description=LVS and VRRP High Availability Monitor
After=network-online.target syslog.target 
Wants=network-online.target 

[Service]
Type=forking
LimitNOFILE=1024000
LimitNPROC=1024000
LimitCORE=infinity
LimitMEMLOCK=infinity
PIDFile=/var/run/keepalived.pid
KillMode=process
EnvironmentFile=-${KEEPALIVED_PATH}/etc/sysconfig/keepalived
ExecStart=${KEEPALIVED_PATH}/sbin/keepalived \$KEEPALIVED_OPTIONS
ExecReload=/bin/kill -HUP \$MAINPID

[Install]
WantedBy=multi-user.target
EOF
# 复制 keepalived 源码包到 playbook
\cp -pdr ${TEMP_PATH}/{automake-${AUTOMAKE_VERSION}.tar.gz,keepalived-${KEEPALIVED_VERSION}.tar.gz} ${HOST_PATH}/roles/keepalived/files/

cat << EOF | tee ${HOST_PATH}/keepalived.yml
- hosts: all
  user: root
  vars:
   IFACE: "${IFACE}"
   ROUTER_ID: HA1
   HA1_ID: 100
   HA2_ID: 110
   HA3_ID: 120
   STATE_1: BACKUP
   STATE_2: BACKUP
   STATE_3: BACKUP
  roles:
   - keepalived
EOF
# 创建kube-controller-manager playbook
cat << EOF | tee ${HOST_PATH}/roles/kube-controller-manager/tasks/main.yml
- name: create groupadd k8s
  group: name=k8s
- name: create name k8s
  user: name=k8s shell="/sbin/nologin k8s" group=k8s
- name:  mkdir ${K8S_PATH}
  raw: mkdir -p ${K8S_PATH}/{log,kubelet-plugins,conf} && mkdir -p ${K8S_PATH}/kubelet-plugins/volume
- name: copy kube-controller-manager
  copy: src=bin dest=${K8S_PATH}/ owner=k8s group=root mode=755
- name: copy  ssl
  copy: src={{ item }} dest=${K8S_PATH}/ owner=k8s group=root
  with_items:
      - ssl
- name: kube-controller-manager conf
  template: src=kube-controller-manager dest=${K8S_PATH}/conf owner=k8s group=root
- name: kube-controller-manager config
  template: src=kube-controller-manager.kubeconfig dest=${K8S_PATH}/config owner=k8s group=root
- name: copy kube-controller-manager.service
  template: src=kube-controller-manager.service  dest=/lib/systemd/system/
- name: chown -R k8s
  shell: chown -R k8s:root ${K8S_PATH}/
- name: Reload service daemon-reload
  shell: systemctl daemon-reload
- name: Enable service kube-controller-manager, and not touch the state
  service:
    name: kube-controller-manager
    enabled: yes
- name: Start service kube-controller-manager, if not started
  service:
    name: kube-controller-manager
    state: started
EOF
# 创建kube-controller-manager 启动配置文件
cat << EOF | tee ${HOST_PATH}/roles/kube-controller-manager/templates/kube-controller-manager
KUBE_CONTROLLER_MANAGER_OPTS="--logtostderr=false \\
--leader-elect=true \\
--address=0.0.0.0 \\
--service-cluster-ip-range=${SERVICE_CIDR} \\
--cluster-cidr=${CLUSTER_CIDR} \\
--node-cidr-mask-size=24 \\
--cluster-name=kubernetes \\
--allocate-node-cidrs=true \\
--kubeconfig=${K8S_PATH}/config/kube-controller-manager.kubeconfig \\
--authentication-kubeconfig=${K8S_PATH}/config/kube-controller-manager.kubeconfig \\
--authorization-kubeconfig=${K8S_PATH}/config/kube-controller-manager.kubeconfig \\
--use-service-account-credentials=true \\
--client-ca-file=${K8S_PATH}/ssl/k8s/k8s-ca.pem \\
--requestheader-client-ca-file=${K8S_PATH}/ssl/k8s/k8s-ca.pem \\
--node-monitor-grace-period=40s \\
--node-monitor-period=5s \\
--pod-eviction-timeout=5m0s \\
--terminated-pod-gc-threshold=50 \\
--alsologtostderr=true \\
--cluster-signing-cert-file=${K8S_PATH}/ssl/k8s/k8s-ca.pem \\
--cluster-signing-key-file=${K8S_PATH}/ssl/k8s/k8s-ca-key.pem  \\
--deployment-controller-sync-period=10s \\
--experimental-cluster-signing-duration=${EXPIRY_TIME}0m0s \\
--enable-garbage-collector=true \\
--root-ca-file=${K8S_PATH}/ssl/k8s/k8s-ca.pem \\
--service-account-private-key-file=${K8S_PATH}/ssl/k8s/k8s-ca-key.pem \\
--feature-gates=RotateKubeletServerCertificate=true,RotateKubeletClientCertificate=true \\
--controllers=*,bootstrapsigner,tokencleaner \\
--horizontal-pod-autoscaler-use-rest-clients=true \\
--horizontal-pod-autoscaler-sync-period=10s \\
--flex-volume-plugin-dir=${K8S_PATH}/kubelet-plugins/volume \\
--tls-cert-file=${K8S_PATH}/ssl/k8s/k8s-controller-manager.pem \\
--tls-private-key-file=${K8S_PATH}/ssl/k8s/k8s-controller-manager-key.pem \\
--kube-api-qps=${KUBE_API_QPS} \\
--kube-api-burst=${KUBE_API_BURST} \\
--log-dir=${K8S_PATH}/log \\
--v=${LEVEL_LOG}"
EOF
# 创建kube-controller-manager 启动文件
cat << EOF | tee ${HOST_PATH}/roles/kube-controller-manager/templates/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
LimitNOFILE=1024000
LimitNPROC=1024000
LimitCORE=infinity
LimitMEMLOCK=infinity
EnvironmentFile=-${K8S_PATH}/conf/kube-controller-manager
ExecStart=${K8S_PATH}/bin/kube-controller-manager \$KUBE_CONTROLLER_MANAGER_OPTS
Restart=on-failure
RestartSec=5
User=k8s

[Install]
WantedBy=multi-user.target
EOF
# cp 二进制文件及ssl及kubeconfig 文件到 ansible 目录 
mkdir -p ${HOST_PATH}/roles/kube-controller-manager/files/{ssl,bin}
mkdir -p ${HOST_PATH}/roles/kube-controller-manager/files/ssl/k8s
\cp -pdr ${TEMP_PATH}/kubernetes/server/bin/kube-controller-manager ${HOST_PATH}/roles/kube-controller-manager/files/bin
\cp -pdr ${HOST_PATH}/cfssl/pki/k8s/{k8s-controller-manager*.pem,k8s-ca*.pem} ${HOST_PATH}/roles/kube-controller-manager/files/ssl/k8s
# 复制kube-controller-manager.kubeconfig 文件
\cp -pdr ${HOST_PATH}/kubeconfig/kube-controller-manager.kubeconfig ${HOST_PATH}/roles/kube-controller-manager/templates/
# 修改kube-controller-manager.kubeconfig 为连接当前主机api ip地址
sed -i "s/${K8S_VIP_DOMAIN}:${K8S_VIP_PORT}/{{ $API_IPV4 }}:${SECURE_PORT}/" ${HOST_PATH}/roles/kube-controller-manager/templates/kube-controller-manager.kubeconfig
# 
cat << EOF | tee ${HOST_PATH}/kube-controller-manager.yml
- hosts: all
  user: root
  roles:
    - kube-controller-manager
EOF
# 创建kube-scheduler playbook 
cat << EOF | tee ${HOST_PATH}/roles/kube-scheduler/tasks/main.yml
- name: create groupadd k8s
  group: name=k8s
- name: create name k8s
  user: name=k8s shell="/sbin/nologin k8s" group=k8s
- name:  mkdir ${K8S_PATH}
  raw: mkdir -p ${K8S_PATH}/{log,kubelet-plugins,conf} && mkdir -p ${K8S_PATH}/kubelet-plugins/volume
- name: copy kube-scheduler
  copy: src=bin dest=${K8S_PATH}/ owner=k8s group=root mode=755
- name: copy  ssl
  copy: src={{ item }} dest=${K8S_PATH}/ owner=k8s group=root
  with_items:
      - ssl
- name: kube-scheduler conf
  template: src=kube-scheduler dest=${K8S_PATH}/conf owner=k8s group=root
- name: kube-scheduler config
  template: src=kube-scheduler.kubeconfig dest=${K8S_PATH}/config owner=k8s group=root
- name: copy kube-scheduler.service
  template: src=kube-scheduler.service  dest=/lib/systemd/system/
- name: chown -R k8s
  shell: chown -R k8s:root ${K8S_PATH}/
- name: Reload service daemon-reload
  shell: systemctl daemon-reload
- name: Enable service kube-scheduler, and not touch the state
  service:
    name: kube-scheduler
    enabled: yes
- name: Start service kube-scheduler, if not started
  service:
    name: kube-scheduler
    state: started
EOF
# 创建kube-scheduler 启动配置文件
cat << EOF | tee ${HOST_PATH}/roles/kube-scheduler/templates/kube-scheduler
KUBE_SCHEDULER_OPTS=" \\
                   --logtostderr=false \\
                   --address=0.0.0.0 \\
                   --leader-elect=true \\
                   --kubeconfig=${K8S_PATH}/config/kube-scheduler.kubeconfig \\
                   --authentication-kubeconfig=${K8S_PATH}/config/kube-scheduler.kubeconfig \\
                   --authorization-kubeconfig=${K8S_PATH}/config/kube-scheduler.kubeconfig \\
                   --requestheader-client-ca-file=${K8S_PATH}/k8s/ssl/k8s/k8s-ca.pem \\
                   --client-ca-file=${K8S_PATH}/k8s/ssl/k8s/k8s-ca.pem \\
                   --alsologtostderr=true \\
                   --kube-api-qps=${KUBE_API_QPS} \\
                   --kube-api-burst=${KUBE_API_BURST} \\
                   --log-dir=${K8S_PATH}/log \\
                   --v=${LEVEL_LOG}"
EOF
# 创建kube-scheduler 启动文件
cat << EOF | tee ${HOST_PATH}/roles/kube-scheduler/templates/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
LimitNOFILE=1024000
LimitNPROC=1024000
LimitCORE=infinity
LimitMEMLOCK=infinity

EnvironmentFile=-${K8S_PATH}/conf/kube-scheduler
ExecStart=${K8S_PATH}/bin/kube-scheduler \$KUBE_SCHEDULER_OPTS
Restart=on-failure
RestartSec=5
User=k8s

[Install]
WantedBy=multi-user.target
EOF
# cp 二进制文件及ssl及kubeconfig 文件到 ansible 目录 
mkdir -p ${HOST_PATH}/roles/kube-scheduler/files/bin
mkdir -p ${HOST_PATH}/roles/kube-scheduler/files/ssl/k8s
\cp -pdr ${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem ${HOST_PATH}/roles/kube-scheduler/files/ssl/k8s
\cp -pdr ${TEMP_PATH}/kubernetes/server/bin/kube-scheduler ${HOST_PATH}/roles/kube-scheduler/files/bin
# 复制kube-controller-manager.kubeconfig 文件
\cp -pdr ${HOST_PATH}/kubeconfig/kube-scheduler.kubeconfig ${HOST_PATH}/roles/kube-scheduler/templates/
# 修改kube-scheduler.kubeconfig 为连接当前主机api ip地址
sed -i "s/${K8S_VIP_DOMAIN}:${K8S_VIP_PORT}/{{ $API_IPV4 }}:${SECURE_PORT}/" ${HOST_PATH}/roles/kube-scheduler/templates/kube-scheduler.kubeconfig
#
cat << EOF | tee ${HOST_PATH}/kube-scheduler.yml
- hosts: all
  user: root
  roles:
    - kube-scheduler
EOF
# 生成node 节点 ansible配置
# iptables playbook 配置
cat << EOF | tee ${HOST_PATH}/roles/iptables/tasks/main.yml
- name: centos8 enabled CentOS-PowerTools.repo
  raw: sed -i "s/enabled=0/enabled=1/" /etc/yum.repos.d/CentOS-PowerTools.repo
  when: ansible_pkg_mgr == "dnf"
- name: centos8 dnf Install
  dnf:
    name:
      - epel-release
    state: latest
  when: ansible_pkg_mgr == "dnf"
- name: centos8 dnf Install
  dnf:
    name:
      - gcc
      - make
    state: latest
  when: ansible_pkg_mgr == "dnf"
- name: centos7 yum Install
  yum: 
    name:  
      - epel-release
      - yum-plugin-fastestmirror
    state: latest
  when: ansible_pkg_mgr == "yum"
- name: centos7 yum Install
  yum: 
    name:
      - gcc 
      - make 
      - libnftnl-devel 
      - libmnl-devel 
      - autoconf 
      - automake 
      - libtool 
      - bison 
      - flex
      - lbzip2
      - libnetfilter_conntrack-devel 
      - libnetfilter_queue-devel 
      - libpcap-devel
    state: latest
  when: ansible_pkg_mgr == "yum"
- name: Only run "update_cache=yes" 
  apt:
    update_cache: yes
  when: ansible_pkg_mgr == "apt"  
- name: ubuntu apt Install
  apt: 
    name:
      - gcc 
      - make 
      - libnftnl-dev 
      - libmnl-dev
      - autoconf 
      - automake 
      - libtool 
      - bison 
      - flex  
      - libnetfilter-conntrack-dev 
      - libnetfilter-queue-dev 
      - libpcap-dev
    state: latest
  when: ansible_pkg_mgr == "apt"
- name: copy to iptables
  copy: src=iptables-${IPTABLES_VERSION}.tar.bz2  dest=${SOURCE_PATH}
- name: tar iptables-${IPTABLES_VERSION}.tar.bz2
  raw: tar -xvf  ${SOURCE_PATH}/iptables-${IPTABLES_VERSION}.tar.bz2 -C  ${SOURCE_PATH}
- name: configure to iptables
  shell: cd  ${SOURCE_PATH}/iptables-${IPTABLES_VERSION} && ./configure --disable-nftables
- name: make install
  shell:  cd  ${SOURCE_PATH}/iptables-${IPTABLES_VERSION} && make -j4 &&  make install
EOF
# 复制 iptables 源码到 playbook
\cp -pdr ${TEMP_PATH}/iptables-${IPTABLES_VERSION}.tar.bz2 ${HOST_PATH}/roles/iptables/files/iptables-${IPTABLES_VERSION}.tar.bz2
cat << EOF | tee ${HOST_PATH}/iptables.yml
- hosts: all
  user: root
  roles:
    - iptables
EOF
# node 二进制包依赖安装
cat << EOF | tee ${HOST_PATH}/roles/package/tasks/main.yml
- name: centos8 dnf Install
  dnf: 
    name:  
      - epel-release
    state: latest
  when: ansible_pkg_mgr == "dnf"
- name: centos8 dnf Install
  dnf: 
    name:
      - dnf-utils
      - ipvsadm
      - telnet
      - wget
      - net-tools
      - conntrack
      - ipset
      - jq
      - iptables
      - curl
      - sysstat
      - libseccomp
      - socat
      - nfs-utils
      - fuse
      - lvm2
      - device-mapper-persistent-data
      - fuse-devel
    state: latest
  when: ansible_pkg_mgr == "dnf"
- name: centos7 yum Install
  yum: 
    name:  
      - epel-release
      - yum-plugin-fastestmirror
    state: latest
  when: ansible_pkg_mgr == "yum"
- name: centos7 yum Install
  yum: 
    name:
      - yum-utils
      - ipvsadm
      - telnet
      - wget
      - net-tools
      - conntrack
      - ipset
      - jq
      - iptables
      - curl
      - sysstat
      - libseccomp
      - socat
      - nfs-utils
      - fuse
      - lvm2
      - device-mapper-persistent-data
      - fuse-devel
      - ceph-common
    state: latest
  when: ansible_pkg_mgr == "yum"
- name: Only run "update_cache=yes"
  apt:
    update_cache: yes
  when: ansible_pkg_mgr == "apt"
- name: ubuntu apt Install
  apt: 
    name:
      - ipvsadm
      - telnet
      - wget
      - net-tools
      - conntrack
      - ipset
      - jq
      - iptables
      - curl
      - sysstat
      - libltdl7
      - libseccomp2
      - socat
      - nfs-common
      - fuse
      - ceph-common
      - software-properties-common
    state: latest
  when: ansible_pkg_mgr == "apt" 
EOF
#
cat << EOF | tee ${HOST_PATH}/package.yml
- hosts: all
  user: root
  roles:
    - package
EOF
# 创建 lxcfs playbook
cat << EOF | tee ${HOST_PATH}/roles/lxcfs/tasks/main.yml
- name: copy /usr/local/lib/lxcfs
  copy: src=lib dest=/usr/local/
- name: up lxcfs
  copy: src=lxcfs dest=/usr/local/bin/lxcfs owner=root group=root mode=755
- name: up lxcfs.service
  copy: src=lxcfs.service dest=/lib/systemd/system/lxcfs.service
- name: create /var/lib/lxcfs
  shell: mkdir -p /var/lib/lxcfs
- name: Reload service daemon-reload
  shell: systemctl daemon-reload
- name: Enable service lxcfs, and not touch the state
  service:
    name: lxcfs
    enabled: yes
- name: Start service lxcfs, if not started
  service:
    name: lxcfs
    state: started
EOF
# 创建lxcfs 启动文件
cat << EOF | tee ${HOST_PATH}/roles/lxcfs/files/lxcfs.service
[Unit]
Description=FUSE filesystem for LXC
ConditionVirtualization=!container
Before=lxc.service
Documentation=man:lxcfs(1)

[Service]
ExecStart=/usr/local/bin/lxcfs -s -f -o allow_other /var/lib/lxcfs/
KillMode=process
Restart=on-failure
ExecStopPost=-/bin/fusermount -u /var/lib/lxcfs
Delegate=yes
ExecReload=/bin/kill -USR1 \$MAINPID
[Install]
WantedBy=multi-user.target
EOF
# cp 二进制文件到 ansible 目录
tar -xf ${TEMP_PATH}/lxcfs-${LXCFS_VERSION}.tar.gz -C ${TEMP_PATH}
\cp -pdr ${TEMP_PATH}/lxcfs-${LXCFS_VERSION}/* ${HOST_PATH}/roles/lxcfs/files/
#
cat << EOF | tee ${HOST_PATH}/lxcfs.yml
- hosts: all
  user: root
  roles:
    - lxcfs
EOF
#docker 二进制安装playbook　
cat << EOF | tee ${HOST_PATH}/roles/docker/tasks/main.yml
- name: create groupadd docker
  group: name=docker
- name:  mkdir ${DOCKER_BIN_PATH}
  raw: mkdir -p ${DOCKER_BIN_PATH} && mkdir -p /etc/docker &&  mkdir -p /etc/containerd
- name: copy docker ${DOCKER_BIN_PATH}
  copy: src=bin/ dest=${DOCKER_BIN_PATH}/ owner=root group=root mode=755
- stat: path=/usr/bin/docker
  register: docker_path_register
- name: PATH 
  raw: echo "export PATH=\\\$PATH:${DOCKER_BIN_PATH}" >> /etc/profile
  when: docker_path_register.stat.exists == False
- name: daemon.json conf
  template: src=daemon.json dest=/etc/docker owner=root group=root
- name: config.toml
  shell: ${DOCKER_BIN_PATH}/containerd config default >/etc/containerd/config.toml
- name: ln runc containerd-shim
  raw: ln -s ${DOCKER_BIN_PATH}/runc /usr/bin/runc && ln -s ${DOCKER_BIN_PATH}/containerd-shim /usr/bin/containerd-shim
  when: docker_path_register.stat.exists == False
  ignore_errors: True
  
- name: copy "{{ item }}"
  template: src={{ item }} dest=/lib/systemd/system/ owner=root group=root
  with_items:
      - containerd.service
      - docker.socket
      - docker.service
- name: Reload service daemon-reload
  shell: systemctl daemon-reload
- name: Enable service docker, and not touch the state
  service:
    name: docker
    enabled: yes
- name: Start service docker, if not started
  service:
    name: docker
    state: started
EOF
# docker 配置文件生成　
cat << EOF | tee ${HOST_PATH}/roles/docker/templates/daemon.json
{
    "max-concurrent-downloads": 20,
    "data-root": "${DOCKER_PATH}/data",
    "exec-root": "${DOCKER_PATH}/root",
    "log-driver": "json-file",
    "bridge": "${NET_BRIDGE}",
    "oom-score-adjust": -1000,
    "debug": false,
    "log-opts": {
        "max-size": "100M",
        "max-file": "10"
    },
    "default-ulimits": {
        "nofile": {
            "Name": "nofile",
            "Hard": 1024000,
            "Soft": 1024000
        },
        "nproc": {
            "Name": "nproc",
            "Hard": 1024000,
            "Soft": 1024000
        },
       "core": {
            "Name": "core",
            "Hard": -1,
            "Soft": -1
      }
    
    }
}
EOF
# 生成containerd 启动服务文件
cat << EOF | tee ${HOST_PATH}/roles/docker/templates/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=${DOCKER_BIN_PATH}/containerd
KillMode=process
Delegate=yes
LimitNOFILE=1024000
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity

[Install]
WantedBy=multi-user.target
EOF
# 生成docker.socket 文件
cat << EOF | tee ${HOST_PATH}/roles/docker/templates/docker.socket
[Unit]
Description=Docker Socket for the API
PartOf=docker.service

[Socket]
ListenStream=/var/run/docker.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF
if [ "${DOCKER_BIN_PATH}" == "/usr/bin" ]; then
        ENVIRONMENT_PATH=""
else
        ENVIRONMENT_PATH="Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin:${DOCKER_BIN_PATH}:/root/bin"
fi
# 生成docker 启动文件
cat << EOF | tee ${HOST_PATH}/roles/docker/templates/docker.service
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
BindsTo=containerd.service
After=network-online.target firewalld.service containerd.service
Wants=network-online.target
Requires=docker.socket

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
${ENVIRONMENT_PATH}
ExecStart=${DOCKER_BIN_PATH}/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
ExecReload=/bin/kill -s HUP \$MAINPID
TimeoutSec=0
RestartSec=2
Restart=always

# Note that StartLimit* options were moved from "Service" to "Unit" in systemd 229.
# Both the old, and new location are accepted by systemd 229 and up, so using the old location
# to make them work for either version of systemd.
StartLimitBurst=3

# Note that StartLimitInterval was renamed to StartLimitIntervalSec in systemd 230.
# Both the old, and new name are accepted by systemd 230 and up, so using the old name to make
# this option work for either version of systemd.
StartLimitInterval=60s

# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=1024000
LimitNPROC=1024000
LimitCORE=infinity

# Comment TasksMax if your systemd version does not support it.
# Only systemd 226 and above support this option.
TasksMax=infinity

# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes

# kill only the docker process, not all processes in the cgroup
KillMode=process

[Install]
WantedBy=multi-user.target
EOF
# cp 二进制文件到 ansible 目录 
mkdir -p ${HOST_PATH}/roles/docker/files/bin
tar -xf ${TEMP_PATH}/docker-${DOCKER_VERSION}.tgz -C ${TEMP_PATH}
\cp -pdr ${TEMP_PATH}/docker/* ${HOST_PATH}/roles/docker/files/bin
#
cat << EOF | tee ${HOST_PATH}/docker.yml
- hosts: all
  user: root
  roles:
    - docker
EOF
#cni 二进制安装playbook
cat << EOF | tee ${HOST_PATH}/roles/cni/tasks/main.yml
- name: create cni
  shell: mkdir -p ${CNI_PATH} && mkdir -p ${CNI_PATH}/etc/net.d/
- name: copy to cni
  copy: src=bin dest=${CNI_PATH}/ owner=root group=root mode=755
EOF
# cp 二进制文件到 ansible 目录 
mkdir -p ${TEMP_PATH}/cni/bin
tar -xf ${TEMP_PATH}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz -C ${TEMP_PATH}/cni/bin
\cp -pdr ${TEMP_PATH}/cni/bin ${HOST_PATH}/roles/cni/files/bin
#
cat << EOF | tee ${HOST_PATH}/cni.yml
- hosts: all
  user: root
  roles:
    - cni
EOF
# kubelet 二进制安装playbook
cat << EOF | tee ${HOST_PATH}/roles/kubelet/tasks/main.yml
- name: create ${K8S_PATH}/{log,kubelet-plugins,conf}
  raw: mkdir -p ${K8S_PATH}/{log,kubelet-plugins,conf} && mkdir -p ${POD_MANIFEST_PATH}/kubernetes/manifests
- name: copy kubelet to ${K8S_PATH}
  copy: src=bin dest=${K8S_PATH}/ owner=root group=root mode=755
- name: copy kubelet ssl
  copy: src=ssl dest=${K8S_PATH}/
- name: copy to kubelet config
  template: src={{ item }} dest=${K8S_PATH}/conf
  with_items:
      - kubelet
      - bootstrap.kubeconfig
- name:  copy to kubelet service
  template: src={{ item }} dest=/lib/systemd/system/
  with_items:
      - kubelet.service
- name: Reload service daemon-reload
  shell: systemctl daemon-reload
- name: Enable service kubelet, and not touch the state
  service:
    name: kubelet
    enabled: yes
- name: Start service kubelet, if not started
  service:
    name: kubelet
    state: started
EOF
# 创建kubelet 启动配置文件
cat << EOF | tee ${HOST_PATH}/roles/kubelet/templates/kubelet
KUBELET_OPTS="--bootstrap-kubeconfig=${K8S_PATH}/conf/bootstrap.kubeconfig \\
              --fail-swap-on=false \\
              --network-plugin=cni \\
              --cni-conf-dir=${CNI_PATH}/etc/net.d \\
              --cni-bin-dir=${CNI_PATH}/bin \\
              --kubeconfig=${K8S_PATH}/conf/kubelet.kubeconfig \\
              --address={{ $KUBELET_IPV4 }} \\
              --node-ip={{ $KUBELET_IPV4 }} \\
              --hostname-override={{ ansible_hostname }} \\
              --cluster-dns=${CLUSTER_DNS_SVC_IP} \\
              --cluster-domain=${CLUSTER_DNS_DOMAIN} \\
              --authorization-mode=Webhook \\
              --authentication-token-webhook=true \\
              --client-ca-file=${K8S_PATH}/ssl/k8s/k8s-ca.pem \\
              --rotate-certificates=true \\
              --cgroup-driver=cgroupfs \\
              --healthz-port=10248 \\
              --healthz-bind-address={{ $KUBELET_IPV4 }} \\
              --cert-dir=${K8S_PATH}/ssl \\
              --feature-gates=RotateKubeletClientCertificate=true,RotateKubeletServerCertificate=true \\
              --serialize-image-pulls=false \\
              --enforce-node-allocatable=pods,kube-reserved,system-reserved \\
              --pod-manifest-path=${POD_MANIFEST_PATH}/kubernetes/manifests \\
              --runtime-cgroups=/systemd/system.slice \\
              --kubelet-cgroups=/systemd/system.slice \\
              --kube-reserved-cgroup=/systemd/system.slice \\
              --system-reserved-cgroup=/systemd/system.slice \\
              --root-dir=${POD_MANIFEST_PATH}/kubernetes/kubelet \\
              --log-dir=${K8S_PATH}/log \\
              --alsologtostderr=true \\
              --logtostderr=false \\
              --anonymous-auth=false \\
              --image-gc-high-threshold=70 \\
              --image-gc-low-threshold=50 \\
              --kube-reserved=cpu=500m,memory=512Mi,ephemeral-storage=1Gi \\
              --system-reserved=cpu=1000m,memory=1024Mi,ephemeral-storage=1Gi \\
              --eviction-hard=memory.available<500Mi,nodefs.available<10% \\
              --node-status-update-frequency=10s \\
              --eviction-pressure-transition-period=20s \\
              --serialize-image-pulls=false \\
              --sync-frequency=30s \\
              --resolv-conf=/etc/resolv.conf \\
              --pod-infra-container-image=${POD_INFRA_CONTAINER_IMAGE} \\
              --image-pull-progress-deadline=30s \\
              --v=${LEVEL_LOG} \\
              --event-burst=30 \\
              --event-qps=15 \\
              --kube-api-burst=30 \\
              --kube-api-qps=15 \\
              --max-pods=${MAX_PODS} \\
              --pods-per-core=${PODS_PER_CORE} \\
              --read-only-port=0 \\
              --allowed-unsafe-sysctls 'kernel.msg*,kernel.shm*,kernel.sem,fs.mqueue.*,net.*' \\
              --volume-plugin-dir=${K8S_PATH}/kubelet-plugins/volume"
EOF
# 创建kubelet 启动文件
cat << EOF | tee ${HOST_PATH}/roles/kubelet/templates/kubelet.service
[Unit]
Description=Kubernetes Kubelet
After=docker.service
Requires=docker.service

[Service]
LimitNOFILE=1024000
LimitNPROC=1024000
LimitCORE=infinity
LimitMEMLOCK=infinity
EnvironmentFile=-${K8S_PATH}/conf/kubelet
ExecStart=${K8S_PATH}/bin/kubelet \$KUBELET_OPTS
Restart=on-failure
KillMode=process
[Install]
WantedBy=multi-user.target
EOF
# cp 二进制文件及ssl及kubeconfig 文件到 ansible 目录 
mkdir -p ${HOST_PATH}/roles/kubelet/files/{bin,ssl}
mkdir -p ${HOST_PATH}/roles/kubelet/files/ssl/k8s
\cp -pdr ${TEMP_PATH}/kubernetes/server/bin/kubelet ${HOST_PATH}/roles/kubelet/files/bin
# 复制ssl
\cp -pdr ${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem ${HOST_PATH}/roles/kubelet/files/ssl/k8s/
# 复制bootstrap.kubeconfig 文件
\cp -pdr ${HOST_PATH}/kubeconfig/bootstrap.kubeconfig ${HOST_PATH}/roles/kubelet/templates/
cat << EOF | tee ${HOST_PATH}/kubelet.yml
- hosts: all
  user: root
  roles:
    - kubelet
EOF
#配置网络插件
mkdir ${HOST_PATH}/yaml
if [ ${NET_PLUG} == 1 ]; then
cat << EOF | tee ${HOST_PATH}/yaml/kube-router.yaml
apiVersion: v1
kind: Secret
metadata:
  name: kube-proxy
  namespace: kube-system
  labels:
    tier: node
    k8s-app: kube-router
data:
  kubeconfig.conf: `cat ${HOST_PATH}/kubeconfig/kube-router.kubeconfig|base64 | tr -d '\n'`
    
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-router-cfg
  namespace: kube-system
  labels:
    tier: node
    k8s-app: kube-router
data:
  cni-conf.json: |
    {
       "cniVersion":"0.3.0",
       "name":"cni0",
       "plugins":[
          {
             "name":"kubernetes",
             "type":"bridge",
             "bridge":"kube-bridge",
             "isDefaultGateway":true,
             "hairpinMode":true,
             "mtu":1450,
             "ipam":{
                "type":"host-local"
             }
          },
          {
             "type":"portmap",
             "capabilities":{
                "snat":true,
                "portMappings":true
             }
          }
       ]
    }

---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  labels:
    k8s-app: kube-router
    tier: node
  name: kube-router
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: kube-router
  template:
    metadata:
      labels:
        k8s-app: kube-router
        tier: node
      annotations:
        scheduler.alpha.kubernetes.io/critical-pod: ''
        prometheus.io/scrape: "true"
        prometheus.io/port: "20241"        
    spec:
      serviceAccountName: kube-router
      serviceAccount: kube-router
      containers:
      - name: kube-router
        image: docker.io/cloudnativelabs/kube-router
        imagePullPolicy: Always
        args:
        - --run-router=true 
        - --run-firewall=true 
        - --run-service-proxy=true 
        - --advertise-cluster-ip=true 
        - --advertise-loadbalancer-ip=true 
        - --advertise-pod-cidr=true 
        - --advertise-external-ip=true
        - --hairpin-mode=true      
        - --cluster-asn=64512 
        - --metrics-path=/metrics 
        - --metrics-port=20241 
        - --enable-cni=true 
        - --enable-ibgp=true      
        - --enable-overlay=true 
        - --nodeport-bindon-all-ip=true 
        - --nodes-full-mesh=true 
        - --enable-pod-egress=true 
        - --cluster-cidr=${CLUSTER_CIDR}
        - --v=${LEVEL_LOG}
        - --kubeconfig=/var/lib/kube-router/kubeconfig
        env:
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        - name: KUBE_ROUTER_CNI_CONF_FILE
          value: /etc/cni/net.d/10-kuberouter.conflist
        livenessProbe:
          httpGet:
            path: /healthz
            port: 20244
          initialDelaySeconds: 10
          periodSeconds: 3
        resources:
          requests:
            cpu: 250m
            memory: 250Mi
        securityContext:
          privileged: true
        volumeMounts:
        - name: lib-modules
          mountPath: /lib/modules
          readOnly: true
        - name: cni-conf-dir
          mountPath: /etc/cni/net.d
        - name: kubeconfig
          mountPath: /var/lib/kube-router
          readOnly: true
      initContainers:
      - name: install-cni
        image: busybox
        imagePullPolicy: Always
        command:
        - /bin/sh
        - -c
        - set -e -x;
          if [ ! -f /etc/cni/net.d/10-kuberouter.conflist ]; then
            if [ -f /etc/cni/net.d/*.conf ]; then
              rm -f /etc/cni/net.d/*.conf;
            fi;
            TMP=/etc/cni/net.d/.tmp-kuberouter-cfg;
            cp /etc/kube-router/cni-conf.json \${TMP};
            mv \${TMP} /etc/cni/net.d/10-kuberouter.conflist;
          fi
        volumeMounts:
        - name: cni-conf-dir
          mountPath: /etc/cni/net.d
        - name: kube-router-cfg
          mountPath: /etc/kube-router
      hostNetwork: true
      tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
      - effect: NoSchedule
        key: node-role.kubernetes.io/master
        operator: Exists
      - effect: NoSchedule
        key: node.kubernetes.io/not-ready
        operator: Exists
      - effect: NoSchedule
        key: node-role.kubernetes.io/ingress
        operator: Equal
      volumes:
      - name: lib-modules
        hostPath:
          path: /lib/modules
      - name: cni-conf-dir
        hostPath:
          path: ${CNI_PATH}/etc/net.d
      - name: kube-router-cfg
        configMap:
          name: kube-router-cfg
      - name: kubeconfig
        secret:
          secretName: kube-proxy
          items:
          - key: kubeconfig.conf
            path: kubeconfig
  updateStrategy:
    rollingUpdate:
      maxUnavailable: 1
    type: RollingUpdate
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: kube-router
  namespace: kube-system
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: kube-router
  namespace: kube-system
rules:
  - apiGroups:
    - ""
    resources:
      - namespaces
      - pods
      - services
      - nodes
      - endpoints
    verbs:
      - list
      - get
      - watch
  - apiGroups:
    - "networking.k8s.io"
    resources:
      - networkpolicies
    verbs:
      - list
      - get
      - watch
  - apiGroups:
    - extensions
    resources:
      - networkpolicies
    verbs:
      - get
      - list
      - watch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: kube-router
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: kube-router
subjects:
- kind: ServiceAccount
  name: kube-router
  namespace: kube-system
EOF
elif [ ${NET_PLUG} == 2 ]; then 
mkdir -p roles/kube-proxy/{files,tasks,templates}
# 创建kube-proxy ansible
cat << EOF | tee ${HOST_PATH}/roles/kube-proxy/tasks/main.yml
- name: copy kube-proxy to ${K8S_PATH}
  copy: src=bin dest=${K8S_PATH}/ owner=root group=root mode=755
- name: copy to kube-proxy config
  template: src={{ item }} dest=${K8S_PATH}/conf
  with_items:
      - kube-proxy
      - kube-proxy.kubeconfig
- name:  copy to kube-proxy service
  template: src={{ item }} dest=/lib/systemd/system/
  with_items:
      - kube-proxy.service
- name: Reload service daemon-reload
  shell: systemctl daemon-reload
- name: Enable service kube-proxy, and not touch the state
  service:
    name: kube-proxy
    enabled: yes
- name: Start service kube-proxy, if not started
  service:
    name: kube-proxy
    state: started
EOF
 
# 创建kubelet 启动配置文件
cat << EOF | tee ${HOST_PATH}/roles/kube-proxy/templates/kube-proxy
KUBE_PROXY_OPTS="--logtostderr=false \\
--v=${LEVEL_LOG} \\
--feature-gates=SupportIPVSProxyMode=true \\
--masquerade-all=true \\
--proxy-mode=ipvs \\
--ipvs-min-sync-period=5s \\
--ipvs-sync-period=5s \\
--ipvs-scheduler=rr \\
--cluster-cidr=${CLUSTER_CIDR} \\
--log-dir=${K8S_PATH}/log \\
--metrics-bind-address=0.0.0.0 \\
--hostname-override={{ ansible_hostname }} \\
--kubeconfig=${K8S_PATH}/conf/kube-proxy.kubeconfig"
EOF
# 创建kubelet 启动文件
cat << EOF | tee ${HOST_PATH}/roles/kube-proxy/templates/kube-proxy.service
[Unit]
Description=Kubernetes Proxy
After=network.target

[Service]
LimitNOFILE=1024000
LimitNPROC=1024000
LimitCORE=infinity
LimitMEMLOCK=infinity
EnvironmentFile=-${K8S_PATH}/conf/kube-proxy
ExecStart=${K8S_PATH}/bin/kube-proxy \$KUBE_PROXY_OPTS
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
# cp 二进制文件及ssl及kubeconfig 文件到 ansible 目录 
mkdir -p ${HOST_PATH}/roles/kube-proxy/files/bin
\cp -pdr ${TEMP_PATH}/kubernetes/server/bin/kube-proxy ${HOST_PATH}/roles/kube-proxy/files/bin
# 复制kube-proxy.kubeconfig 文件
\cp -pdr ${HOST_PATH}/kubeconfig/kube-proxy.kubeconfig ${HOST_PATH}/roles/kube-proxy/templates/
#
cat << EOF | tee ${HOST_PATH}/kube-proxy.yml
- hosts: all
  user: root
  roles:
    - kube-proxy
EOF
# 创建flannel yaml
cat << EOF | tee ${HOST_PATH}/yaml/flannel.yaml
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: flannel
rules:
  - apiGroups:
      - ""
    resources:
      - pods
    verbs:
      - get
  - apiGroups:
      - ""
    resources:
      - nodes
    verbs:
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - nodes/status
    verbs:
      - patch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: flannel
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: flannel
subjects:
- kind: ServiceAccount
  name: flannel
  namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: flannel
  namespace: kube-system
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: kube-flannel-cfg
  namespace: kube-system
  labels:
    tier: node
    app: flannel
data:
  cni-conf.json: |
     {
     "name":"cni0",
     "cniVersion":"0.3.1",
     "plugins":[
       {
         "type":"flannel",
         "delegate":{
           "forceAddress":false,
           "hairpinMode": true,
           "isDefaultGateway":true
         }
       },
       {
         "type":"portmap",
         "capabilities":{
           "portMappings":true
         }
       }
     ]
     }
  net-conf.json: |
    {
      "Network": "${CLUSTER_CIDR}",
      "Backend": {
        "Type": "vxlan",
        "Directrouting": true
      }
    }
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: kube-flannel-ds-amd64
  namespace: kube-system
  labels:
    tier: node
    app: flannel
spec:
  selector:
    matchLabels:
      app: flannel
  template:
    metadata:
      labels:
        tier: node
        app: flannel
    spec:
      hostNetwork: true
      nodeSelector:
        beta.kubernetes.io/arch: amd64
      tolerations:
      - key: CriticalAddonsOnly
        operator: Exists
      - effect: NoSchedule
        key: node-role.kubernetes.io/master
        operator: Exists
      - effect: NoSchedule
        key: node.kubernetes.io/not-ready
        operator: Exists
      - effect: NoSchedule
        key: node-role.kubernetes.io/ingress
        operator: Equal
      serviceAccountName: flannel
      initContainers:
      - name: install-cni
        image: quay.io/coreos/flannel:v0.11.0-amd64
        command:
        - cp
        args:
        - -f
        - /etc/kube-flannel/cni-conf.json
        - /etc/cni/net.d/10-flannel.conflist
        volumeMounts:
        - name: cni
          mountPath: /etc/cni/net.d
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
      containers:
      - name: kube-flannel
        image: quay.io/coreos/flannel:v0.11.0-amd64
        command:
        - /opt/bin/flanneld
        args:
        - --ip-masq
        - --kube-subnet-mgr
        - --healthz-port=10244
        livenessProbe:
          httpGet:
            path: /healthz
            port: 10244
          initialDelaySeconds: 10
          periodSeconds: 3
        resources:
          requests:
            cpu: "100m"
            memory: "50Mi"
          limits:
            cpu: "100m"
            memory: "50Mi"
        securityContext:
          privileged: true
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        volumeMounts:
        - name: run
          mountPath: /run
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
      volumes:
        - name: run
          hostPath:
            path: /run
        - name: cni
          hostPath:
            path: ${CNI_PATH}/etc/net.d
        - name: flannel-cfg
          configMap:
            name: kube-flannel-cfg
  updateStrategy:
    rollingUpdate:
      maxUnavailable: 1
    type: RollingUpdate
EOF
fi
# 生成集群授权yaml
cat << EOF | tee ${HOST_PATH}/yaml/kube-api-rbac.yaml
---
# kube-controller-manager 绑定
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: controller-node-clusterrolebing
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-controller-manager
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: system:kube-controller-manager
---
# 创建kube-scheduler 绑定
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: scheduler-node-clusterrolebing
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-scheduler
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: system:kube-scheduler
---
# 创建kube-controller-manager 到auth-delegator 绑定
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: controller-manager:system:auth-delegator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: system:kube-controller-manager
---
#授予 kubernetes 证书访问 kubelet API 的权限
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kube-system-cluster-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: system:serviceaccount:kube-system:default
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kubelet-node-clusterbinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:node
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:nodes
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kube-apiserver:kubelet-apis
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kubelet-api-admin
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: kubernetes
EOF
# 创建kubelet-bootstrap 授权
cat << EOF | tee ${HOST_PATH}/yaml/kubelet-bootstrap-rbac.yaml
---
# 允许 system:bootstrappers 组用户创建 CSR 请求
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kubelet-bootstrap
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:node-bootstrapper
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:bootstrappers
---
# 自动批准 system:bootstrappers 组用户 TLS bootstrapping 首次申请证书的 CSR 请求
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: node-client-auto-approve-csr
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:certificates.k8s.io:certificatesigningrequests:nodeclient
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:bootstrappers
---
# 自动批准 system:nodes 组用户更新 kubelet 自身与 apiserver 通讯证书的 CSR 请求
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: node-client-auto-renew-crt
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:certificates.k8s.io:certificatesigningrequests:selfnodeclient
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:nodes
---
# 自动批准 system:nodes 组用户更新 kubelet 10250 api 端口证书的 CSR 请求
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: node-server-auto-renew-crt
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:certificates.k8s.io:certificatesigningrequests:selfnodeserver
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: Group
  name: system:nodes
---
EOF
# 创建bootstrap secret yaml
cat << EOF | tee ${HOST_PATH}/yaml/bootstrap-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  # Name MUST be of form "bootstrap-token-<token id>"
  name: bootstrap-token-${TOKEN_ID}
  namespace: kube-system

# Type MUST be 'bootstrap.kubernetes.io/token'
type: bootstrap.kubernetes.io/token
stringData:
  # Human readable description. Optional.
  description: "The default bootstrap token generated by 'kubelet '."

  # Token ID and secret. Required.
  token-id: ${TOKEN_ID}
  token-secret: ${TOKEN_SECRET}

  # Allowed usages.
  usage-bootstrap-authentication: "true"
  usage-bootstrap-signing: "true"

  # Extra groups to authenticate the token as. Must start with "system:bootstrappers:"
  auth-extra-groups: system:bootstrappers:worker,system:bootstrappers:ingress
---
# A ClusterRole which instructs the CSR approver to approve a node requesting a
# serving cert matching its client cert.
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: system:certificates.k8s.io:certificatesigningrequests:selfnodeserver
rules:
- apiGroups: ["certificates.k8s.io"]
  resources: ["certificatesigningrequests/selfnodeserver"]
  verbs: ["create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kubernetes-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: system:kubernetes
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kubernetes-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF
# 生成自动挂载日期与lxcfs
cat << EOF | tee ${HOST_PATH}/yaml/allow-lxcfs-tz-env.yaml
apiVersion: settings.k8s.io/v1alpha1
kind: PodPreset
metadata:
  name: allow-lxcfs-tz-env
spec:
  selector:
    matchLabels:
  volumeMounts:
    - mountPath: /proc/cpuinfo
      name: proc-cpuinfo
    - mountPath: /proc/diskstats
      name: proc-diskstats
    - mountPath: /proc/meminfo
      name: proc-meminfo
    - mountPath: /proc/stat
      name: proc-stat
    - mountPath: /proc/swaps
      name: proc-swaps
    - mountPath: /proc/uptime
      name: proc-uptime
    - mountPath: /etc/localtime
      name: allow-tz-env
        
  volumes:
    - name: proc-cpuinfo
      hostPath:
        path: /var/lib/lxcfs/proc/cpuinfo
    - name: proc-diskstats
      hostPath:
        path: /var/lib/lxcfs/proc/diskstats
    - name: proc-meminfo
      hostPath:
        path: /var/lib/lxcfs/proc/meminfo
    - name: proc-stat
      hostPath:
        path: /var/lib/lxcfs/proc/stat
    - name: proc-swaps
      hostPath:
        path: /var/lib/lxcfs/proc/swaps
    - name: proc-uptime
      hostPath:
        path: /var/lib/lxcfs/proc/uptime
    - name: allow-tz-env
      hostPath:
        path: /usr/share/zoneinfo/Asia/Shanghai
---
apiVersion: settings.k8s.io/v1alpha1
kind: PodPreset
metadata:
  name: allow-tz-env
spec:
  selector:
    matchLabels:
  env:
    - name: TZ
      value: Asia/Shanghai
EOF
# 生成环境变量配置方便创建kubeconfig 跟签发新的个人证书
cat << EOF | tee ${HOST_PATH}/environment.sh
#!/bin/sh
export KUBE_APISERVER="https://${K8S_VIP_DOMAIN}:${K8S_VIP_PORT}"
export HOST_PATH="${HOST_PATH}"
export CERT_ST="${CERT_ST}"
export CERT_L="${CERT_L}"
export CERT_O="${CERT_O}"
export CERT_OU="${CERT_OU}"
export CERT_PROFILE="${CERT_PROFILE}"
export CLUSTER_DNS_DOMAIN="${CLUSTER_DNS_DOMAIN}"
export CLUSTER_DNS_SVC_IP="${CLUSTER_DNS_SVC_IP}"
EOF
# 创建kubectl 工具配置文件
if [ ${K8S_EVENTS} == 1 ]; then
EVENTS_ETCD="##########  etcd EVENTS 部署 ansible-playbook -i ${ETCD_EVENTS_IPS}, events-etcd.yml"
fi
if [ ${NET_PLUG} == 2 ]; then
NET_PLUG1="##########  安装K8S node 使用 flannel 网络插件ansible部署ansible-playbook -i 要安装node ip列表 package.yml cni.yml lxcfs.yml docker.yml kubelet.yml kube-proxy.yml"
NET_PLUG2="##########  flannel 网络插件部署 kubectl apply -f ${HOST_PATH}/yaml/flannel.yaml 等待容器部署完成查看node 节点网络 ip a| grep flannel.1"
elif [ ${NET_PLUG} == 1 ]; then
NET_PLUG1="##########  安装K8S node 使用kube-router ansible部署 ansible-playbook -i 要安装node ip列表 package.yml cni.yml lxcfs.yml docker.yml kubelet.yml"
NET_PLUG2="##########  kube-router 网络插件部署 方式部署 kubectl apply -f ${HOST_PATH}/yaml/kube-router.yaml 等待容器部署完成查看node ip a | grep kube-bridge"
fi
cat << EOF | tee ${HOST_PATH}/README.md
########## mkdir -p /root/.kube
##########复制admin kubeconfig 到root用户作为kubectl 工具默认密钥文件
########## \cp -pdr ${HOST_PATH}/kubeconfig/admin.kubeconfig /root/.kube/config
###################################################################################
##########  ansible 及ansible-playbook 单个ip ip结尾一点要添加“,”符号 ansible-playbook -i 192.168.0.1, xxx.yml
##########  source ${HOST_PATH}/environment.sh 设置环境变量生效方便后期新增证书等
##########  etcd 部署 ansible-playbook -i ${ETCD_SERVER_IPS} etcd.yml
${EVENTS_ETCD}
##########  kube-apiserver 部署 ansible-playbook -i ${K8S_APISERVER_VIP}, kube-apiserver.yml 
##########  haproxy 部署 ansible-playbook -i ${K8S_APISERVER_VIP}, haproxy.yml
##########  keepalived 节点IP ${K8S_APISERVER_VIP} 安装keepalived使用IP 如果大于三个节点安装keepalived 记得HA1_ID 唯一的也就是priority的值
##########  keepalived 也可以全部部署为BACKUP STATE_x 可以使用默认值 IFACE 网卡名字默认${IFACE} ROUTER_ID 全局唯一ID   HA1_ID为priority值  
##########  keepalived 部署 节点1 ansible-playbook -i 节点ip1, keepalived.yml -e IFACE=${IFACE} -e ROUTER_ID=HA1 -e HA1_ID=100 -e HA2_ID=110 -e HA3_ID=120 -e STATE_3=MASTER
##########  keepalived 部署 节点2 ansible-playbook -i 节点ip2, keepalived.yml -e IFACE=${IFACE} -e ROUTER_ID=HA2 -e HA1_ID=110 -e HA2_ID=120 -e HA3_ID=100 -e STATE_2=MASTER
##########  keepalived 部署 节点3 ansible-playbook -i 节点ip3, keepalived.yml -e IFACE=${IFACE} -e ROUTER_ID=HA3 -e HA1_ID=120 -e HA2_ID=100 -e HA3_ID=110 -e STATE_1=MASTER
##########  kube-controller-manager kube-scheduler  ansible-playbook -i ${K8S_APISERVER_VIP}, kube-controller-manager.yml kube-scheduler.yml
##########  部署完成验证集群 kubectl cluster-info  kubectl api-versions  kubectl get cs 1.16 kubectl 显示不正常 
##########  提交bootstrap 跟授权到K8S 集群 kubectl apply -f ${HOST_PATH}/yaml/bootstrap-secret.yaml 
##########  提交授权到K8S集群 kubectl apply -f ${HOST_PATH}/yaml/kubelet-bootstrap-rbac.yaml kubectl apply -f ${HOST_PATH}/yaml/kube-api-rbac.yaml
##########  系统版本为centos7,8 或者 ubuntu18 请先升级 iptables ansible-playbook -i  要安装node ip列表, iptables.yml
${NET_PLUG1}
${NET_PLUG2}
##########  部署自动挂载日期与lxcfs 到pod的 PodPreset  kubectl apply -f ${HOST_PATH}/yaml/allow-lxcfs-tz-env.yaml -n kube-system  " kube-system 命名空间名字"PodPreset 只是当前空间生效所以需要每个命名空间执行
##########  查看node 节点是否注册到K8S kubectl get node kubectl get csr 
##########  给 master ingress 添加污点 防止其它服务使用这些节点:kubectl taint nodes  k8s-master-01 node-role.kubernetes.io/master=:NoSchedule kubectl taint nodes  k8s-ingress-01 node-role.kubernetes.io/ingress=:NoSchedule
##########  calico 网络插件部署 50节点内 wget https://docs.projectcalico.org/v3.10/manifests/calico.yaml  大于50节点 wget https://docs.projectcalico.org/v3.10/manifests/calico-typha.yaml
########## 如果cni配置没放到默认路径请创建软链 ln -s ${CNI_PATH}/etc /etc/cni 同时修改yaml hostPath路径 同时修改CALICO_IPV4POOL_CIDR 参数为 ${CLUSTER_CIDR} CALICO_IPV4POOL_IPIP: Never 启用bgp模式
##########  windows 证书访问 openssl pkcs12 -export -inkey k8s-apiserver-admin-key.pem -in k8s_apiserver-admin.pem -out client.p12
########## kubectl proxy --port=8001 &  把kube-apiserver 端口映射成本地 8001 端口      
########## 查看kubelet节点配置信息 NODE_NAME="k8s-node-04"; curl -sSL "http://localhost:8001/api/v1/nodes/\${NODE_NAME}/proxy/configz" | jq '.kubeletconfig|.kind="KubeletConfiguration"|.apiVersion="kubelet.config.k8s.io/v1beta1"' > kubelet_configz_\${NODE_NAME}

EOF