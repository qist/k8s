#!/bin/bash
###########################################################K8S一键自动安装##############################################################################################################
###########################################################K8S 版本支持在v1.25.0 及以上版本低版本到版本分支下载############################################################################
###########################################################在部署中会重启服务器及更新系统需要在全新环境部署不然重启对业务有影响###############################################################
#########################支持操作系统centos7，centos8-Stream版本原centos8源已经不再更新，Ubuntu维护版本非维护版本可能源有问题，openSUSE Leap 15.0及上版本rockylinux8,9版本支持##################
# 开启 下载代理 国内尽量配置
Proxy() {
  # export http_proxy=http://127.0.0.1:7890/
  # export https_proxy=http://127.0.0.1:7890/
  test
}
# 卸载 代理
UNProxy() {
  unset http_proxy
  unset https_proxy
}

###########################################################################################################################################################################
###################################                           必须修改            hostname必须先修改好         ############################################################
###########################################################################################################################################################################
# node 节点 ansible 接受写法
NODE_IP="192.168.2.185,192.168.2.187,192.168.3.62"
#kube-apiserver 服务器IP列表 有更多的节点时请添加IP K8S_APISERVER_VIP="\"192.168.2.247\",\"192.168.2.248\",\"192.168.2.249\",\"192.168.2.250\",\"192.168.2.251\""
MASTER_FRONTEND_IP1=192.168.2.175
MASTER_FRONTEND_IP2=192.168.2.176
MASTER_FRONTEND_IP3=192.168.2.177
K8S_APISERVER_VIP="\"${MASTER_FRONTEND_IP1}\",\"${MASTER_FRONTEND_IP2}\",\"${MASTER_FRONTEND_IP3}\""
#kube-apiserver 监听port
SECURE_PORT=5443
# kube-apiserver vip 监听port proxy 工具监听端口不能与kube-apiserver 端口重复master 不能做高可用。
K8S_VIP_PORT=6443
# k8s apiserver IP 外部操作K8S 使用 建议使用lb ip 如果使用LB IP 请先配置好，自动部署集群验证会用到不然会报错 可以是master 任意节点IP 或者解析域名
K8S_VIP="192.168.2.175"
# 是否使用ipvs 负载均衡 默认关闭
IPVS=false
if [ $IPVS = true ]; then
# ipvs 负载均衡vip ip 
  MASTER_IP=169.254.0.10
else
  # K8S 组件连接 master IP 这里采用 NGINX 每个节点部署所以本地IP
  MASTER_IP=127.0.0.1
fi
# 配置etcd 集群IP
ETCD_MEMBER_1_IP="192.168.2.175"
ETCD_MEMBER_1_HOSTNAMES="k8s-master-1"
ETCD_MEMBER_2_IP="192.168.2.176"
ETCD_MEMBER_2_HOSTNAMES="k8s-master-2"
ETCD_MEMBER_3_IP="192.168.2.177"
ETCD_MEMBER_3_HOSTNAMES="k8s-master-3"
# etcd events集群 IP
ETCD_EVENTS_MEMBER_1_IP="192.168.2.185"
ETCD_EVENTS_MEMBER_1_HOSTNAMES="k8s-node-1"
ETCD_EVENTS_MEMBER_2_IP="192.168.2.187"
ETCD_EVENTS_MEMBER_2_HOSTNAMES="k8s-node-2"
ETCD_EVENTS_MEMBER_3_IP="192.168.3.62"
ETCD_EVENTS_MEMBER_3_HOSTNAMES="k8s-node-3"
### cgroup驱动 cgroupfs systemd 默认 systemd
NATIVE_CGROUPDRIVER=systemd
##### 以下参数根据实际网络环境修改不能有重复网段
# 最好使用 当前未用的网段 来定义服务网段和 Pod 网段
# 服务网段，部署前路由不可达，部署后集群内路由可达(kube-proxy 保证)
export SERVICE_CIDR="10.66.0.0/16"
# Pod 网段，建议 /12 段地址，部署前路由不可达，部署后集群内路由可达(网络插件 保证)
export CLUSTER_CIDR="10.80.0.0/12"
# 服务端口范围 (NodePort Range)
NODE_PORT_RANGE="30000-65535"
# kubernetes 服务 IP (一般是 SERVICE_CIDR 中第一个IP)
export CLUSTER_KUBERNETES_SVC_IP="10.66.0.1"
# 集群名字
export CLUSTER_NAME=kubernetes
#集群域名
export CLUSTER_DNS_DOMAIN="cluster.local"
# 集群 服务帐号令牌颁发者的标识符 1.20版本及以上用到
export SERVICE_ACCOUNT_ISSUER="https://${CLUSTER_NAME}.default.svc.${CLUSTER_DNS_DOMAIN}"
#集群DNS
export CLUSTER_DNS_SVC_IP="10.66.0.2"
# 证书相关配置
export CERT_ST="GuangDong"
export CERT_L="GuangZhou"
export CERT_O="k8s"
export CERT_OU="Qist"
export CERT_PROFILE="kubernetes"
# 数字证书时间及kube-controller-manager 签发证书时间 默认100年
export EXPIRY_TIME="876000h"
#######################################################################################################################################################################
#######################################################################################################################################################################
##############################参数选择，选择需要部署网络查询 容器运行时，是否升级iptables  是否部署K8S 事件集群etcd等 #################################################
#######################################################################################################################################################################
# 是否自动安装 K8S 集群 ON 开启 OFF 关闭
INSTALL_K8S=OFF
# 配置容器运行时 DOCKER,CONTAINERD,CRIO 默认docker
RUNTIME=CONTAINERD
# 网络插件 选择 flannel,kube-router 默认 flannel

# calico 插件下载地址
# https://docs.projectcalico.org/manifests/calico.yaml
# https://docs.projectcalico.org/manifests/calico-typha.yaml
NET_PLUG=flannel
#K8S events 存储ETCD 集群 默认关闭OFF ON开启
K8S_EVENTS=OFF
# 是否升级iptables OFF 关闭 ON 开启
IPTABLES_INSTALL=OFF
# 是否开启 审计 false 关闭 true 开启
DYNAMICAUDITING=false
# k8s 17号版本及以上的版本配置
# 拓扑感知服务路由配置 false 关闭 true 开启
SERVICETOPOLOGY=true
# k8s 网络互联接口 ansible_eth0.ipv4.address 单网卡使用ansible_default_ipv4.address 多个网卡请指定使用的网卡名字
KUBELET_IPV4=ansible_default_ipv4.address
# ETCD 集群通讯网卡
ETCD_IPV4=ansible_default_ipv4.address
# POD 通信 网卡
IFACE="eth0"
# 是否更新系统及基本的内核修改 OFF 关闭 ON 开启 默认开启
PACKAGE_SYSCTL=ON
# 开启日志是否写文件 true 为不写入文件只写入系统日志 false 写入log-dir配置目录
LOGTOSTDERR=true
# 当logtostderr 为false alsologtostderr为 true 同时写入log文件及系统日志。当logtostderr 为true alsologtostderr 参数失效
ALSOLOGTOSTDERR=true
# 设置输出日志级别
LEVEL_LOG="2"
# 启用特性 处于Alpha 或者Beta 阶段 https://kubernetes.io/zh/docs/reference/command-line-tools-reference/feature-gates/
# RemoveSelfLink=false 1.20 以后使用provisioner 方式部署动态StorageClass 使用默认true
FEATURE_GATES_OPT="ServiceTopology=true,EndpointSlice=true,TTLAfterFinished=true"

########################################################################################################################################################################
######################################################### 负载均衡插件及镜像   尽量下载使用私有仓库镜像地址这样部署很快        #########################################
########################################################################################################################################################################
## kube-apiserver ha proxy 配置
# nginx 启动进程数 auto 当前机器cpu 核心数的进程数
CPU_NUM=4
# 所用 镜像名字 可以自己构建  项目地址 https://github.com/qist/k8s/tree/master/dockerfile/k8s-ha-master 或者nginx docker.io/juestnow/nginx-proxy:1.21.6
if [ $IPVS = true ]; then
  HA_PROXY_IMAGE="docker.io/juestnow/lvscare-proxy:v1.1.3-beta.8-amd64"
else
  HA_PROXY_IMAGE="docker.io/juestnow/haproxy-proxy:2.5.4"
fi

# pod-infra-container-image 地址
POD_INFRA_CONTAINER_IMAGE="docker.io/juestnow/pause:3.9"
#########################################################################################################################################################################
#########################################################################################################################################################################
#############################################                    一般参数修改                                    ########################################################
#########################################################################################################################################################################
# 设置工作目录
export HOST_PATH=$(pwd)
# 设置下载文件目录
export DOWNLOAD_PATH=${HOST_PATH}/download
# 设置版本号
# ETCD 版本
export ETCD_VERSION=v3.5.13
# kubernetes 版本
export KUBERNETES_VERSION=v1.30.0
# cni 版本
export CNI_VERSION=v1.4.1
# iptables
export IPTABLES_VERSION=1.8.5
# 数字证书签名工具
export CFSSL_VERSION=1.6.4
# docker 版本
export DOCKER_VERSION=26.0.1
# docker cri 版本
export CRI_DOCKER_VERSION=v0.3.12
# containerd 版本
export CONTAINERD_VERSION=1.7.15
# crictl 版本
export CRICTL_VERSION=v1.30.0
# runc 版本
export RUNC_VERSION=v1.1.12
# cri-o 版本
export DOWNLOAD_CRIO_VERSION="https://storage.googleapis.com/cri-o/artifacts/cri-o.amd64.v1.29.2.tar.gz"
export CRIO_VERSION=v1.29.2
# 网络插件镜像选择 尽量下载使用私有仓库镜像地址这样部署很快
# flannel cni
FLANNEL_CNI_PLUGIN="docker.io/flannel/flannel-cni-plugin:v1.4.1-flannel1"
# flannel 插件选择
FLANNEL_VERSION="docker.io/flannel/flannel:v0.25.1"
# kube-router 镜像
KUBE_ROUTER_INIT="docker.io/cloudnativelabs/kube-router"
KUBE_ROUTER_IMAGE="docker.io/cloudnativelabs/kube-router"
# coredns 镜像
COREDNS_IMAGE=docker.io/coredns/coredns:1.11.1
# 应用部署目录 选择硬盘空间比较大的
TOTAL_PATH=/apps
# etcd 部署目录
ETCD_PATH=$TOTAL_PATH/etcd
# etcd 数据存储目录
ETCD_DATA_DIR=$TOTAL_PATH/etcd/data/default.etcd
# etcd 日志存储目录
ETCD_WAL_DIR=$TOTAL_PATH/etcd/data/default.etcd/wal
# K8S 部署目录
K8S_PATH=$TOTAL_PATH/k8s
# K8S pod 运行目录
POD_ROOT_DIR=$TOTAL_PATH/work
# kubelet pod manifest path
POD_MANIFEST_PATH=${POD_ROOT_DIR}/kubernetes/manifests
# kubelet pod runing 目录
POD_RUNING_PATH=${POD_ROOT_DIR}/kubernetes/kubelet
# docker 运行目录
DOCKER_PATH=$TOTAL_PATH/docker
# docker 二进制部署目录
# DOCKER_BIN_PATH=$TOTAL_PATH/docker/bin #ubuntu 18 版本必须设置在/usr/bin 目录下面
DOCKER_BIN_PATH=/usr/bin
# cni 部署目录
# cni 配置
CNI_BIN_DIR=/opt/cni/bin
CNI_CONF_DIR=/etc/cni/net.d
# 源码安装 源码存放目录
SOURCE_PATH=/usr/local/src
# containerd 部署目录
CONTAINERD_PATH=$TOTAL_PATH/containerd
# cri-o 部署目录
CRIO_PATH=$TOTAL_PATH/crio
# service 文件打开数
HARD_SOFT=655350
#容器运行文件打开数
POD_HARD_SOFT=65535
# 配置etcd集群参数
ETCD_SERVER_HOSTNAMES="\"${ETCD_MEMBER_1_HOSTNAMES}\",\"${ETCD_MEMBER_2_HOSTNAMES}\",\"${ETCD_MEMBER_3_HOSTNAMES}\""
ETCD_SERVER_IPS="\"${ETCD_MEMBER_1_IP}\",\"${ETCD_MEMBER_2_IP}\",\"${ETCD_MEMBER_3_IP}\""
# etcd 集群间通信的 IP 和端口
INITIAL_CLUSTER="${ETCD_MEMBER_1_HOSTNAMES}=https://${ETCD_MEMBER_1_IP}:2380,${ETCD_MEMBER_2_HOSTNAMES}=https://${ETCD_MEMBER_2_IP}:2380,${ETCD_MEMBER_3_HOSTNAMES}=https://${ETCD_MEMBER_3_IP}:2380"
# etcd 集群服务地址列表
ENDPOINTS=https://${ETCD_MEMBER_1_IP}:2379,https://${ETCD_MEMBER_2_IP}:2379,https://${ETCD_MEMBER_3_IP}:2379
# 心跳间隔的时间（以毫秒为单位）
HEARTBEAT_INTERVAL=6000
# 选举超时的时间（以毫秒为单位）
ELECTION_TIMEOUT=30000
# 触发快照到磁盘的已提交事务数
SNAPSHOT_COUNT=5000
# 在一个小时内为mvcc键值存储的自动压实保留。0表示禁用自动压缩。
AUTO_COMPACTION_RETENTION=1
# 服务器将接受的最大客户端请求大小（字节）
MAX_REQUEST_BYTES=33554432
# 当后端大小超过给定配额时（0默认为低空间配额），引发警报。计算方式: echo $((16*1024*1024*1024))
QUOTA_BACKEND_BYTES=17179869184
#集群初始化名称
INITIAL_CLUSTER_TOKEN=k8s-cluster
if [ ${K8S_EVENTS} == "ON" ]; then
  # etcd events集群配置
  ETCD_EVENTS_HOSTNAMES="\"${ETCD_EVENTS_MEMBER_1_HOSTNAMES}\",\"${ETCD_EVENTS_MEMBER_2_HOSTNAMES}\",\"${ETCD_EVENTS_MEMBER_3_HOSTNAMES}\""
  ETCD_EVENTS_IPS="\"${ETCD_EVENTS_MEMBER_1_IP}\",\"${ETCD_EVENTS_MEMBER_2_IP}\",\"${ETCD_EVENTS_MEMBER_3_IP}\""
  #集群初始化名称
  INITIAL_CLUSTER_TOKEN_EVENTS=k8s-events-cluster
  # etcd 集群间通信的 IP 和端口
  INITIAL_EVENTS_CLUSTER="${ETCD_EVENTS_MEMBER_1_HOSTNAMES}=https://${ETCD_EVENTS_MEMBER_1_IP}:2380,${ETCD_EVENTS_MEMBER_2_HOSTNAMES}=https://${ETCD_EVENTS_MEMBER_2_IP}:2380,${ETCD_EVENTS_MEMBER_3_HOSTNAMES}=https://${ETCD_EVENTS_MEMBER_3_IP}:2380"
  ENDPOINTS="${ENDPOINTS} --etcd-servers-overrides=/events#https://${ETCD_EVENTS_MEMBER_1_IP}:2379;https://${ETCD_EVENTS_MEMBER_2_IP}:2379;https://${ETCD_EVENTS_MEMBER_3_IP}:2379"
fi
# kubernetes 相关配置
# 公共配置
# 配置tls 加密套件 etcd k8s 组件配置
TLS_CIPHER="TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_GCM_SHA256"
# kube-apiserver 配置
# K8S ETCD存储 目录名字
ETCD_PREFIX="/registry"
K8S_SSL="\"${K8S_VIP}\",\"127.0.0.1\",\"${MASTER_IP}\""
# 生成 EncryptionConfig 所需的加密 key
ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)
# kubectl 连接 kube-apiserver
export KUBE_APISERVER="https://${K8S_VIP}:${SECURE_PORT}"
# kubernetes 集群节点链接 kube-apiserver 配置
KUBE_API_KUBELET="https://${MASTER_IP}:${K8S_VIP_PORT}"
# RUNTIME_CONFIG 设置
RUNTIME_CONFIG="api/all=true"
#开启插件enable-admission-plugins #AlwaysPullImages 启用istio 不能自动注入需要手动执行注入
ENABLE_ADMISSION_PLUGINS="DefaultStorageClass,DefaultTolerationSeconds,LimitRanger,NamespaceExists,NamespaceLifecycle,NodeRestriction,PodNodeSelector,PersistentVolumeClaimResize,PodTolerationRestriction,ResourceQuota,ServiceAccount,StorageObjectInUseProtection,MutatingAdmissionWebhook,ValidatingAdmissionWebhook"
#禁用插件disable-admission-plugins
DISABLE_ADMISSION_PLUGINS="ExtendedResourceToleration,ImagePolicyWebhook,LimitPodHardAntiAffinityTopology,NamespaceAutoProvision,Priority,EventRateLimit"
# 设置api 副本数
APISERVER_COUNT="3"
# api 突变请求最大数
MAX_MUTATING_REQUESTS_INFLIGHT="500"
# api 非突变请求的最大数目
MAX_REQUESTS_INFLIGHT="1500"
# 指示notReady:NoExecute的容忍秒数，默认情况下添加到没有这种容忍的每个pod中。 默认 300
DEFAULT_NOT_READY_TOLERATION_SECONDS=30
# 指示对不可到达的:NoExecute的容忍秒数,默认情况下添加到没有这种容忍的每个pod中。默认 300
DEFAULT_UNREACHABLE_TOLERATION_SECONDS=30
# kube-controller-manager kube-scheduler 配置
# 与 apiserver 通信的每秒查询数（QPS） 值 默认50
KUBE_API_QPS="100"
#每秒发送到 apiserver 的请求数量上限 默认30
KUBE_API_BURST="100"
# 可以并发同步的 Service 对象个数。数值越大，服务管理的响应速度越快，不过对 CPU （和网络）的占用也越高。 默认1
CONCURRENT_SERVICE_SYNCS=2
# 可以并发同步的 Deployment 对象个数。数值越大意味着对 Deployment 的响应越及时，同时也意味着更大的 CPU（和网络带宽）压力。默认5
CONCURRENT_DEPLOYMENT_SYNCS=10
# 可以并发同步的垃圾收集工作线程个数。 默认20
CONCURRENT_GC_SYNCS=30
# 我们允许运行的节点在标记为不健康之前没有响应的时间。必须是kubelet的nodeStatusUpdateFrequency的N倍， 其中N表示允许kubelet发布节点状态的重试次数默认40s。
NODE_MONITOR_GRACE_PERIOD=30s
#在NodeController中同步节点状态的周期。默认5s
NODE_MONITOR_PERIOD=5s
# 我们允许启动节点在标记为不健康之前没有响应的时间。，默认1m0s。
NODE_STARTUP_GRACE_PERIOD=20s
# 默认,exit状态的pod回收阀值 12500
TERMINATED_POD_GC_THRESHOLD=50
# kubelet 配置
# max-pods node 节点启动最多pod 数量
MAX_PODS=55
#每1核cpu最多运行pod数 默认0 关闭
PODS_PER_CORE=0
# hairpin-mode 标志必须设置为 hairpin-veth 或者 promiscuous-bridge pod 试图访问它们自己的 Service VIP，就可以让 Service 的端点重新负载到他们自己身上
HAIRPIN_MODE=hairpin-veth
# 突发事件记录的个数上限
EVENT_BURST=30
# 设置大于 0 的值表示限制每秒可生成的事件数量。设置为 0 表示不限制。（默认值为 5）
EVENT_QPS=15
# 每秒发送到 apiserver 的请求数量上限（默认值为 10）
KUBELET_API_BURST=30
# 与 apiserver 通信的每秒查询数（QPS） 值（默认值为 5）
KUBELET_API_QPS=15
# 镜像垃圾回收上限。磁盘使用空间达到该百分比时，镜像垃圾回收将持续工作
IMAGE_GC_HIGH_THRESHOLD=70
# 镜像垃圾回收下限。磁盘使用空间在达到该百分比之前，镜像垃圾回收操作不会运行。
IMAGE_GC_LOW_THRESHOLD=50
# kubernetes 系统预留的资源配置，以一组 ResourceName=ResourceQuantity 格式表示
KUBERESERVED_CPU=500m
KUBERESERVED_MEMORY=512Mi
KUBERESERVED_STORAGE=1Gi
# 系统预留的资源配置，以一组 ”ResourceName=ResourceQuantity“ 的格式表示
SYSTEMRESERVED_CPU=1000m
SYSTEMRESERVED_MEMORY=1024Mi
SYSTEMRESERVED_STORAGE=1Gi
# 触发 Pod 驱逐操作的一组硬性限制
EVICTIONHARD_MEMORY=500Mi
EVICTIONHARD_NODEFS=10%
EVICTIONHARD_IMAGEFS=10%
# 指定 kubelet 向主控节点汇报节点状态的时间间隔
NODE_STATUS_UPDATE_FREQUENCY=10s
# kubelet 在触发软性 Pod 驱逐操作之前的最长等待时间
EVICTION_PRESSURE_TRANSITION_PERIOD=20s
# 逐一拉取镜像 默认值为 true
SERIALIZE_IMAGE_PULLS=false
# 在运行中的容器与其配置之间执行同步操作的最长时间间隔
SYNC_FREQUENCY=30s
# 如果在该参数值所设置的期限之前没有拉取镜像的进展，镜像拉取操作将被取消。默认值为 1m0s
IMAGE_PULL_PROGRESS_DEADLINE=30s
# 获取版本号纯数字方便判断版本
KUBERNETES_VER=$(echo $KUBERNETES_VERSION | awk '{print substr($0,2)}')
# runtime 配置
if [ ${RUNTIME} == "DOCKER" ]; then
  # docker 配置
  #是否开启docker0 网卡 参数: doakcer0 none k8s集群建议不用开启，单独部署请设置值为docker0
  NET_BRIDGE="none"
  # docker 最大下载线程数
  MAX_CONCURRENT_DOWNLOADS=20
  # docker 数据存放目录
  DATA_ROOT=$TOTAL_PATH/docker/data
  # 容器运行目录
  EXEC_ROOT=$TOTAL_PATH/docker/root
  # 容器日志格式
  LOG_DRIVER=json-file
  # 输出日志大小
  LOG_OPTS_MAX_SIZE=100M
  # 保留日志文件
  LOG_OPTS_MAX_FILE=10
  # kubelet 启动配置
  AFTER_REQUIRES=cri-docker.service
  # 其它runtime 使用
  EXEC_START_PRE=""
  # docker.sock 路径
  RUN_DOCKER_SOCK=/var/run/cri-docker
  # kubelet runtime 配置
  CONTAINER_RUNTIME_ENDPOINT=unix://${RUN_DOCKER_SOCK}/cri-docker.sock
  CONTAINERD_ENDPOINT=unix://${RUN_DOCKER_SOCK}/cri-docker.sock
  # 拉取镜像使用命令
  PULL_IMAGES=${DOCKER_BIN_PATH}/docker
elif [ ${RUNTIME} == "CONTAINERD" ]; then
  # containerd 配置
  # containerd 运行目录 二进制目录
  CONTAINERD_BIN_PATH=$CONTAINERD_PATH/bin/containerd
  # sandbox_image 地址
  SANDBOX_IMAGE=${POD_INFRA_CONTAINER_IMAGE}
  # 镜像下载线程 20
  MAX_CONCURRENT_DOWNLOADS=20
  # snapshotter
  SNAPSHOTTER=overlayfs
  # containerd.sock 路径
  RUN_CONTAINERD_SOCK=/run/containerd
  # kubelet 启动出错解决
   EXEC_START_PRE=""
  #EXEC_START_PRE=$(echo -e "ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/hugetlb/systemd/system.slice\nExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/blkio/systemd/system.slice\nExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/cpuset/systemd/system.slice\nExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/devices/systemd/system.slice\nExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/net_cls,net_prio/systemd/system.slice\nExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/perf_event/systemd/system.slice\nExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/cpu,cpuacct/systemd/system.slice\nExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/freezer/systemd/system.slice\nExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/memory/systemd/system.slice\nExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/pids/systemd/system.slice\nExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/systemd/systemd/system.slice")
  # kubelet 启动配置
  AFTER_REQUIRES=containerd.service
  # kubelet runtime 配置
  CONTAINER_RUNTIME_ENDPOINT=unix://${RUN_CONTAINERD_SOCK}/containerd.sock
  CONTAINERD_ENDPOINT=unix:///${RUN_CONTAINERD_SOCK}/containerd.sock
  # 拉取镜像使用命令
  PULL_IMAGES=crictl
elif [ ${RUNTIME} == "CRIO" ]; then
  # cri-o 配置
  # 镜像存储路径
  CRIO_ROOT=$TOTAL_PATH/crio/lib/containers/storage
  # 镜像工作路径
  RUNROOT=$TOTAL_PATH/crio/run/containers/storage
  #KEYS 存储路径
  DECRYPTION_KEYS_PATH=$TOTAL_PATH/crio/keys/
  # conmon 存放路径类似containerd-shim
  CONMON_PATH=$TOTAL_PATH/crio/bin/conmon
  # WorkingDirectory PATH
  WORKINGDIRECTORY=$TOTAL_PATH/crio
  # cri-o 环境变量
  CONMON_ENV=$TOTAL_PATH/crio/bin
  # hooks_dir 路径 必须存储
  HOOKS_DIR=$TOTAL_PATH/crio/containers/oci/hooks.d
  # Maximum number of processes allowed in a container
  PIDS_LIMIT=102400
  # Path to directory in which container exit files are written to by conmon.
  CONTAINER_EXITS_DIR=$TOTAL_PATH/crio/run/crio/exits
  # Only used when manage_ns_lifecycle is true.
  NAMESPACES_DIR=$TOTAL_PATH/crio/run
  # pinns_path is the path to find the pinns binary, which is needed to manage namespace lifecycle
  PINNS_PATH=$TOTAL_PATH/crio/bin/pinns
  # runc 路径
  RUNTIME_PATH=$TOTAL_PATH/crio/bin/runc
  # runtime 运行路径
  RUNTIME_ROOT=$TOTAL_PATH/crio/run/runc
  # pause_image 地址
  PAUSE_IMAGE=${POD_INFRA_CONTAINER_IMAGE}
  # crio.sock 路径
  RUN_CRIO_SOCK=/var/run/crio
  # kubelet 启动配置
  AFTER_REQUIRES=crio.service
  # kubelet 启动出错解决
   EXEC_START_PRE=""
  #EXEC_START_PRE=$(echo -e "ExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/hugetlb/systemd/system.slice\nExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/blkio/systemd/system.slice\nExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/cpuset/systemd/system.slice\nExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/devices/systemd/system.slice\nExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/net_cls,net_prio/systemd/system.slice\nExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/perf_event/systemd/system.slice\nExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/cpu,cpuacct/systemd/system.slice\nExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/freezer/systemd/system.slice\nExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/memory/systemd/system.slice\nExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/pids/systemd/system.slice\nExecStartPre=-/bin/mkdir -p /sys/fs/cgroup/systemd/systemd/system.slice")
  # kubelet runtime 配置
  CONTAINER_RUNTIME_ENDPOINT=unix://${RUN_CRIO_SOCK}/crio.sock
  CONTAINERD_ENDPOINT=unix://${RUN_CRIO_SOCK}/crio.sock
  # 拉取镜像使用命令
  PULL_IMAGES=crictl
fi
#　disable ipv6
#- name: disabled ipv6
# shell: nmcli c modify "System {{ ansible_default_ipv4.interface }}" ipv6.method ignore
# when: ansible_distribution_major_version == '8' and  ansible_os_family == 'RedHat' or  ansible_os_family == 'Rocky'
#- name: restarted service NetworkManager
# service:
#   name: NetworkManager 
#   state: restarted
# when: ansible_os_family == 'RedHat' or ansible_os_family == 'Rocky'
# 后端 kube-apiserver ip列表
CP_HOSTS=$(echo $K8S_APISERVER_VIP | sed -e "s/\"//g")
#######
RED="31m"    # Error message
GREEN="32m"  # Success message
YELLOW="33m" # Warning message
BLUE="36m"   # Info message
colorEcho() {
  echo -e "\033[${1}${@:2}\033[0m" 1>&2
}
#下载文件包

downloadK8S() {
  Proxy
  colorEcho ${GREEN} "download for K8S file."
  if [[ ! -d "${DOWNLOAD_PATH}" ]]; then
    mkdir -p ${DOWNLOAD_PATH}
  else
    colorEcho ${GREEN} '文件夹已经存在'
  fi
  # 下载etcd
  wget -c --tries=40 https://github.com/etcd-io/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz \
    -O $DOWNLOAD_PATH/etcd-${ETCD_VERSION}-linux-amd64.tar.gz
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "download  FATAL etcd."
    exit $?
  fi
  # 下载kubernetes
  wget -c --tries=40 https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/kubernetes-server-linux-amd64.tar.gz \
    -O $DOWNLOAD_PATH/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}.tar.gz
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "download  FATAL kubernetes."
    exit $?
  fi
  # 下载cni
  wget -c --tries=40 https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz \
    -O $DOWNLOAD_PATH/cni-plugins-linux-amd64-${CNI_VERSION}.tgz
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "download  FATAL cni."
    exit $?
  fi
  if [ ${IPTABLES_INSTALL} == "ON" ]; then
    # 下载iptables
    curl -C - https://www.netfilter.org/projects/iptables/files/iptables-${IPTABLES_VERSION}.tar.bz2 \
      -o $DOWNLOAD_PATH/iptables-${IPTABLES_VERSION}.tar.bz2
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "download  FATAL iptables."
      exit $?
    fi
  else
    colorEcho ${BLUE} '不升级iptables'
  fi
  if [[ ${RUNTIME} == "DOCKER" ]]; then
    # 下载docker
    wget -c --tries=40 https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz \
      -O $DOWNLOAD_PATH/docker-${DOCKER_VERSION}.tgz
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "download  FATAL docker."
      exit $?
    fi
    # 下载 docker-cri
    wget -c --tries=40 https://github.com/Mirantis/cri-dockerd/releases/download/v${CRI_DOCKER_VERSION}/cri-dockerd-${CRI_DOCKER_VERSION}.amd64.tgz \
      -O $DOWNLOAD_PATH/cri-dockerd-${CRI_DOCKER_VERSION}.amd64.tgz
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "download  FATAL cri-dockerd."
      exit $?
    fi
  elif [[ ${RUNTIME} == "CONTAINERD" ]]; then
    # 下载crictl
    wget -c --tries=40 https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz \
      -O $DOWNLOAD_PATH/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "download  FATAL crictl."
      exit $?
    fi
    # 下载runc
    wget -c --tries=40 https://github.com/opencontainers/runc/releases/download/${RUNC_VERSION}/runc.amd64 \
      -O $DOWNLOAD_PATH/runc-${RUNC_VERSION}
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "download  FATAL runc."
      exit $?
    fi
    # 下载containerd
    wget -c --tries=40 https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-amd64.tar.gz \
      -O $DOWNLOAD_PATH/containerd-${CONTAINERD_VERSION}.linux-amd64.tar.gz
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "download  FATAL containerd."
      exit $?
    fi
  elif [[ ${RUNTIME} == "CRIO" ]]; then
    # 下载crio
    wget -c --tries=40 ${DOWNLOAD_CRIO_VERSION} \
      -O $DOWNLOAD_PATH/crio-${CRIO_VERSION}.tar.gz
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "download  FATAL crio."
      exit $?
    fi
  fi
  UNProxy
  return 0
}
# return 1: not apt, yum
getPMT() {
  if [[ -n $(command -v apt) ]]; then
    CMD_INSTALL="apt -y -qq install"
    CMD_UPDATE="apt -qq update"
    CMD_UPGRADE="apt -y -qq upgrade"
  elif [[ -n $(command -v yum) ]]; then
    rpm -q epel-release
    if [[ $? -gt 0 ]]; then
      yum -y -q install epel-release
    fi
    CMD_INSTALL="yum -y -q install"
    CMD_UPDATE="yum -q makecache"
    CMD_UPGRADE="yum -y -q update"
  else
    return 1
  fi
  return 0
}

function version_lt() {
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" = "$1"
}

function version_gt() {
  test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

ansibleInstall() {
  getPMT
  if [[ -n $(command -v ansible) ]]; then
    CMD_ANSIBLE=$(command -v ansible)
    ANSIBLE_VERSION=$($CMD_ANSIBLE --version | awk 'NR==1{print $2}')
    colorEcho ${GREEN} ${ANSIBLE_VERSION}
    if version_lt ${ANSIBLE_VERSION} 2.8.0; then
      $CMD_UPDATE
      $CMD_UPGRADE ansible
    else
      colorEcho ${GREEN} "ansibel ok"
    fi
  else
    $CMD_UPDATE
    $CMD_INSTALL ansible sshpass
  fi
  return 0
}
kubectlInstall() {
  Proxy
  colorEcho ${GREEN} "download for K8S file."
  if [[ ! -d "${DOWNLOAD_PATH}" ]]; then
    mkdir -p ${DOWNLOAD_PATH}
  else
    colorEcho ${GREEN} '文件夹已经存在'
  fi
  # 下载kubernetes client
  if [[ ! -n $(command -v kubectl) ]]; then
    wget -c --tries=40 https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/kubernetes-client-linux-amd64.tar.gz \
      -O $DOWNLOAD_PATH/kubernetes-client-linux-amd64-${KUBERNETES_VERSION}.tar.gz
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "download  FATAL kubernetes-client."
      exit $?
    fi
    mkdir -p $DOWNLOAD_PATH/kubernetes-client-linux-amd64-${KUBERNETES_VERSION}
    tar -xf $DOWNLOAD_PATH/kubernetes-client-linux-amd64-${KUBERNETES_VERSION}.tar.gz -C $DOWNLOAD_PATH/kubernetes-client-linux-amd64-${KUBERNETES_VERSION}
    cp -pdr $DOWNLOAD_PATH/kubernetes-client-linux-amd64-${KUBERNETES_VERSION}/kubernetes/client/bin/kubectl /usr/bin/kubectl
  fi
  UNProxy
  return 0
}
cfsslInstall() {
  Proxy
  if [[ ! -n $(command -v cfssl) ]]; then
    wget -c --tries=40 https://github.com/cloudflare/cfssl/releases/download/v${CFSSL_VERSION}/cfssl_${CFSSL_VERSION}_linux_amd64 \
      -O $DOWNLOAD_PATH/cfssl
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "download  FATAL cfssl."
      exit $?
    fi
    cp -pdr $DOWNLOAD_PATH/cfssl /usr/bin/cfssl
    chmod +x /usr/bin/cfssl
  fi
  if [[ ! -n $(command -v cfssljson) ]]; then
    wget -c --tries=40 https://github.com/cloudflare/cfssl/releases/download/v${CFSSL_VERSION}/cfssljson_${CFSSL_VERSION}_linux_amd64 \
      -O $DOWNLOAD_PATH/cfssljson
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "download  FATAL cfssljson."
      exit $?
    fi
    cp -pdr $DOWNLOAD_PATH/cfssljson /usr/bin/cfssljson
    chmod +x /usr/bin/cfssljson
  fi
  UNProxy
  return 0
}
etcdCert() {
  colorEcho ${GREEN} "create for etcd cert."
  if [[ ! -d "${HOST_PATH}/cfssl/etcd" ]]; then
    mkdir -p ${HOST_PATH}/cfssl/etcd
  else
    colorEcho ${GREEN} '文件夹已经存在'
  fi
  if [[ ! -d "${HOST_PATH}/cfssl/pki/etcd" ]]; then
    mkdir -p ${HOST_PATH}/cfssl/pki/etcd
  else
    colorEcho ${GREEN} '文件夹已经存在'
  fi
  # CA 配置文件用于配置根证书的使用场景 (profile) 和具体参数 (usage，过期时间、服务端认证、客户端认证、加密等)，后续在签名其它证书时需要指定特定场景。
  cat >${HOST_PATH}/cfssl/ca-config.json <<EOF
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
  cat >${HOST_PATH}/cfssl/etcd/etcd-ca-csr.json <<EOF
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
  cat >${HOST_PATH}/cfssl/etcd/etcd-server.json <<EOF
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
  cat >${HOST_PATH}/cfssl/etcd/${ETCD_MEMBER_1_HOSTNAMES}.json <<EOF
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
  cat >${HOST_PATH}/cfssl/etcd/${ETCD_MEMBER_2_HOSTNAMES}.json <<EOF
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
  cat >${HOST_PATH}/cfssl/etcd/${ETCD_MEMBER_3_HOSTNAMES}.json <<EOF
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
  if [ ${K8S_EVENTS} == "ON" ]; then
    # 创建 ETCD EVENTS Server 配置文件
    cat >${HOST_PATH}/cfssl/etcd/etcd-events.json <<EOF
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
    cat >${HOST_PATH}/cfssl/etcd/${ETCD_EVENTS_MEMBER_1_HOSTNAMES}.json <<EOF
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
    cat >${HOST_PATH}/cfssl/etcd/${ETCD_EVENTS_MEMBER_2_HOSTNAMES}.json <<EOF
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
    cat >${HOST_PATH}/cfssl/etcd/${ETCD_EVENTS_MEMBER_3_HOSTNAMES}.json <<EOF
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
  cat >${HOST_PATH}/cfssl/etcd/etcd-client.json <<EOF
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

  if [[ ! -e "${HOST_PATH}/cfssl/pki/etcd/etcd-ca.pem" ]] || [[ ! -e "${HOST_PATH}/cfssl/pki/etcd/etcd-ca-key.pem" ]]; then
    # etcd ca 证书签发
    cfssl gencert -initca ${HOST_PATH}/cfssl/etcd/etcd-ca-csr.json |
      cfssljson -bare ${HOST_PATH}/cfssl/pki/etcd/etcd-ca
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL etcd-ca."
      exit $?
    fi
  fi
  if [[ ! -e "${HOST_PATH}/cfssl/pki/etcd/etcd-server.pem" ]] || [[ ! -e "${HOST_PATH}/cfssl/pki/etcd/etcd-server-key.pem" ]]; then
    ## 生成 ETCD Server 证书和私钥
    cfssl gencert \
      -ca=${HOST_PATH}/cfssl/pki/etcd/etcd-ca.pem \
      -ca-key=${HOST_PATH}/cfssl/pki/etcd/etcd-ca-key.pem \
      -config=${HOST_PATH}/cfssl/ca-config.json \
      -profile=${CERT_PROFILE} \
      ${HOST_PATH}/cfssl/etcd/etcd-server.json |
      cfssljson -bare ${HOST_PATH}/cfssl/pki/etcd/etcd-server
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL etcd-server."
      exit $?
    fi
  fi
  # 生成 ETCD Member 1 证书和私钥
  if [[ ! -e "${HOST_PATH}/cfssl/pki/etcd/etcd-member-${ETCD_MEMBER_1_HOSTNAMES}.pem" ]] || [[ ! -e "${HOST_PATH}/cfssl/pki/etcd/etcd-member-${ETCD_MEMBER_1_HOSTNAMES}-key.pem" ]]; then
    cfssl gencert \
      -ca=${HOST_PATH}/cfssl/pki/etcd/etcd-ca.pem \
      -ca-key=${HOST_PATH}/cfssl/pki/etcd/etcd-ca-key.pem \
      -config=${HOST_PATH}/cfssl/ca-config.json \
      -profile=${CERT_PROFILE} \
      ${HOST_PATH}/cfssl/etcd/${ETCD_MEMBER_1_HOSTNAMES}.json |
      cfssljson -bare ${HOST_PATH}/cfssl/pki/etcd/etcd-member-${ETCD_MEMBER_1_HOSTNAMES}
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL etcd-member-${ETCD_MEMBER_1_HOSTNAMES}."
      exit $?
    fi
  fi
  # 生成 ETCD Member 2 证书和私钥
  if [[ ! -e "${HOST_PATH}/cfssl/pki/etcd/etcd-member-${ETCD_MEMBER_2_HOSTNAMES}.pem" ]] || [[ ! -e "${HOST_PATH}/cfssl/pki/etcd/etcd-member-${ETCD_MEMBER_2_HOSTNAMES}-key.pem" ]]; then
    cfssl gencert \
      -ca=${HOST_PATH}/cfssl/pki/etcd/etcd-ca.pem \
      -ca-key=${HOST_PATH}/cfssl/pki/etcd/etcd-ca-key.pem \
      -config=${HOST_PATH}/cfssl/ca-config.json \
      -profile=${CERT_PROFILE} \
      ${HOST_PATH}/cfssl/etcd/${ETCD_MEMBER_2_HOSTNAMES}.json |
      cfssljson -bare ${HOST_PATH}/cfssl/pki/etcd/etcd-member-${ETCD_MEMBER_2_HOSTNAMES}
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL etcd-member-${ETCD_MEMBER_2_HOSTNAMES}."
      exit $?
    fi
  fi
  if [[ ! -e "${HOST_PATH}/cfssl/pki/etcd/etcd-member-${ETCD_MEMBER_3_HOSTNAMES}.pem" ]] || [[ ! -e "${HOST_PATH}/cfssl/pki/etcd/etcd-member-${ETCD_MEMBER_3_HOSTNAMES}-key.pem" ]]; then
    # 生成 ETCD Member 3 证书和私钥
    cfssl gencert \
      -ca=${HOST_PATH}/cfssl/pki/etcd/etcd-ca.pem \
      -ca-key=${HOST_PATH}/cfssl/pki/etcd/etcd-ca-key.pem \
      -config=${HOST_PATH}/cfssl/ca-config.json \
      -profile=${CERT_PROFILE} \
      ${HOST_PATH}/cfssl/etcd/${ETCD_MEMBER_3_HOSTNAMES}.json |
      cfssljson -bare ${HOST_PATH}/cfssl/pki/etcd/etcd-member-${ETCD_MEMBER_3_HOSTNAMES}
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL etcd-member-${ETCD_MEMBER_3_HOSTNAMES}."
      exit $?
    fi
  fi
  if [ ${K8S_EVENTS} == "ON" ]; then

    if [[ ! -e "${HOST_PATH}/cfssl/pki/etcd/etcd-events.pem" ]] || [[ ! -e "${HOST_PATH}/cfssl/pki/etcd/etcd-events-key.pem" ]]; then
      ## 生成 ETCD EVENTS Server 证书和私钥
      cfssl gencert \
        -ca=${HOST_PATH}/cfssl/pki/etcd/etcd-ca.pem \
        -ca-key=${HOST_PATH}/cfssl/pki/etcd/etcd-ca-key.pem \
        -config=${HOST_PATH}/cfssl/ca-config.json \
        -profile=${CERT_PROFILE} \
        ${HOST_PATH}/cfssl/etcd/etcd-events.json |
        cfssljson -bare ${HOST_PATH}/cfssl/pki/etcd/etcd-events
      if [[ $? -ne 0 ]]; then
        colorEcho ${RED} "cfssl  FATAL etcd-events."
        exit $?
      fi
    fi
    # 生成 ETCD EVENTS Member 1 证书和私钥
    if [[ ! -e "${HOST_PATH}/cfssl/pki/etcd/etcd-events-${ETCD_EVENTS_MEMBER_1_HOSTNAMES}.pem" ]] || [[ ! -e "${HOST_PATH}/cfssl/pki/etcd/etcd-events-${ETCD_EVENTS_MEMBER_1_HOSTNAMES}-key.pem" ]]; then
      cfssl gencert \
        -ca=${HOST_PATH}/cfssl/pki/etcd/etcd-ca.pem \
        -ca-key=${HOST_PATH}/cfssl/pki/etcd/etcd-ca-key.pem \
        -config=${HOST_PATH}/cfssl/ca-config.json \
        -profile=${CERT_PROFILE} \
        ${HOST_PATH}/cfssl/etcd/${ETCD_EVENTS_MEMBER_1_HOSTNAMES}.json |
        cfssljson -bare ${HOST_PATH}/cfssl/pki/etcd/etcd-events-${ETCD_EVENTS_MEMBER_1_HOSTNAMES}
      if [[ $? -ne 0 ]]; then
        colorEcho ${RED} "cfssl  FATAL etcd-events-${ETCD_EVENTS_MEMBER_1_HOSTNAMES}."
        exit $?
      fi
    fi
    if [[ ! -e "${HOST_PATH}/cfssl/pki/etcd/etcd-events-${ETCD_EVENTS_MEMBER_2_HOSTNAMES}.pem" ]] || [[ ! -e "${HOST_PATH}/cfssl/pki/etcd/etcd-events-${ETCD_EVENTS_MEMBER_2_HOSTNAMES}-key.pem" ]]; then
      # 生成 ETCD EVENTS  Member 2 证书和私钥
      cfssl gencert \
        -ca=${HOST_PATH}/cfssl/pki/etcd/etcd-ca.pem \
        -ca-key=${HOST_PATH}/cfssl/pki/etcd/etcd-ca-key.pem \
        -config=${HOST_PATH}/cfssl/ca-config.json \
        -profile=${CERT_PROFILE} \
        ${HOST_PATH}/cfssl/etcd/${ETCD_EVENTS_MEMBER_2_HOSTNAMES}.json |
        cfssljson -bare ${HOST_PATH}/cfssl/pki/etcd/etcd-events-${ETCD_EVENTS_MEMBER_2_HOSTNAMES}
      if [[ $? -ne 0 ]]; then
        colorEcho ${RED} "cfssl  FATAL etcd-events-${ETCD_EVENTS_MEMBER_2_HOSTNAMES}."
        exit $?
      fi
    fi
    if [[ ! -e "${HOST_PATH}/cfssl/pki/etcd/etcd-events-${ETCD_EVENTS_MEMBER_3_HOSTNAMES}.pem" ]] || [[ ! -e "${HOST_PATH}/cfssl/pki/etcd/etcd-events-${ETCD_EVENTS_MEMBER_3_HOSTNAMES}-key.pem" ]]; then
      # 生成 ETCD EVENTS Member 3 证书和私钥
      cfssl gencert \
        -ca=${HOST_PATH}/cfssl/pki/etcd/etcd-ca.pem \
        -ca-key=${HOST_PATH}/cfssl/pki/etcd/etcd-ca-key.pem \
        -config=${HOST_PATH}/cfssl/ca-config.json \
        -profile=${CERT_PROFILE} \
        ${HOST_PATH}/cfssl/etcd/${ETCD_EVENTS_MEMBER_3_HOSTNAMES}.json |
        cfssljson -bare ${HOST_PATH}/cfssl/pki/etcd/etcd-events-${ETCD_EVENTS_MEMBER_3_HOSTNAMES}
      if [[ $? -ne 0 ]]; then
        colorEcho ${RED} "cfssl  FATAL etcd-events-${ETCD_EVENTS_MEMBER_3_HOSTNAMES}."
        exit $?
      fi
    fi
  fi
  if [[ ! -e "${HOST_PATH}/cfssl/pki/etcd/etcd-client.pem" ]] || [[ ! -e "${HOST_PATH}/cfssl/pki/etcd/etcd-client-key.pem" ]]; then
    # 生成 ETCD Client 证书和私钥
    cfssl gencert \
      -ca=${HOST_PATH}/cfssl/pki/etcd/etcd-ca.pem \
      -ca-key=${HOST_PATH}/cfssl/pki/etcd/etcd-ca-key.pem \
      -config=${HOST_PATH}/cfssl/ca-config.json \
      -profile=${CERT_PROFILE} \
      ${HOST_PATH}/cfssl/etcd/etcd-client.json |
      cfssljson -bare ${HOST_PATH}/cfssl/pki/etcd/etcd-client
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL etcd-events-${ETCD_EVENTS_MEMBER_1_HOSTNAMES}."
      exit $?
    fi
  fi
  return 0
}
k8sCert() {
  colorEcho ${GREEN} "create for k8s cert."
  if [[ ! -d "${HOST_PATH}/cfssl/k8s" ]]; then
    mkdir -p ${HOST_PATH}/cfssl/k8s
  else
    colorEcho ${GREEN} '文件夹已经存在'
  fi
  if [[ ! -d "${HOST_PATH}/cfssl/pki/k8s" ]]; then
    mkdir -p ${HOST_PATH}/cfssl/pki/k8s
  else
    colorEcho ${GREEN} '文件夹已经存在'
  fi
  # CA 配置文件用于配置根证书的使用场景 (profile) 和具体参数 (usage，过期时间、服务端认证、客户端认证、加密等)，后续在签名其它证书时需要指定特定场景。
  cat >${HOST_PATH}/cfssl/ca-config.json <<EOF
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
  # 创建 Kubernetes CA 配置文件
  cat >${HOST_PATH}/cfssl/k8s/k8s-ca-csr.json <<EOF
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
  cat >${HOST_PATH}/cfssl/k8s/k8s-apiserver.json <<EOF
{
  "CN": "$CLUSTER_NAME",
  "hosts": [
    ${K8S_APISERVER_VIP},
    "${CLUSTER_KUBERNETES_SVC_IP}", 
    ${K8S_SSL},
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
  cat >${HOST_PATH}/cfssl/k8s/aggregator.json <<EOF
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
  cat >${HOST_PATH}/cfssl/k8s/k8s-controller-manager.json <<EOF
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
  cat >${HOST_PATH}/cfssl/k8s/k8s-scheduler.json <<EOF
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
  cat >${HOST_PATH}/cfssl/k8s/k8s-apiserver-admin.json <<EOF
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
  # 创建kube-proxy 证书配置
  cat >${HOST_PATH}/cfssl/k8s/kube-proxy.json <<EOF
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
      "O": "system:node-proxier",
      "OU": "Kubernetes-manual"
    }
  ]
}
EOF
  # 生成 Kubernetes CA 证书和私钥
  if [[ ! -e "${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem" ]] || [[ ! -e "${HOST_PATH}/cfssl/pki/k8s/k8s-ca-key.pem" ]]; then
    cfssl gencert -initca ${HOST_PATH}/cfssl/k8s/k8s-ca-csr.json |
      cfssljson -bare ${HOST_PATH}/cfssl/pki/k8s/k8s-ca
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL k8s-ca."
      exit $?
    fi
  fi
  if [[ ! -e "${HOST_PATH}/cfssl/pki/k8s/k8s-server.pem" ]] || [[ ! -e "${HOST_PATH}/cfssl/pki/k8s/k8s-server-key.pem" ]]; then
    # 生成 Kubernetes API Server 证书和私钥
    cfssl gencert \
      -ca=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
      -ca-key=${HOST_PATH}/cfssl/pki/k8s/k8s-ca-key.pem \
      -config=${HOST_PATH}/cfssl/ca-config.json \
      -profile=${CERT_PROFILE} \
      ${HOST_PATH}/cfssl/k8s/k8s-apiserver.json |
      cfssljson -bare ${HOST_PATH}/cfssl/pki/k8s/k8s-server
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL k8s-server."
      exit $?
    fi
  fi
  if [[ ! -e "${HOST_PATH}/cfssl/pki/k8s/aggregator.pem" ]] || [[ ! -e "${HOST_PATH}/cfssl/pki/k8s/aggregator-key.pem" ]]; then
    # 生成 Kubernetes webhook 证书和私钥
    cfssl gencert \
      -ca=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
      -ca-key=${HOST_PATH}/cfssl/pki/k8s/k8s-ca-key.pem \
      -config=${HOST_PATH}/cfssl/ca-config.json \
      -profile=${CERT_PROFILE} \
      ${HOST_PATH}/cfssl/k8s/aggregator.json |
      cfssljson -bare ${HOST_PATH}/cfssl/pki/k8s/aggregator
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL aggregator."
      exit $?
    fi
  fi
  if [[ ! -e "${HOST_PATH}/cfssl/pki/k8s/k8s-controller-manager.pem" ]] || [[ ! -e "${HOST_PATH}/cfssl/pki/k8s/k8s-controller-manager-key.pem" ]]; then
    # 生成 Kubernetes Controller Manager 证书和私钥
    cfssl gencert \
      -ca=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
      -ca-key=${HOST_PATH}/cfssl/pki/k8s/k8s-ca-key.pem \
      -config=${HOST_PATH}/cfssl/ca-config.json \
      -profile=${CERT_PROFILE} \
      ${HOST_PATH}/cfssl/k8s/k8s-controller-manager.json |
      cfssljson -bare ${HOST_PATH}/cfssl/pki/k8s/k8s-controller-manager
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL k8s-controller-manager."
      exit $?
    fi
  fi
  if [[ ! -e "${HOST_PATH}/cfssl/pki/k8s/k8s-scheduler.pem" ]] || [[ ! -e "${HOST_PATH}/cfssl/pki/k8s/k8s-scheduler-key.pem" ]]; then
    # 生成 Kubernetes Scheduler 证书和私钥
    cfssl gencert \
      -ca=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
      -ca-key=${HOST_PATH}/cfssl/pki/k8s/k8s-ca-key.pem \
      -config=${HOST_PATH}/cfssl/ca-config.json \
      -profile=${CERT_PROFILE} \
      ${HOST_PATH}/cfssl/k8s/k8s-scheduler.json |
      cfssljson -bare ${HOST_PATH}/cfssl/pki/k8s/k8s-scheduler
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL k8s-scheduler."
      exit $?
    fi
  fi
  if [[ ! -e "${HOST_PATH}/cfssl/pki/k8s/k8s-apiserver-admin.pem" ]] || [[ ! -e "${HOST_PATH}/cfssl/pki/k8s/k8s-apiserver-admin-key.pem" ]]; then
    # 生成 Kubernetes admin管理员证书
    cfssl gencert -ca=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
      -ca-key=${HOST_PATH}/cfssl/pki/k8s/k8s-ca-key.pem \
      -config=${HOST_PATH}/cfssl/ca-config.json \
      -profile=${CERT_PROFILE} \
      ${HOST_PATH}/cfssl/k8s/k8s-apiserver-admin.json |
      cfssljson -bare ${HOST_PATH}/cfssl/pki/k8s/k8s-apiserver-admin
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL k8s-apiserver-admin."
      exit $?
    fi
  fi
  if [[ ! -e "${HOST_PATH}/cfssl/pki/k8s/kube-proxy.pem" ]] || [[ ! -e "${HOST_PATH}/cfssl/pki/k8s/kube-proxy-key.pem" ]]; then
    # 生成 kube-proxy 证书和私钥
    cfssl gencert \
      -ca=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
      -ca-key=${HOST_PATH}/cfssl/pki/k8s/k8s-ca-key.pem \
      -config=${HOST_PATH}/cfssl/ca-config.json \
      -profile=${CERT_PROFILE} \
      ${HOST_PATH}/cfssl/k8s/kube-proxy.json |
      cfssljson -bare ${HOST_PATH}/cfssl/pki/k8s/kube-proxy
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL kube-proxy."
      exit $?
    fi
  fi
  return 0
}
k8sKubeConfig() {
  colorEcho ${GREEN} "create for k8s KubeConfig."
  if [[ ! -d "${HOST_PATH}/kubeconfig" ]]; then
    mkdir -p ${HOST_PATH}/kubeconfig
  else
    colorEcho ${GREEN} '文件夹已经存在'
  fi
  if [[ ! -n $(command -v kubectl) ]]; then
    colorEcho ${GREEN} "download kubectl FATAL kubectl "
    exit $?
  fi
  if [[ ! -e "${HOST_PATH}/kubeconfig/admin.kubeconfig" ]]; then
    # 创建admin管理员登录kubeconfig
    # 设置集群参数
    kubectl config set-cluster ${CLUSTER_NAME} \
      --certificate-authority=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
      --embed-certs=true \
      --server=${KUBE_APISERVER} \
      --kubeconfig=${HOST_PATH}/kubeconfig/admin.kubeconfig
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL admin.kubeconfig."
      exit $?
    fi
    # 设置客户端认证参数
    kubectl config set-credentials admin \
      --client-certificate=${HOST_PATH}/cfssl/pki/k8s/k8s-apiserver-admin.pem \
      --client-key=${HOST_PATH}/cfssl/pki/k8s/k8s-apiserver-admin-key.pem \
      --embed-certs=true \
      --kubeconfig=${HOST_PATH}/kubeconfig/admin.kubeconfig
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL admin.kubeconfig."
      exit $?
    fi
    # 设置上下文参数
    kubectl config set-context ${CLUSTER_NAME} \
      --cluster=${CLUSTER_NAME} \
      --user=admin \
      --namespace=kube-system \
      --kubeconfig=${HOST_PATH}/kubeconfig/admin.kubeconfig
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL admin.kubeconfig."
      exit $?
    fi
    # 设置默认上下文
    kubectl config use-context ${CLUSTER_NAME} --kubeconfig=${HOST_PATH}/kubeconfig/admin.kubeconfig
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL admin.kubeconfig."
      exit $?
    fi
  fi
  if [[ ! -e "${HOST_PATH}/kubeconfig/kube-controller-manager.kubeconfig" ]]; then
    # 创建kube-scheduler kubeconfig 配置文件
    # 设置集群参数
    kubectl config set-cluster ${CLUSTER_NAME} \
      --certificate-authority=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
      --embed-certs=true \
      --server=${KUBE_API_KUBELET} \
      --kubeconfig=${HOST_PATH}/kubeconfig/kube-scheduler.kubeconfig
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL kube-scheduler.kubeconfig."
      exit $?
    fi
    # 设置客户端认证参数
    kubectl config set-credentials system:kube-scheduler \
      --client-certificate=${HOST_PATH}/cfssl/pki/k8s/k8s-scheduler.pem \
      --embed-certs=true \
      --client-key=${HOST_PATH}/cfssl/pki/k8s/k8s-scheduler-key.pem \
      --kubeconfig=${HOST_PATH}/kubeconfig/kube-scheduler.kubeconfig
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL kube-scheduler.kubeconfig."
      exit $?
    fi
    # 设置上下文参数
    kubectl config set-context ${CLUSTER_NAME} \
      --cluster=${CLUSTER_NAME} \
      --user=system:kube-scheduler \
      --kubeconfig=${HOST_PATH}/kubeconfig/kube-scheduler.kubeconfig
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL kube-scheduler.kubeconfig."
      exit $?
    fi
    # 设置默认上下文
    kubectl config use-context ${CLUSTER_NAME} --kubeconfig=${HOST_PATH}/kubeconfig/kube-scheduler.kubeconfig
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL kube-scheduler.kubeconfig."
      exit $?
    fi
  fi
  if [[ ! -e "${HOST_PATH}/kubeconfig/kube-controller-manager.kubeconfig" ]]; then
    # 创建kube-controller-manager kubeconfig 配置文件
    # 设置集群参数
    kubectl config set-cluster ${CLUSTER_NAME} \
      --certificate-authority=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
      --embed-certs=true \
      --server=${KUBE_API_KUBELET} \
      --kubeconfig=${HOST_PATH}/kubeconfig/kube-controller-manager.kubeconfig
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL kube-controller-manager.kubeconfig."
      exit $?
    fi
    # 设置客户端认证参数
    kubectl config set-credentials system:kube-controller-manager \
      --client-certificate=${HOST_PATH}/cfssl/pki/k8s/k8s-controller-manager.pem \
      --embed-certs=true \
      --client-key=${HOST_PATH}/cfssl/pki/k8s/k8s-controller-manager-key.pem \
      --kubeconfig=${HOST_PATH}/kubeconfig/kube-controller-manager.kubeconfig
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL kube-controller-manager.kubeconfig."
      exit $?
    fi
    # 设置上下文参数
    kubectl config set-context ${CLUSTER_NAME} \
      --cluster=${CLUSTER_NAME} \
      --user=system:kube-controller-manager \
      --kubeconfig=${HOST_PATH}/kubeconfig/kube-controller-manager.kubeconfig
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL kube-controller-manager.kubeconfig."
      exit $?
    fi
    # 设置默认上下文
    kubectl config use-context ${CLUSTER_NAME} --kubeconfig=${HOST_PATH}/kubeconfig/kube-controller-manager.kubeconfig
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL kube-controller-manager.kubeconfig."
      exit $?
    fi
  fi
  # 创建kube-proxy kubeconfig 配置文件
  # 设置集群参数
  if [[ ! -e "${HOST_PATH}/kubeconfig/kube-proxy.kubeconfig" ]]; then
    kubectl config set-cluster ${CLUSTER_NAME} \
      --certificate-authority=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
      --embed-certs=true \
      --server=${KUBE_API_KUBELET} \
      --kubeconfig=${HOST_PATH}/kubeconfig/kube-proxy.kubeconfig
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL kube-proxy.kubeconfig."
      exit $?
    fi
    # 设置客户端认证参数
    kubectl config set-credentials system:kube-proxy \
      --client-certificate=${HOST_PATH}/cfssl/pki/k8s/kube-proxy.pem \
      --client-key=${HOST_PATH}/cfssl/pki/k8s/kube-proxy-key.pem \
      --embed-certs=true \
      --kubeconfig=${HOST_PATH}/kubeconfig/kube-proxy.kubeconfig
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL kube-proxy.kubeconfig."
      exit $?
    fi
    # 设置上下文参数
    kubectl config set-context default \
      --cluster=${CLUSTER_NAME} \
      --user=system:kube-proxy \
      --kubeconfig=${HOST_PATH}/kubeconfig/kube-proxy.kubeconfig
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL kube-proxy.kubeconfig."
      exit $?
    fi
    # 设置默认上下文
    kubectl config use-context default --kubeconfig=${HOST_PATH}/kubeconfig/kube-proxy.kubeconfig
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL kube-proxy.kubeconfig."
      exit $?
    fi
  fi
  return 0
}
etcdConfig() {
  colorEcho ${GREEN} "create for etcd Config."
  # 创建 etcd playbook 目录
  if [[ ! -d "${HOST_PATH}/roles/etcd/" ]]; then
    mkdir -p ${HOST_PATH}/roles/etcd/{files,tasks,templates}
  else
    colorEcho ${GREEN} '文件夹已经存在'
  fi
  if [[ -e "${DOWNLOAD_PATH}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz" ]]; then
    if [[ ! -e "${DOWNLOAD_PATH}/etcd-${ETCD_VERSION}-linux-amd64/etcd" ]] || [[ ! -e "${HOST_PATH}/roles/etcd/files/bin/etcd" ]]; then
      # cp 二进制文件及ssl 文件到 ansible 目录
      tar -xf ${DOWNLOAD_PATH}/etcd-${ETCD_VERSION}-linux-amd64.tar.gz -C ${DOWNLOAD_PATH}
      mkdir -p ${HOST_PATH}/roles/etcd/files/{ssl,bin}
      \cp -pdr ${DOWNLOAD_PATH}/etcd-${ETCD_VERSION}-linux-amd64/{etcd,etcdctl} ${HOST_PATH}/roles/etcd/files/bin
      \cp -pdr ${HOST_PATH}/cfssl/pki/etcd/*.pem ${HOST_PATH}/roles/etcd/files/ssl
    fi
  else
    colorEcho ${RED} "etcd no download."
    exit 1
  fi
  #创建etcd playbook
  cat >${HOST_PATH}/roles/etcd/tasks/main.yml <<EOF
- name: create groupadd etcd
  group: name=etcd
- name: create name etcd
  user: name=etcd shell="/sbin/nologin etcd" group=etcd
- name: Create ${ETCD_PATH}
  file:
    path: "${ETCD_PATH}/{{ item }}"
    state: directory
    owner: etcd
    group: etcd
  with_items:
      - conf
      - ssl
      - bin
- name: Create ${ETCD_WAL_DIR}
  file:
    path: "${ETCD_WAL_DIR}"
    state: directory
    owner: etcd
    group: etcd
- name: Create ${ETCD_WAL_DIR}
  file:
    path: "${ETCD_DATA_DIR}"
    state: directory
    owner: etcd
    group: etcd
- name: copy etcd
  copy: 
    src: bin 
    dest: "${ETCD_PATH}/" 
    owner: etcd 
    group: etcd 
    mode: 0755
- name: copy etcd ssl
  copy: 
    src: ssl 
    dest: "${ETCD_PATH}/" 
    owner: etcd 
    group: etcd 
- name: copy etcd config 
  template: 
    src: etcd 
    dest: "${ETCD_PATH}/conf" 
    owner: etcd 
    group: etcd 
- name: copy etcd.service
  template: 
    src: etcd.service 
    dest: "/lib/systemd/system/"
- name: Change file ownership, group and permissions etcd
  file:
    path: ${ETCD_PATH}/
    owner: etcd
    group: etcd
- name: Change file ownership, group and permissions etcd wal
  file:
    path: ${ETCD_WAL_DIR}/
    owner: etcd
    group: etcd
- name: Reload service daemon-reload
  shell: systemctl daemon-reload
- name: Enable service etcd, and not touch the state
  service:
    name: etcd
    enabled: yes
- name: Start service etcd, if not restarted
  service:
    name: etcd
    state: restarted
EOF
  # 创建etcd 启动配置文件
  cat >${HOST_PATH}/roles/etcd/templates/etcd <<EOF
ETCD_OPTS="--name={{ ansible_hostname }} \\
           --data-dir=${ETCD_DATA_DIR} \\
           --wal-dir=${ETCD_WAL_DIR} \\
           --listen-peer-urls=https://{{ $ETCD_IPV4 }}:2380 \\
           --listen-client-urls=https://{{ $ETCD_IPV4 }}:2379,https://127.0.0.1:2379 \\
           --advertise-client-urls=https://{{ $ETCD_IPV4 }}:2379 \\
           --initial-advertise-peer-urls=https://{{ $ETCD_IPV4 }}:2380 \\
           --initial-cluster={{ INITIAL_CLUSTER }} \\
           --initial-cluster-token={{ INITIAL_CLUSTER_TOKEN }} \\
           --initial-cluster-state=new \\
           --heartbeat-interval=${HEARTBEAT_INTERVAL} \\
           --election-timeout=${ELECTION_TIMEOUT} \\
           --snapshot-count=${SNAPSHOT_COUNT} \\
           --auto-compaction-retention=${AUTO_COMPACTION_RETENTION} \\
           --max-request-bytes=${MAX_REQUEST_BYTES} \\
           --quota-backend-bytes=${QUOTA_BACKEND_BYTES} \\
           --trusted-ca-file=${ETCD_PATH}/ssl/{{ ca }}.pem \\
           --cert-file=${ETCD_PATH}/ssl/{{ cert_file }}.pem \\
           --key-file=${ETCD_PATH}/ssl/{{ cert_file }}-key.pem \\
           --peer-cert-file=${ETCD_PATH}/ssl/{{ ETCD_MEMBER }}-{{ ansible_hostname }}.pem \\
           --peer-key-file=${ETCD_PATH}/ssl/{{ ETCD_MEMBER }}-{{ ansible_hostname }}-key.pem \\
           --peer-client-cert-auth \\
           --cipher-suites=${TLS_CIPHER} \\
           --enable-v2=true \\
           --peer-trusted-ca-file=${ETCD_PATH}/ssl/{{ ca }}.pem"
EOF
  # 创建etcd 启动文件
  cat >${HOST_PATH}/roles/etcd/templates/etcd.service <<EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/etcd-io/etcd
[Service]
Type=notify
LimitNOFILE=${HARD_SOFT}
LimitNPROC=${HARD_SOFT}
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
  cat >${HOST_PATH}/etcd.yml <<EOF
- hosts: all
  user: root
  vars:
    cert_file: etcd-server
    ca: etcd-ca
    ETCD_MEMBER: etcd-member
    INITIAL_CLUSTER: ${INITIAL_CLUSTER}
    INITIAL_CLUSTER_TOKEN: ${INITIAL_CLUSTER_TOKEN}
  roles:
    - etcd
EOF
  if [ ${K8S_EVENTS} == "ON" ]; then
    cat >${HOST_PATH}/events-etcd.yml <<EOF
- hosts: all
  user: root
  vars:
    cert_file: etcd-events
    ca: etcd-ca
    ETCD_MEMBER: etcd-events
    INITIAL_CLUSTER: ${INITIAL_EVENTS_CLUSTER}
    INITIAL_CLUSTER_TOKEN: ${INITIAL_CLUSTER_TOKEN_EVENTS} 
  roles:
    - etcd
EOF
  fi
  return 0
}
KubeApiserverConfig() {
  colorEcho ${GREEN} "create for kube-apiserver Config."
  # 创建 kube-apiserver playbook 目录
  if [[ ! -d "${HOST_PATH}/roles/kube-apiserver/" ]]; then
    mkdir -p ${HOST_PATH}/roles/kube-apiserver/{files,tasks,templates}
  else
    colorEcho ${GREEN} '文件夹已经存在'
  fi
  if [[ -e "${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}.tar.gz" ]]; then
    if [[ ! -e "${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/kubernetes/server/bin/kube-apiserver" ]] || [[ ! -e "${HOST_PATH}/roles/kube-apiserver/files/bin/kube-apiserver" ]]; then
      # cp 二进制文件及ssl 文件到 ansible 目录
      mkdir -p ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}
      tar -xf ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}.tar.gz -C ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/
      mkdir -p ${HOST_PATH}/roles/kube-apiserver/files/{ssl,bin,config}
      mkdir -p ${HOST_PATH}/roles/kube-apiserver/files/ssl/{etcd,k8s}
      \cp -pdr ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/kubernetes/server/bin/kube-apiserver ${HOST_PATH}/roles/kube-apiserver/files/bin/
      \cp -pdr ${HOST_PATH}/cfssl/pki/etcd/{etcd-client*.pem,etcd-ca.pem} ${HOST_PATH}/roles/kube-apiserver/files/ssl/etcd
      \cp -pdr ${HOST_PATH}/cfssl/pki/k8s/{k8s-server*.pem,k8s-ca*.pem,aggregator*.pem} ${HOST_PATH}/roles/kube-apiserver/files/ssl/k8s
    fi
  else
    colorEcho ${RED} "kubernetes no download."
    exit 1
  fi
  if [[ "$DYNAMICAUDITING" == "true" ]]; then
    # 创建审计策略文件
    cat >${HOST_PATH}/roles/kube-apiserver/files/config/audit-policy.yaml <<EOF
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
    AUDIT_POLICY_FILE=$(echo -e "--audit-policy-file=${K8S_PATH}/config/audit-policy.yaml \\\\\n        --audit-log-truncate-enabled")
  else
    AUDIT_POLICY_FILE="--audit-log-truncate-enabled"
  fi
  # 创建 kube-apiserver 启动配置文件
  cat >${HOST_PATH}/roles/kube-apiserver/templates/kube-apiserver <<EOF
KUBE_APISERVER_OPTS="--bind-address={{ $KUBELET_IPV4 }} \\
        --advertise-address={{ $KUBELET_IPV4 }} \\
        --secure-port=${SECURE_PORT} \\
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
        --service-account-issuer=${SERVICE_ACCOUNT_ISSUER} \\
        --service-account-signing-key-file=${K8S_PATH}/ssl/k8s/k8s-ca-key.pem \\
        --requestheader-allowed-names=aggregator \\
        --requestheader-group-headers=X-Remote-Group \\
        --requestheader-extra-headers-prefix=X-Remote-Extra- \\
        --requestheader-username-headers=X-Remote-User \\
        --enable-aggregator-routing=true \\
        --anonymous-auth=false \\
        --encryption-provider-config=${K8S_PATH}/config/encryption-config.yaml \\
        --enable-admission-plugins=${ENABLE_ADMISSION_PLUGINS} \\
        --disable-admission-plugins=${DISABLE_ADMISSION_PLUGINS} \\
        --cors-allowed-origins=.* \\
        --runtime-config=${RUNTIME_CONFIG} \\
        --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname \\
        --authorization-mode=Node,RBAC \\
        --allow-privileged=true \\
        --apiserver-count=${APISERVER_COUNT} \\
        --audit-log-maxage=30 \\
        --audit-log-maxbackup=3 \\
        --audit-log-maxsize=100 \\
        --default-not-ready-toleration-seconds=${DEFAULT_NOT_READY_TOLERATION_SECONDS} \\
        --default-unreachable-toleration-seconds=${DEFAULT_UNREACHABLE_TOLERATION_SECONDS} \\
        ${AUDIT_POLICY_FILE} \\
        --audit-log-path=${K8S_PATH}/log/api-server-audit.log \\
        --profiling \\
        --http2-max-streams-per-connection=10000 \\
        --event-ttl=1h \\
        --enable-bootstrap-token-auth=true \\
        --v=${LEVEL_LOG} \\
        --tls-cipher-suites=${TLS_CIPHER} \\
        --endpoint-reconciler-type=lease \\
        --max-mutating-requests-inflight=${MAX_MUTATING_REQUESTS_INFLIGHT} \\
        --max-requests-inflight=${MAX_REQUESTS_INFLIGHT}"
EOF
  # 创建 kube-apiserver 启动文件
  cat >${HOST_PATH}/roles/kube-apiserver/templates/kube-apiserver.service <<EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
Type=notify
LimitNOFILE=${HARD_SOFT}
LimitNPROC=${HARD_SOFT}
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
  if [[ ! -e ${HOST_PATH}/roles/kube-apiserver/files/config/encryption-config.yaml ]]; then
    # 生成encryption-config.yaml
    cat >${HOST_PATH}/roles/kube-apiserver/files/config/encryption-config.yaml <<EOF
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
  fi
  # 创建kube-apiserver playbook
  cat >${HOST_PATH}/roles/kube-apiserver/tasks/main.yml <<EOF
- name: create groupadd k8s
  group: name=k8s
- name: create name k8s
  user: name=k8s shell="/sbin/nologin k8s" group=k8s
- name: Create  ${K8S_PATH}
  file:
    path: "${K8S_PATH}/{{ item }}"
    state: directory
    owner: k8s
    group: root
  with_items:
      - log
      - conf
- name: copy kube-apiserver
  copy: 
    src: bin 
    dest: ${K8S_PATH}/ 
    owner: k8s 
    group: root 
    mode: 0755
- name: copy config
  copy: 
    src: '{{ item }}'
    dest: ${K8S_PATH}/ 
    owner: k8s 
    group: root
  with_items:
      - config
      - ssl
- name: kube-apiservice conf
  template: 
    src: kube-apiserver 
    dest: ${K8S_PATH}/conf 
    owner: k8s 
    group: root
- name: copy kube-apiserver.service
  template: 
    src: kube-apiserver.service  
    dest: /lib/systemd/system/
- name: Change file ownership, group and permissions k8s
  file:
    path: ${K8S_PATH}/
    owner: k8s
    group: root
- name: Reload service daemon-reload
  shell: systemctl daemon-reload
- name: Enable service kube-apiserver, and not touch the state
  service:
    name: kube-apiserver
    enabled: yes
- name: Start service kube-apiserver, if not restarted
  service:
    name: kube-apiserver
    state: restarted
EOF
  cat >${HOST_PATH}/kube-apiserver.yml <<EOF
- hosts: all
  user: root
  roles:
    - kube-apiserver
EOF
  return 0
}
kubeHaProxy() {
  colorEcho ${GREEN} "create for kube-Ha-Proxy Config."
  # 创建 kube-apiserver playbook 目录
  if [[ ! -d "${HOST_PATH}/roles/kube-ha-proxy/" ]]; then
    mkdir -p ${HOST_PATH}/roles/kube-ha-proxy/{files,tasks}
  else
    colorEcho ${GREEN} '文件夹已经存在'
  fi
  if [ $IPVS = true ]; then
  cat >${HOST_PATH}/roles/kube-ha-proxy/files/kube-ha-proxy.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    component: kube-apiserver-ha-proxy
    tier: control-plane
  name: kube-apiserver-ha-proxy
  namespace: kube-system
spec:
  containers:
  - args:
    - care
    - --vs
    - ${MASTER_IP}:${K8S_VIP_PORT}
    - --health-path
    - /
    - --health-schem
    - https
    - --rs
    - ${MASTER_FRONTEND_IP1}:${SECURE_PORT}
    - --rs
    - ${MASTER_FRONTEND_IP2}:${SECURE_PORT}
    - --rs
    - ${MASTER_FRONTEND_IP3}:${SECURE_PORT}
    image: ${HA_PROXY_IMAGE}
    imagePullPolicy: IfNotPresent
    name: kube-apiserver-ha-proxy
    env:
    - name: vip
      value: "${MASTER_IP}"
    - name: K8S_VIP_PORT
      value: "${K8S_VIP_PORT}"
    resources: {}
    securityContext:
      privileged: true
    volumeMounts:
    - mountPath: /lib/modules
      name: lib-modules
      readOnly: true
  hostNetwork: true
  priorityClassName: system-cluster-critical
  volumes:
  - hostPath:
      path: /lib/modules
      type: ""
    name: lib-modules
status: {}
EOF
else
  cat >${HOST_PATH}/roles/kube-ha-proxy/files/kube-ha-proxy.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    component: kube-apiserver-ha-proxy
    tier: control-plane
  annotations:
    prometheus.io/port: "8404"
    prometheus.io/scrape: "true"    
  name: kube-apiserver-ha-proxy
  namespace: kube-system
spec:
  containers:
  - args:
    - "CP_HOSTS=${CP_HOSTS}"
    image: ${HA_PROXY_IMAGE}
    imagePullPolicy: IfNotPresent
    name: kube-apiserver-ha-proxy
    env:
    - name: CPU_NUM
      value: "${CPU_NUM}"
    - name: BACKEND_PORT
      value: "${SECURE_PORT}"
    - name: HOST_PORT
      value: "${K8S_VIP_PORT}"
    - name: CP_HOSTS
      value: "${CP_HOSTS}"
  hostNetwork: true
  priorityClassName: system-cluster-critical
status: {}
EOF
fi
  # 创建kube-proxy ansible
  cat >${HOST_PATH}/roles/kube-ha-proxy/tasks/main.yml <<EOF
- name: Create ${POD_MANIFEST_PATH}
  file:
    path: "${POD_MANIFEST_PATH}"
    state: directory
- name: copy kubelet to ${POD_MANIFEST_PATH}
  copy: 
    src: kube-ha-proxy.yaml 
    dest: ${POD_MANIFEST_PATH} 
    owner: root 
    group: root 
    mode: 644
- name: ${PULL_IMAGES} pull ${HA_PROXY_IMAGE}
  raw: ${PULL_IMAGES} pull ${HA_PROXY_IMAGE} && ${PULL_IMAGES} pull ${POD_INFRA_CONTAINER_IMAGE}
  ignore_errors: True
EOF
  cat >${HOST_PATH}/kube-ha-proxy.yml <<EOF
- hosts: all
  user: root
  roles:
    - kube-ha-proxy
EOF
  return 0
}
packageSysctl() {
  colorEcho ${GREEN} "create for Package-Sysctl Config."
  # 创建 kube-apiserver playbook 目录
  if [[ ! -d "${HOST_PATH}/roles/package-sysctl/" ]]; then
    mkdir -p ${HOST_PATH}/roles/package-sysctl/{templates,tasks}
  else
    colorEcho ${GREEN} '文件夹已经存在'
  fi
  cat >${HOST_PATH}/roles/package-sysctl/templates/k8s-debian-modules.conf <<EOF
br_netfilter
nf_conntrack
EOF
  cat >${HOST_PATH}/roles/package-sysctl/templates/k8s-redhat-modules.conf <<EOF
br_netfilter
nf_conntrack_ipv4
EOF
  cat >${HOST_PATH}/roles/package-sysctl/templates/k8s-ipvs-modules.conf <<EOF
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
EOF
  cat >${HOST_PATH}/roles/package-sysctl/tasks/main.yml <<EOF
- name: Get Kernel version
  shell: uname -r | egrep '^[0-9]*' -o
  register: kernel_shell_output
- name: copy modprobe modules
  template: 
    src: '{{ item }}'
    dest: /etc/modules-load.d/ 
    owner: root 
    group: root
  with_items:
      - k8s-redhat-modules.conf
      - k8s-ipvs-modules.conf
  when: 'kernel_shell_output.stdout|int <= 3'
- name: Add the ipvs-modules module
  modprobe: 
    name: '{{ item }}'
    state: present
  with_items:
      - ip_vs
      - ip_vs_rr
      - ip_vs_wrr
      - ip_vs_sh
      - nf_conntrack_ipv4
  when: 'kernel_shell_output.stdout|int <= 3'
- name: copy "{{ item }}"
  template: 
    src: '{{ item }}'
    dest: /etc/modules-load.d/ 
    owner: root 
    group: root
  with_items:
      - k8s-debian-modules.conf
      - k8s-ipvs-modules.conf
  when: 'kernel_shell_output.stdout|int >= 4'
- name: Add the ipvs-modules module
  modprobe: 
    name: '{{ item }}'
    state: present
  with_items:
      - ip_vs
      - ip_vs_rr
      - ip_vs_wrr
      - ip_vs_sh
      - nf_conntrack
  when: 'kernel_shell_output.stdout|int >= 4'
- name: Change various sysctl-settings, look at the sysctl-vars file for documentation
  sysctl:
    name: '{{ item.key }}'
    value: '{{ item.value }}' 
    sysctl_set: yes 
    state: present 
    reload: yes
    ignoreerrors: yes
  with_items:
      - { key: 'net.ipv4.tcp_slow_start_after_idle', value: '0' }
      - { key: 'net.core.rmem_max', value: '16777216' }
      - { key: 'fs.inotify.max_user_watches', value: '1048576' }
      - { key: 'kernel.softlockup_all_cpu_backtrace', value: '1' }
      - { key: 'kernel.softlockup_panic', value: '1' }
      - { key: 'fs.file-max', value: '2097152' } 
      - { key: 'fs.nr_open', value: '2097152' }
      - { key: 'kernel.pid_max', value: '4194303' } 
      - { key: 'fs.inotify.max_user_instances', value: '8192' }
      - { key: 'fs.inotify.max_queued_events', value: '16384' }
      - { key: 'vm.max_map_count', value: '262144' }
      - { key: 'net.core.netdev_max_backlog', value: '16384' }
      - { key: 'net.ipv4.tcp_wmem', value: '4096 12582912 16777216' }
      - { key: 'net.core.wmem_max', value: '16777216' }
      - { key: 'net.core.somaxconn', value: '32768' }
      - { key: 'net.ipv4.ip_forward', value: '1' }
      - { key: 'net.ipv4.tcp_timestamps', value: '0' }
      - { key: 'net.ipv4.tcp_tw_reuse', value: '1' }
      - { key: 'net.ipv4.tcp_fin_timeout', value: '1' }
      - { key: 'net.ipv4.tcp_max_syn_backlog', value: '8096' }
      - { key: 'net.bridge.bridge-nf-call-iptables', value: '1' }
      - { key: 'net.bridge.bridge-nf-call-ip6tables', value: '1' }
      - { key: 'net.bridge.bridge-nf-call-arptables',value: '1' }
      - { key: 'net.ipv4.tcp_rmem', value: '4096 12582912 16777216' }
      - { key: 'vm.swappiness', value: '0' }
      - { key: 'kernel.sysrq', value: '1' }
      - { key: 'vm.min_free_kbytes', value: '262144' }
      - { key: 'kernel.msgmnb', value: '65535' } 
      - { key: 'kernel.msgmax', value: '65535' }
      - { key: 'kernel.shmmax', value: '68719476736' }
      - { key: 'kernel.shmall', value: '4294967296' }
      - { key: 'kernel.core_uses_pid', value: '1' } 
      - { key: 'net.ipv4.neigh.default.gc_stale_time', value: '120' }
      - { key: 'net.ipv4.neigh.default.gc_thresh1', value: '0' }
      - { key: 'net.ipv4.neigh.default.gc_thresh2', value: '4096' }
      - { key: 'net.ipv4.neigh.default.gc_thresh3', value: '8192' }
      - { key: 'net.ipv4.conf.all.rp_filter', value: '0' }
      - { key: 'net.ipv4.conf.default.rp_filter', value: '0' }
      - { key: 'net.ipv4.conf.default.arp_announce', value: '2' }
      - { key: 'net.ipv4.conf.lo.arp_announce', value: '2' }
      - { key: 'net.ipv4.conf.all.arp_announce', value: '2' }
      - { key: 'net.ipv4.conf.default.arp_ignore', value: '1' }
      - { key: 'net.ipv4.conf.lo.arp_ignore', value: '1' }
      - { key: 'net.ipv4.conf.all.arp_ignore', value: '1' }
      - { key: 'net.ipv4.tcp_max_tw_buckets', value: '5000' }
      - { key: 'net.ipv4.tcp_syncookies', value: '1' }
      - { key: 'net.ipv4.tcp_synack_retries', value: '2' }
      - { key: 'net.ipv6.conf.lo.disable_ipv6', value: '1' }
      - { key: 'net.ipv6.conf.all.disable_ipv6', value: '1' }
      - { key: 'net.ipv6.conf.default.disable_ipv6', value: '1' }
      - { key: 'net.ipv4.ip_local_port_range', value: '1024 65535' }
      - { key: 'net.ipv4.tcp_keepalive_time', value: '600' }
      - { key: 'net.ipv4.tcp_keepalive_probes', value: '10' }
      - { key: 'net.ipv4.tcp_keepalive_intvl', value: '30' }
      - { key: 'net.ipv4.tcp_orphan_retries', value: '3' }
      - { key: 'net.nf_conntrack_max', value: '25000000' }
      - { key: 'net.netfilter.nf_conntrack_max', value: '25000000' }
      - { key: 'net.netfilter.nf_conntrack_tcp_timeout_established', value: '180' }
      - { key: 'net.netfilter.nf_conntrack_tcp_timeout_time_wait', value: '120' }
      - { key: 'net.netfilter.nf_conntrack_tcp_timeout_close_wait', value: '60' }
      - { key: 'net.netfilter.nf_conntrack_tcp_timeout_fin_wait', value: '12' }
      - { key: 'net.netfilter.nf_conntrack_tcp_timeout_close', value: '3' }
      - { key: 'net.ipv4.conf.all.route_localnet', value: '1' }
- name: Add the sysctl
  sysctl:
    name: '{{ item.key }}'
    value: '{{ item.value }}' 
    sysctl_set: yes 
    state: present 
    reload: yes
    ignoreerrors: yes
  with_items:
      - { key: 'fs.may_detach_mounts', value: '1' }
  when: 'kernel_shell_output.stdout|int <= 3'      
- name: Add or modify hard nofile limits for wildcard domain
  pam_limits:
    domain: '*'
    limit_type: '{{ item.key }}'
    limit_item: '{{ item.item }}'
    value: '{{ item.value }}'
  with_items:
      - { key: 'soft', item: 'nofile', value: '$HARD_SOFT'  }
      - { key: 'hard', item: 'nofile', value: '$HARD_SOFT'  }
      - { key: 'soft', item: 'nproc', value: '$HARD_SOFT'  }
      - { key: 'hard', item: 'nproc', value: '$HARD_SOFT'  }
      - { key: 'soft', item: 'core', value: 'unlimited'  }
      - { key: 'hard', item: 'core', value: 'unlimited'  }
- name: Add or modify  nofile limits for wildcard domain
  pam_limits:
    dest: '/etc/security/limits.d/20-nproc.conf'
    domain: '{{ item.domain }}'
    limit_type: '{{ item.key }}'
    limit_item: '{{ item.item }}'
    value: '{{ item.value }}'
  with_items:
      - { domain: '*', key: 'soft', item: 'nproc', value: '$HARD_SOFT'  }
      - { domain: 'root', key: 'soft', item: 'nproc', value: '$HARD_SOFT'  }
  when: ansible_distribution_major_version == '7' and ansible_os_family == 'RedHat'
- name: Disable SELinux
  selinux:
    state: disabled
  when: ansible_os_family == 'RedHat' or ansible_os_family == 'Rocky'
- name: Enable service firewalld , and not touch the state
  service:
    name: firewalld 
    enabled: no
  when: ansible_os_family == 'RedHat' or ansible_os_family == 'Rocky'
- name: Stop service firewalld , if started
  service:
    name: firewalld 
    state: stopped
  when: ansible_os_family == 'RedHat' or ansible_os_family == 'Rocky'
- name: Enable service firewalld , and not touch the state
  service:
    name: firewalld 
    enabled: no
  when: ansible_os_family == 'Suse'
- name: Stop service firewalld , if started
  service:
    name: firewalld 
    state: stopped
  when: ansible_os_family == 'Suse'  
- name: Enable service ufw , and not touch the state
  service:
    name: ufw 
    enabled: no
  when: ansible_facts.distribution == 'Ubuntu'
- name: Stop service ufw , if started
  service:
    name: ufw 
    state: stopped  
  when: ansible_facts.distribution == 'Ubuntu'
- name: create additional limits
  lineinfile: 
    dest: /etc/profile
    line: '{{ item.key }}'
  with_items:
      - { key: 'ulimit -u $HARD_SOFT' }
      - { key: 'ulimit -n $HARD_SOFT'  }
      - { key: 'ulimit -d unlimited' }
      - { key: 'ulimit -m unlimited' }
      - { key: 'ulimit -s unlimited' }
      - { key: 'ulimit -v unlimited' }
      - { key: 'ulimit -t unlimited' }
      - { key: 'ulimit -c unlimited' }
  when: ansible_facts.distribution == 'Ubuntu'
- name: remove swapfile
  lineinfile: 
    dest: /etc/fstab 
    regexp: "^/swapfile" 
    line: "#/swapfile" 
    state: absent
  when: ansible_facts.distribution == 'Ubuntu'    
- name: is set sources.list
  replace:
    path: /etc/apt/sources.list
    regexp: 'archive.ubuntu.com'
    replace: 'mirrors.aliyun.com'
  when: ansible_facts.distribution == 'Ubuntu'
- name: Only run "update_cache=yes"
  apt:
    update_cache: yes
  when: ansible_facts.distribution == 'Ubuntu'
- name: Only run "update *"
  apt:
    name: "*"
    state: latest
  register: ubuntu_upack_source
  when: ansible_facts.distribution == 'Ubuntu'
- name: remove RedHat swap
  lineinfile: 
    dest: /etc/fstab
    regexp: "^/dev/mapper/centos-swap"
    line: "#/dev/mapper/centos-swap" 
    state: absent
  when: ansible_os_family == 'RedHat' or ansible_os_family == 'Rocky'
- name: CentOS 7 repo
  get_url:
    url: https://mirrors.aliyun.com/repo/Centos-7.repo
    dest: /etc/yum.repos.d/CentOS-Base.repo
    force: yes
  when: ansible_distribution_major_version == '7' and  ansible_os_family == 'RedHat'
- name: CentOS 7 epel.repo
  get_url:
    url: http://mirrors.aliyun.com/repo/epel-7.repo
    dest: /etc/yum.repos.d/epel.repo
  when: ansible_distribution_major_version == '7' and  ansible_os_family == 'RedHat'
#- name: CentOS 8 repo
#  get_url:
#    url: https://mirrors.aliyun.com/repo/Centos-8.repo
#    dest: /etc/yum.repos.d/CentOS-Base.repo
#    force: yes
#  when: ansible_distribution_major_version == '8' and  ansible_distribution == 'CentOS'  
- name: enabled centos8 BaseOS
  lineinfile: 
    dest: '/etc/yum.repos.d/{{ item }}'
    regexp: "^enabled=0"
    line: "enabled=1" 
  with_items:
      - CentOS-Stream-AppStream.repo
      - CentOS-Stream-PowerTools.repo
      - CentOS-Stream-BaseOS.repo
      - CentOS-Stream-Extras.repo
  when: ansible_distribution_major_version == '8'  and  ansible_distribution == 'CentOS'
- name: remove centos8 BaseOS
  lineinfile: 
    dest: '/etc/yum.repos.d/{{ item }}'
    regexp: "^mirrorlist"
    line: "#mirrorlist" 
    state: absent
  with_items:
      - CentOS-Stream-AppStream.repo
      - CentOS-Stream-PowerTools.repo
      - CentOS-Stream-BaseOS.repo
      - CentOS-Stream-Extras.repo 
  when: ansible_distribution_major_version == '8' and  ansible_distribution == 'CentOS'
- name: is set centos8 BaseOS
  replace:
    path: '/etc/yum.repos.d/{{ item }}'
    regexp: '^#baseurl=http://mirror.centos.org/\\\$contentdir'
    replace: 'baseurl=https://mirrors.aliyun.com/centos'
  with_items:
      - CentOS-Stream-AppStream.repo
      - CentOS-Stream-PowerTools.repo
      - CentOS-Stream-BaseOS.repo
      - CentOS-Stream-Extras.repo
  when: ansible_distribution_major_version == '8' and  ansible_distribution == 'CentOS'
 
- name: enabled Rocky BaseOS
  lineinfile: 
    dest: '/etc/yum.repos.d/{{ item }}'
    regexp: "^enabled=0"
    line: "enabled=1" 
  with_items:
      - Rocky-AppStream.repo
      - Rocky-PowerTools.repo
      - Rocky-BaseOS.repo
      - Rocky-Extras.repo
  when: ansible_distribution_major_version == '8'  and  ansible_distribution == 'Rocky'
- name: remove Rocky BaseOS
  lineinfile: 
    dest: '/etc/yum.repos.d/{{ item }}'
    regexp: "^mirrorlist"
    line: "#mirrorlist" 
    state: absent
  with_items:
      - Rocky-AppStream.repo
      - Rocky-PowerTools.repo
      - Rocky-BaseOS.repo
      - Rocky-Extras.repo 
  when: ansible_distribution_major_version == '8' and  ansible_distribution == 'Rocky'
- name: is set Rocky BaseOS
  replace:
    path: '/etc/yum.repos.d/{{ item }}'
    regexp: '^#baseurl=http://dl.rockylinux.org/\\\$contentdir'
    replace: 'baseurl=https://mirrors.aliyun.com/rockylinux'
  with_items:
      - Rocky-AppStream.repo
      - Rocky-PowerTools.repo
      - Rocky-BaseOS.repo
      - Rocky-Extras.repo
  when: ansible_distribution_major_version == '8' and  ansible_distribution == 'Rocky'
  
- name: install the epel-release rpm from a remote repo
  yum:
    name: epel-release
    state: present
  when: ansible_distribution_major_version == '8' and  (ansible_os_family == 'RedHat' or  ansible_os_family == 'Rocky')  
- name: remove  epel-release
  lineinfile: 
    dest: '/etc/yum.repos.d/{{ item }}'
    regexp: "^metalink"
    line: "#metalink" 
    state: absent
  with_items:
      - epel-modular.repo
      - epel-testing-modular.repo
      - epel-testing.repo
      - epel.repo
  when: ansible_distribution_major_version == '8' and  (ansible_os_family == 'RedHat'  or  ansible_os_family == 'Rocky')
- name: is set  epel-release
  replace:
    path: '/etc/yum.repos.d/{{ item }}'
    regexp: '^#baseurl=https://download.example/pub'
    replace: 'baseurl=https://mirrors.aliyun.com'
  with_items:
      - epel-modular.repo
      - epel-testing-modular.repo
      - epel-testing.repo
      - epel.repo
  when: ansible_distribution_major_version == '8' and  (ansible_os_family == 'RedHat' or  ansible_os_family == 'Rocky')

- name: enabled Rocky9 BaseOS
  replace:
    path: '/etc/yum.repos.d/{{ item }}'
    regexp: '^enabled=0'
    replace: 'enabled=1'
  with_items:
      - rocky-devel.repo
      - rocky-addons.repo
      - rocky.repo
      - rocky-extras.repo
  when: ansible_distribution_major_version == '9'  and  ansible_distribution == 'Rocky'

- name: remove Rocky9 BaseOS
  lineinfile: 
    dest: '/etc/yum.repos.d/{{ item }}'
    regexp: "^mirrorlist"
    line: "#mirrorlist" 
    state: absent
  with_items:
      - rocky-devel.repo
      - rocky-addons.repo
      - rocky.repo
      - rocky-extras.repo
  when: ansible_distribution_major_version == '9' and  ansible_distribution == 'Rocky'

- name: is set Rocky 9 BaseOS
  replace:
    path: '/etc/yum.repos.d/{{ item }}'
    regexp: '^#baseurl=http://dl.rockylinux.org/\$contentdir'
    replace: 'baseurl=https://mirrors.aliyun.com/rockylinux'
  with_items:
      - rocky-devel.repo
      - rocky-addons.repo
      - rocky.repo
      - rocky-extras.repo
  when: ansible_distribution_major_version == '9' and  ansible_distribution == 'Rocky'

- name: install the epel-release9 rpm from a remote repo
  yum:
    name: epel-release
    state: present
  when: ansible_distribution_major_version == '9' and  (ansible_os_family == 'RedHat' or  ansible_os_family == 'Rocky') 

- name: remove  epel-release9
  lineinfile: 
    dest: '/etc/yum.repos.d/{{ item }}'
    regexp: "^metalink"
    line: "#metalink" 
    state: absent
  with_items:
      - epel-testing.repo
      - epel.repo
  when: ansible_distribution_major_version == '9' and  (ansible_os_family == 'RedHat'  or  ansible_os_family == 'Rocky')

- name: is set  epel-release9
  replace:
    path: '/etc/yum.repos.d/{{ item }}'
    regexp: '^#baseurl=https://download.example/pub'
    replace: 'baseurl=https://mirrors.aliyun.com'
  with_items:
      - epel-testing.repo
      - epel.repo
  when: ansible_distribution_major_version == '9' and  (ansible_os_family == 'RedHat' or  ansible_os_family == 'Rocky')
#- name: Remove /etc/yum.repos.d/CentOS-AppStream.repo
#  file:
#    path: "/etc/yum.repos.d/CentOS-AppStream.repo"
#    state: absent
#  ignore_errors: True
#  when: ansible_distribution_major_version == '8' and  ansible_os_family == 'RedHat'
- name: upgrade all packages
  yum:
    name: '*'
    state: latest
    lock_timeout: 36000
  register: redhat_upack_source
  when: ansible_os_family == 'RedHat' or  ansible_os_family == 'Rocky'
- name:  dnf Install
  dnf: 
    name:  
      - epel-release
    state: latest
  when: ansible_pkg_mgr == "dnf"
- name:  dnf Install
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
- name: dpkg  update db
  shell: dpkg --configure -a
  when: ansible_pkg_mgr == "apt"
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
- name: remove net.ipv4.ip_forward suse yast set forwarding
  sysctl:
    name: net.ipv4.ip_forward 
    state: absent
    sysctl_file: /etc/sysctl.d/70-yast.conf
  ignore_errors: True  
  when: ansible_os_family == 'Suse'    
- name: remove swapfile
  lineinfile: 
    dest: /etc/fstab 
    regexp: "swap" 
    line: "#UUID"
    state: absent
  when: ansible_os_family == 'Suse' 

- name: remvoe repository
  zypper_repository:
    name: openSUSE-Leap-{{ ansible_distribution_version }}-1
    state: absent
  ignore_errors: True
  when: ansible_pkg_mgr == "zypper" 
- name: add repository
  zypper_repository:
    name: '{{ item.value }}'
    repo: '{{ item.key }}'
    state: present
  with_items:    
      - { key: 'https://mirrors.ustc.edu.cn/opensuse/distribution/leap/{{ ansible_distribution_version }}/repo/oss/', value: 'USTC:{{ ansible_distribution_version }}:OSS' }
      - { key: 'https://mirrors.ustc.edu.cn/opensuse/distribution/leap/{{ ansible_distribution_version }}/repo/non-oss/', value: 'USTC:{{ ansible_distribution_version }}:NON-OSS' }
      - { key: 'https://mirrors.ustc.edu.cn/opensuse/update/leap/{{ ansible_distribution_version }}/oss/', value: 'USTC:{{ ansible_distribution_version }}:UPDATE-OSS' }
      - { key: 'https://mirrors.ustc.edu.cn/opensuse/update/leap/{{ ansible_distribution_version }}/non-oss/', value: 'USTC:{{ ansible_distribution_version }}:UPDATE-NON-OSS ' }
  ignore_errors: True
  when: ansible_pkg_mgr == "zypper"
- name: Refresh all repos 
  zypper_repository:
    repo: '*'
    runrefresh: yes
  ignore_errors: True
  when: ansible_pkg_mgr == "zypper"    
#- name: Only run
#  zypper:
#    name: '*'
#    state: dist-upgrade
#  ignore_errors: True  
#  when: ansible_pkg_mgr == "zypper" 
- name: Update all packages
  zypper:
    name: '*'
    state: latest
  register: suse_upack_source
  environment:
    ZYPP_LOCK_TIMEOUT: 3600
  when: ansible_pkg_mgr == "zypper"
- name: Suse zypper Install
  zypper: 
    name:
      - ipvsadm
      - telnet
      - wget
      - net-tools
      - conntrackd
      - ipset
      - jq
      - iptables
      - curl
      - sysstat
      - libseccomp2
      - socat
      - nfs-utils
      - fuse
      - lvm2
      - apparmor-parser 
      - apparmor-parser-lang 
      - catatonit  
      - less 
      - libbsd0 
      - liblvm2cmd2_03 
      - libnet9 
      - libpcre2-8-0 
      - libprotobuf-c1
      - libsha1detectcoll1  
      - perl-Error 
      - rsync 
      - vim
      - tree
      - iputils
      - net-tools-deprecated
      - device-mapper
      - fuse-devel
      - ceph-common
    state: latest
  when: ansible_pkg_mgr == "zypper"    
- name: Reboot a slow machine that might have lots of updates to apply
  reboot:
    reboot_timeout: 3600
  when: ubuntu_upack_source.changed or redhat_upack_source.changed or suse_upack_source.changed
EOF
  cat >${HOST_PATH}/package-sysctl.yml <<EOF
- hosts: all
  user: root
  roles:
    - package-sysctl
EOF
  return 0
}
runtimeConfig() {
  if [ ${RUNTIME} == "DOCKER" ]; then
    colorEcho ${GREEN} "create for docker Config."
    # 创建 docker playbook 目录
    if [[ ! -d "${HOST_PATH}/roles/docker/" ]]; then
      mkdir -p ${HOST_PATH}/roles/docker/{files,tasks,templates}
    else
      colorEcho ${GREEN} '文件夹已经存在'
    fi
    if [[ -e "$DOWNLOAD_PATH/docker-${DOCKER_VERSION}.tgz" ]] || [[ ! -e "${HOST_PATH}/roles/docker/files/bin/docker" ]]; then
      if [[ ! -e "$DOWNLOAD_PATH/docker-${DOCKER_VERSION}/docker/docker" ]] || [[ ! -e "${HOST_PATH}/roles/docker/files/bin/docker" ]]; then
        # cp 二进制 文件到 ansible 目录
        mkdir -p ${HOST_PATH}/roles/docker/files/bin
        mkdir -p ${DOWNLOAD_PATH}/docker-${DOCKER_VERSION}
        tar -xf ${DOWNLOAD_PATH}/docker-${DOCKER_VERSION}.tgz -C ${DOWNLOAD_PATH}/docker-${DOCKER_VERSION}
        tar -xf ${DOWNLOAD_PATH}/cri-dockerd-${CRI_DOCKER_VERSION}.amd64.tgz -C $DOWNLOAD_PATH
        \cp -pdr ${DOWNLOAD_PATH}/docker-${DOCKER_VERSION}/docker/* ${HOST_PATH}/roles/docker/files/bin/
        \cp -pdr $DOWNLOAD_PATH/cri-dockerd/cri-dockerd ${HOST_PATH}/roles/docker/files/bin/cri-dockerd
      fi
    else
      colorEcho ${RED} "docker no download."
      exit 1
    fi
    #docker 二进制安装playbook
    cat >${HOST_PATH}/roles/docker/tasks/main.yml <<EOF
- name: btrfs
  shell: 'mount |grep \\${TOTAL_PATH}| grep btrfs'
  ignore_errors: yes
  register: btrfs_result

- name: btrfs
  shell: 'mount |grep \/| grep btrfs'
  ignore_errors: yes
  register: btr_result
- name: create groupadd docker
  group: name=docker
- name: Create ${DOCKER_BIN_PATH}
  file:
    path: "${DOCKER_BIN_PATH}"
    state: directory
- name: Create /etc/docker
  file:
    path: "/etc/docker"
    state: directory
- name: Create /var/lib/docker
  file:
    path: "/var/lib/docker"
    state: directory
    owner: root
    group: root
- name: Create /run/docker
  file:
    path: "/run/docker"
    state: directory
    owner: root
    group: root
- name: Create $TOTAL_PATH/docker/data
  file:
    path: "$TOTAL_PATH/docker/data"
    state: directory
    owner: root
    group: root
- name: Create $TOTAL_PATH/docker/root
  file:
    path: "$TOTAL_PATH/docker/root"
    state: directory
    owner: root
    group: root    
- name: Create /etc/containerd
  file:
    path: "/etc/containerd"
    state: directory
- name: copy docker ${DOCKER_BIN_PATH}
  copy: 
    src: bin/ 
    dest: ${DOCKER_BIN_PATH}/ 
    owner: root 
    group: root 
    mode: 0755
- stat: 
    path: /usr/bin/docker
  register: docker_path_register
- name: PATH 
  raw: echo "export PATH=${DOCKER_BIN_PATH}:\\\$PATH" >> /etc/profile
  when: docker_path_register.stat.exists == False
- name: daemon.json conf
  template: 
    src: daemon.json 
    dest: /etc/docker 
    owner: root 
    group: root
- name: config.toml
  shell: ${DOCKER_BIN_PATH}/containerd config default >/etc/containerd/config.toml
#- name: Create a symbolic link
#  file:
#    src: "${DOCKER_BIN_PATH}/{{ item }}"
#    dest: '/usr/bin/{{ item }}'
#    owner: root
#    group: root
#    state: link
#    force: yes
#  with_items:
#      - containerd-shim
#      - runc
#  when: docker_path_register.stat.exists == False
#  ignore_errors: True 
- name: Mount docker data a volume
  mount:
    path: /var/lib/docker
    src:  "${DATA_ROOT}"
    opts: defaults,bind,nofail
    state: mounted
    fstype: none  
# - name: Mount docker exec a volume
#   mount:
#     path: /run/docker
#     src:  "${EXEC_ROOT}"
#     opts: defaults,bind,nofail
#     state: mounted
#     fstype: none 
#- name: mount docker data 
#  lineinfile: 
#    dest: /etc/fstab
#    line: '${DATA_ROOT} /var/lib/docker none defaults,bind,nofail 0 0'
#- name: mount docker exec 
#  lineinfile: 
#    dest: /etc/fstab
#    line: '${EXEC_ROOT} /run/docker none defaults,bind,nofail 0 0'
#- name: mount docker
#  shell: mount -a
#  ignore_errors: yes     
- name: copy "{{ item }}"
  template: 
    src: '{{ item }}'
    dest: /lib/systemd/system/
    owner: root 
    group: root
  with_items:
      - containerd.service
      - docker.socket
      - docker.service
      - cri-docker.service
      - cri-docker.socket
- name: Reload service daemon-reload
  shell: systemctl daemon-reload
- name: Enable service docker, and not touch the state
  service:
    name: docker
    enabled: yes
- name: Start service docker, if not restarted
  service:
    name: docker
    state: restarted
- name: Enable service cri-docker, and not touch the state
  service:
    name: cri-docker
    enabled: yes
- name: Start service cri-docker, if not restarted
  service:
    name: cri-docker
    state: restarted 
EOF
    # docker 配置文件生成
    cat >${HOST_PATH}/roles/docker/templates/daemon.json <<EOF
{
    "max-concurrent-downloads": ${MAX_CONCURRENT_DOWNLOADS},
    "data-root": "/var/lib/docker",
    "exec-root": "/var/run/docker",
    "log-driver": "${LOG_DRIVER}",
    "bridge": "${NET_BRIDGE}",
    "live-restore": true,
    "exec-opts": ["native.cgroupdriver=${NATIVE_CGROUPDRIVER}"],
    {% if  btrfs_result.rc == 0 or btr_result.rc == 0 %}
     "storage-driver": "btrfs",
     {% else %} 
    "storage-driver": "overlay2",
    "storage-opts":["overlay2.override_kernel_check=true"],
    {% endif %}
    "debug": false,
    "log-opts": {
        "max-size": "${LOG_OPTS_MAX_SIZE}",
        "max-file": "${LOG_OPTS_MAX_FILE}"
    },
    "default-ulimits": {
        "nofile": {
            "Name": "nofile",
            "Hard": ${POD_HARD_SOFT},
            "Soft": ${POD_HARD_SOFT}
        },
        "nproc": {
            "Name": "nproc",
            "Hard": ${POD_HARD_SOFT},
            "Soft": ${POD_HARD_SOFT}
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
    if [ "${DOCKER_BIN_PATH}" == "/usr/bin" ]; then
      ENVIRONMENT_PATH=""
    else
      ENVIRONMENT_PATH="Environment=PATH=${DOCKER_BIN_PATH}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin:/root/bin"
    fi
    cat >${HOST_PATH}/roles/docker/templates/containerd.service <<EOF
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
${ENVIRONMENT_PATH}
ExecStartPre=-/sbin/modprobe overlay
ExecStart=${DOCKER_BIN_PATH}/containerd
KillMode=process
Delegate=yes
LimitNOFILE=${HARD_SOFT}
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity

[Install]
WantedBy=multi-user.target
EOF
    # 生成docker.socket 文件
    cat >${HOST_PATH}/roles/docker/templates/docker.socket <<EOF
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
    # 生成 cri docker socket 文件
    cat >${HOST_PATH}/roles/docker/templates/cri-docker.socket <<EOF
[Unit]
Description=CRI Docker Socket for the API
PartOf=cri-docker.service

[Socket]
ListenStream=${RUN_DOCKER_SOCK}/cri-dockerd.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker

[Install]
WantedBy=sockets.target
EOF
    # 生成cri-docker.service 启动文件
    cat >${HOST_PATH}/roles/docker/templates/cri-docker.service <<EOF
[Unit]
Description=CRI Interface for Docker Application Container Engine
Documentation=https://docs.mirantis.com
After=network-online.target firewalld.service docker.service
Wants=network-online.target
Requires=cri-docker.socket

[Service]
Type=notify
${ENVIRONMENT_PATH}
ExecStart=${DOCKER_BIN_PATH}/cri-dockerd --container-runtime-endpoint=${CONTAINER_RUNTIME_ENDPOINT} --network-plugin=cni --cni-bin-dir=${CNI_BIN_DIR} \\
          --cni-conf-dir=${CNI_CONF_DIR} --image-pull-progress-deadline=${IMAGE_PULL_PROGRESS_DEADLINE} --pod-infra-container-image=${POD_INFRA_CONTAINER_IMAGE} \\
          --docker-endpoint=unix:///var/run/docker.sock --cri-dockerd-root-directory=/var/lib/docker
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
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not support it.
# Only systemd 226 and above support this option.
TasksMax=infinity
Delegate=yes
KillMode=process

[Install]
WantedBy=multi-user.target
EOF
    # 生成docker 启动文件
    cat >${HOST_PATH}/roles/docker/templates/docker.service <<EOF
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
LimitNOFILE=${HARD_SOFT}
LimitNPROC=${HARD_SOFT}
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
    cat >${HOST_PATH}/docker.yml <<EOF
- hosts: all
  user: root
  roles:
    - docker
EOF
    return 0
  elif [ ${RUNTIME} == "CONTAINERD" ]; then
    colorEcho ${GREEN} "create for containerd Config."
    # 创建 containerd playbook 目录
    if [[ ! -d "${HOST_PATH}/roles/containerd/" ]]; then
      mkdir -p ${HOST_PATH}/roles/containerd/{files,tasks,templates}
    else
      colorEcho ${GREEN} '文件夹已经存在'
    fi
    if [[ -e "$DOWNLOAD_PATH/containerd-${CONTAINERD_VERSION}.linux-amd64.tar.gz" ]]; then
      if [[ ! -e "$DOWNLOAD_PATH/containerd-${CONTAINERD_VERSION}.linux-amd64/bin/containerd" ]] || [[ ! -e "${HOST_PATH}/roles/containerd/files/bin/containerd" ]]; then
        # cp 二进制 文件到 ansible 目录
        mkdir -p $DOWNLOAD_PATH/containerd-${CONTAINERD_VERSION}.linux-amd64
        tar -xf $DOWNLOAD_PATH/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz -C $DOWNLOAD_PATH
        tar -xf $DOWNLOAD_PATH/containerd-${CONTAINERD_VERSION}.linux-amd64.tar.gz -C $DOWNLOAD_PATH/containerd-${CONTAINERD_VERSION}.linux-amd64
        \cp -pdr $DOWNLOAD_PATH/containerd-${CONTAINERD_VERSION}.linux-amd64/bin ${HOST_PATH}/roles/containerd/files/
        \cp -pdr $DOWNLOAD_PATH/runc-${RUNC_VERSION} ${HOST_PATH}/roles/containerd/files/bin/runc
        \cp -pdr $DOWNLOAD_PATH/crictl ${HOST_PATH}/roles/containerd/files/crictl
      fi
    else
      colorEcho ${RED} "containerd no download."
      exit 1
    fi

    if [[ ${NATIVE_CGROUPDRIVER} == "cgroupfs" ]]; then
      CONTAINER_CGROUP="false"
    elif [[ ${NATIVE_CGROUPDRIVER} == "systemd" ]]; then
      CONTAINER_CGROUP="true"
    fi
    # 生成containerd 配置文件
    cat >${HOST_PATH}/roles/containerd/templates/config.toml <<EOF
version = 2

[plugins]

  [plugins."io.containerd.gc.v1.scheduler"]
    deletion_threshold = 0
    mutation_threshold = 100
    pause_threshold = 0.02
    schedule_delay = "0s"
    startup_delay = "100ms"

  [plugins."io.containerd.grpc.v1.cri"]
    image_pull_progress_timeout = "5m0s"
    max_concurrent_downloads = ${MAX_CONCURRENT_DOWNLOADS}
    max_container_log_line_size = 16384
    netns_mounts_under_state_dir = false
    restrict_oom_score_adj = false
    sandbox_image = "${SANDBOX_IMAGE}"
    selinux_category_range = 1024
    stats_collect_period = 10
    stream_idle_timeout = "4h0m0s"
    stream_server_address = "127.0.0.1"
    stream_server_port = "0"
    systemd_cgroup = false
    tolerate_missing_hugetlb_controller = true
    unset_seccomp_profile = ""

    [plugins."io.containerd.grpc.v1.cri".cni]
      bin_dir = "${CNI_BIN_DIR}"
      conf_dir = "${CNI_CONF_DIR}"
      conf_template = ""
      ip_pref = ""
      max_conf_num = 1
      setup_serially = false

    [plugins."io.containerd.grpc.v1.cri".containerd]
      default_runtime_name = "runc"
      disable_snapshot_annotations = true
      discard_unpacked_layers = false
      ignore_blockio_not_enabled_errors = false
      ignore_rdt_not_enabled_errors = false
      no_pivot = false
  {% if  btrfs_result.rc == 0 or btr_result.rc == 0 %}
      snapshotter = "btrfs"
  {% else %}
      snapshotter = "${SNAPSHOTTER}"
  {% endif %}

      [plugins."io.containerd.grpc.v1.cri".containerd.default_runtime]
        base_runtime_spec = ""
        cni_conf_dir = ""
        cni_max_conf_num = 0
        container_annotations = []
        pod_annotations = []
        privileged_without_host_devices = false
        privileged_without_host_devices_all_devices_allowed = false
        runtime_engine = ""
        runtime_path = ""
        runtime_root = ""
        runtime_type = ""
        sandbox_mode = ""
        snapshotter = ""

        [plugins."io.containerd.grpc.v1.cri".containerd.default_runtime.options]

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]

        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          base_runtime_spec = ""
          cni_conf_dir = ""
          cni_max_conf_num = 0
          container_annotations = []
          pod_annotations = []
          privileged_without_host_devices = false
          privileged_without_host_devices_all_devices_allowed = false
          runtime_engine = ""
          runtime_path = ""
          runtime_root = ""
          runtime_type = "io.containerd.runc.v2"
          sandbox_mode = "podsandbox"
          snapshotter = ""

          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            BinaryName = ""
            CriuImagePath = ""
            CriuPath = ""
            CriuWorkPath = ""
            IoGid = 0
            IoUid = 0
            NoNewKeyring = false
            NoPivotRoot = false
            Root = ""
            ShimCgroup = ""
            SystemdCgroup = ${CONTAINER_CGROUP}

      [plugins."io.containerd.grpc.v1.cri".containerd.untrusted_workload_runtime]
        base_runtime_spec = ""
        cni_conf_dir = ""
        cni_max_conf_num = 0
        container_annotations = []
        pod_annotations = []
        privileged_without_host_devices = false
        privileged_without_host_devices_all_devices_allowed = false
        runtime_engine = ""
        runtime_path = ""
        runtime_root = ""
        runtime_type = ""
        sandbox_mode = ""
        snapshotter = ""

        [plugins."io.containerd.grpc.v1.cri".containerd.untrusted_workload_runtime.options]
        
    [plugins."io.containerd.grpc.v1.cri".image_decryption]
      key_model = "node"

    [plugins."io.containerd.grpc.v1.cri".registry]
      config_path = ""

      [plugins."io.containerd.grpc.v1.cri".registry.auths]

      [plugins."io.containerd.grpc.v1.cri".registry.configs]

      [plugins."io.containerd.grpc.v1.cri".registry.headers]

      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]

    [plugins."io.containerd.grpc.v1.cri".x509_key_pair_streaming]
      tls_cert_file = ""
      tls_key_file = ""

  [plugins."io.containerd.internal.v1.opt"]
    path = "${CONTAINERD_PATH}"

  [plugins."io.containerd.internal.v1.restart"]
    interval = "10s"

  [plugins."io.containerd.internal.v1.tracing"]
    sampling_ratio = 1.0
    service_name = "containerd"

  [plugins."io.containerd.runtime.v1.linux"]
    no_shim = false
    runtime = "runc"
    runtime_root = ""
    shim = "containerd-shim"
    shim_debug = false

  [plugins."io.containerd.runtime.v2.task"]
    platforms = ["linux/amd64"]
    sched_core = false

  [plugins."io.containerd.transfer.v1.local"]
    config_path = ""
    max_concurrent_downloads = ${MAX_CONCURRENT_DOWNLOADS}
    max_concurrent_uploaded_layers = 3

    [[plugins."io.containerd.transfer.v1.local".unpack_config]]
      differ = ""
      platform = "linux/amd64"
  {% if  btrfs_result.rc == 0 or btr_result.rc == 0 %}
      snapshotter = "btrfs"
  {% else %}
     snapshotter = "${SNAPSHOTTER}"
  {% endif %}
EOF
    # containerd 启动文件创建
    cat >${HOST_PATH}/roles/containerd/templates/containerd.service <<EOF
[Unit]
Description=Lightweight Kubernetes
Documentation=https://containerd.io
After=network-online.target

[Service]
Type=notify
Environment=PATH=${CONTAINERD_PATH}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin:/root/bin
ExecStartPre=-/sbin/modprobe br_netfilter
ExecStartPre=-/sbin/modprobe overlay
ExecStartPre=-/bin/mkdir -p ${RUN_CONTAINERD_SOCK}
ExecStart=${CONTAINERD_BIN_PATH} \\
         -c ${CONTAINERD_PATH}/conf/config.toml \\
         -a ${RUN_CONTAINERD_SOCK}/containerd.sock \\
         --state /run/containerd \\
         --root /var/lib/containerd 

KillMode=process
Delegate=yes
OOMScoreAdjust=-999
LimitNOFILE=${POD_HARD_SOFT} 
LimitNPROC=${POD_HARD_SOFT}
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
    # crictl 配置
    cat >${HOST_PATH}/roles/containerd/files/crictl.yaml <<EOF
  runtime-endpoint: unix://${RUN_CONTAINERD_SOCK}/containerd.sock
  image-endpoint: unix://${RUN_CONTAINERD_SOCK}/containerd.sock
  timeout: 10
  debug: false
  pull-image-on-create: true
  disable-pull-on-run: false
EOF
    cat >${HOST_PATH}/roles/containerd/tasks/main.yml <<EOF
- name: btrfs
  shell: 'mount |grep \\${TOTAL_PATH}| grep btrfs'
  ignore_errors: yes
  register: btrfs_result

- name: btrfs
  shell: 'mount |grep \/| grep btrfs'
  ignore_errors: yes
  register: btr_result  
- name: Create containerd
  file:
    path: "${CONTAINERD_PATH}/{{ item }}"
    state: directory
  with_items:
      - conf
      - run
      - containerd      
- name: copy containerd
  copy: 
    src: bin 
    dest: "${CONTAINERD_PATH}" 
    owner: root 
    group: root 
    mode: 0755
- name: copy crictl
  copy: 
    src: crictl 
    dest: "/usr/bin/" 
    owner: root 
    group: root 
    mode: 0755
- name:  containerd etc
  template: 
    src: '{{ item }}'
    dest: "${CONTAINERD_PATH}/conf"
    owner: root 
    group: root
  with_items:
      - config.toml
- name:  containers etc
  copy: 
    src: '{{ item }}'
    dest: /etc
    owner: root 
    group: root
  with_items:
      - crictl.yaml
- name: Create /var/lib/containerd
  file:
    path: "/var/lib/containerd"
    state: directory
    owner: root
    group: root
- name: Create /run/containerd
  file:
    path: "/run/containerd"
    state: directory
    owner: root
    group: root
- name: Create ${CONTAINERD_PATH}/containerd
  file:
    path: "${CONTAINERD_PATH}/containerd"
    state: directory
    owner: root
    group: root
- name: Create ${CONTAINERD_PATH}/run/containerd
  file:
    path: "${CONTAINERD_PATH}/run/containerd"
    state: directory
    owner: root
    group: root
- name: Mount containerd data volume
  mount:
    path: /var/lib/containerd
    src:  "${CONTAINERD_PATH}/containerd"
    opts: defaults,bind,nofail
    state: mounted
    fstype: none 
# - name: Mount containerd exec volume
#   mount:
#     path: /run/containerd
#     src:  "${CONTAINERD_PATH}/run/containerd"
#     opts: defaults,bind,nofail
#     state: mounted
#     fstype: none     
#- name: mount containerd data 
#  lineinfile:
#    dest: /etc/fstab
#    line: '${CONTAINERD_PATH}/containerd /var/lib/containerd none defaults,bind,nofail 0 0'
#- name: mount containerd exec 
#  lineinfile:
#    dest: /etc/fstab
#    line: '${CONTAINERD_PATH}/run/containerd /run/containerd none defaults,bind,nofail 0 0'     
#- name: mount containerd
#  shell: mount -a
#  ignore_errors: yes
- name:  copy to containerd service
  template: 
    src: '{{ item }}' 
    dest: /lib/systemd/system/
  with_items:
      - containerd.service
- name: Reload service daemon-reload
  shell: systemctl daemon-reload
- name: Enable service containerd, and not touch the state
  service:
    name: containerd
    enabled: yes
- name: Start service containerd, if not restarted
  service:
    name: containerd
    state: restarted 
EOF
    cat >${HOST_PATH}/containerd.yml <<EOF
- hosts: all
  user: root
  roles:
    - containerd
EOF
    return 0
  elif [ ${RUNTIME} == "CRIO" ]; then
    colorEcho ${GREEN} "create for crio Config."
    # 创建 containerd playbook 目录
    if [[ ! -d "${HOST_PATH}/roles/crio/" ]]; then
      mkdir -p ${HOST_PATH}/roles/crio/{files,tasks,templates}
    else
      colorEcho ${GREEN} '文件夹已经存在'
    fi
    if [[ -e "$DOWNLOAD_PATH/crio-${CRIO_VERSION}.tar.gz" ]]; then
      if [[ ! -e "$DOWNLOAD_PATH/crio-${CRIO_VERSION}/bin/crio" ]] || [[ ! -e "${HOST_PATH}/roles/crio/files/bin/crio" ]]; then
        mkdir -p ${DOWNLOAD_PATH}/crio-${CRIO_VERSION}
        # cp 二进制 文件到 ansible 目录
        tar -xf $DOWNLOAD_PATH/crio-${CRIO_VERSION}.tar.gz -C ${DOWNLOAD_PATH}/crio-${CRIO_VERSION}
        \cp -pdr $DOWNLOAD_PATH/crio-${CRIO_VERSION}/cri-o/bin ${HOST_PATH}/roles/crio/files/
        mv -f ${HOST_PATH}/roles/crio/files/bin/crictl ${HOST_PATH}/roles/crio/files
        \cp -pdr $DOWNLOAD_PATH/crio-${CRIO_VERSION}/cri-o/etc/crio-umount.conf ${HOST_PATH}/roles/crio/templates/crio-umount.conf
      fi
    else
      colorEcho ${RED} "crio no download."
      exit 1
    fi
    # 生成 crio 配置文件
    cat >${HOST_PATH}/roles/crio/templates/crio.conf <<EOF
# The CRI-O configuration file specifies all of the available configuration
# options and command-line flags for the crio(8) OCI Kubernetes Container Runtime
# daemon, but in a TOML format that can be more easily modified and versioned.
#
# Please refer to crio.conf(5) for details of all configuration options.

# CRI-O supports partial configuration reload during runtime, which can be
# done by sending SIGHUP to the running process. Currently supported options
# are explicitly mentioned with: 'This option supports live configuration
# reload'.

# CRI-O reads its storage defaults from the containers-storage.conf(5) file
# located at /etc/containers/storage.conf. Modify this storage configuration if
# you want to change the system's defaults. If you want to modify storage just
# for CRI-O, you can change the storage configuration options here.
[crio]

# Path to the "root directory". CRI-O stores all of its data, including
# containers images, in this directory.
root = "/var/lib/containers/storage"

# Path to the "run directory". CRI-O stores all of its state in this directory.
runroot = "/var/run/containers/storage"

# Storage driver used to manage the storage of images and containers. Please
# refer to containers-storage.conf(5) to see all available storage drivers.
#storage_driver = ""
{% if  btrfs_result.rc == 0 or btr_result.rc == 0 %}
driver = "btrfs"
{% endif %}
# List to pass options to the storage driver. Please refer to
# containers-storage.conf(5) to see all available storage options.
#storage_option = [
#]

# The default log directory where all logs will go unless directly specified by
# the kubelet. The log directory specified must be an absolute directory.
log_dir = "/var/log/crio/pods"

# Location for CRI-O to lay down the temporary version file.
# It is used to check if crio wipe should wipe containers, which should
# always happen on a node reboot
version_file = "/var/run/crio/version"

# Location for CRI-O to lay down the persistent version file.
# It is used to check if crio wipe should wipe images, which should
# only happen when CRI-O has been upgraded
version_file_persist = "/var/lib/crio/version"

# The crio.api table contains settings for the kubelet/gRPC interface.
[crio.api]

# Path to AF_LOCAL socket on which CRI-O will listen.
listen = "${RUN_CRIO_SOCK}/crio.sock"

# IP address on which the stream server will listen.
stream_address = "127.0.0.1"

# The port on which the stream server will listen. If the port is set to "0", then
# CRI-O will allocate a random free port number.
stream_port = "0"

# Enable encrypted TLS transport of the stream server.
stream_enable_tls = false

# Path to the x509 certificate file used to serve the encrypted stream. This
# file can change, and CRI-O will automatically pick up the changes within 5
# minutes.
stream_tls_cert = ""

# Path to the key file used to serve the encrypted stream. This file can
# change and CRI-O will automatically pick up the changes within 5 minutes.
stream_tls_key = ""

# Path to the x509 CA(s) file used to verify and authenticate client
# communication with the encrypted stream. This file can change and CRI-O will
# automatically pick up the changes within 5 minutes.
stream_tls_ca = ""

# Maximum grpc send message size in bytes. If not set or <=0, then CRI-O will default to 16 * 1024 * 1024.
grpc_max_send_msg_size = 16777216

# Maximum grpc receive message size. If not set or <= 0, then CRI-O will default to 16 * 1024 * 1024.
grpc_max_recv_msg_size = 16777216

# The crio.runtime table contains settings pertaining to the OCI runtime used
# and options for how to set up and manage the OCI runtime.
[crio.runtime]

# A list of ulimits to be set in containers by default, specified as
# "<ulimit name>=<soft limit>:<hard limit>", for example:
# "nofile=1024:2048"
# If nothing is set here, settings will be inherited from the CRI-O daemon
#default_ulimits = [
#]
default_ulimits = [
  "nofile=${POD_HARD_SOFT}:${POD_HARD_SOFT}",
  "nproc=${POD_HARD_SOFT}:${POD_HARD_SOFT}",
  "core=-1:-1"
]

# default_runtime is the _name_ of the OCI runtime to be used as the default.
# The name is matched against the runtimes map below.
default_runtime = "runc"

# If true, the runtime will not use pivot_root, but instead use MS_MOVE.
no_pivot = false

# decryption_keys_path is the path where the keys required for
# image decryption are stored. This option supports live configuration reload.
decryption_keys_path = "${DECRYPTION_KEYS_PATH}"

# Path to the conmon binary, used for monitoring the OCI runtime.
# Will be searched for using \$PATH if empty.
conmon = ""

# Cgroup setting for conmon
conmon_cgroup = "system.slice"

# Environment variable list for the conmon process, used for passing necessary
# environment variables to conmon or the runtime.
conmon_env = [
	"PATH=${CONMON_ENV}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
]

# Additional environment variables to set for all the
# containers. These are overridden if set in the
# container image spec or in the container runtime configuration.
default_env = [
]

# If true, SELinux will be used for pod separation on the host.
selinux = false

# Path to the seccomp.json profile which is used as the default seccomp profile
# for the runtime. If not specified, then the internal default seccomp profile
# will be used. This option supports live configuration reload.
seccomp_profile = ""

# Used to change the name of the default AppArmor profile of CRI-O. The default
# profile name is "crio-default". This profile only takes effect if the user
# does not specify a profile via the Kubernetes Pod's metadata annotation. If
# the profile is set to "unconfined", then this equals to disabling AppArmor.
# This option supports live configuration reload.
apparmor_profile = "crio-default"

# Cgroup management implementation used for the runtime.
cgroup_manager = "${NATIVE_CGROUPDRIVER}"

# List of default capabilities for containers. If it is empty or commented out,
# only the capabilities defined in the containers json file by the user/kube
# will be added.
default_capabilities = [
    "CHOWN",
    "MKNOD",
    "DAC_OVERRIDE",
    "NET_ADMIN",
    "NET_RAW",
    "SYS_CHROOT",
    "FSETID",
    "FOWNER",
    "SETGID",
    "SETUID",
    "SETPCAP",
    "NET_BIND_SERVICE",
    "KILL",
]

# List of default sysctls. If it is empty or commented out, only the sysctls
# defined in the container json file by the user/kube will be added.
default_sysctls = [
]

# List of additional devices. specified as
# "<device-on-host>:<device-on-container>:<permissions>", for example: "--device=/dev/sdc:/dev/xvdc:rwm".
#If it is empty or commented out, only the devices
# defined in the container json file by the user/kube will be added.
additional_devices = [
]

# Path to OCI hooks directories for automatically executed hooks. If one of the
# directories does not exist, then CRI-O will automatically skip them.
hooks_dir = [
	"${HOOKS_DIR}",
]

# List of default mounts for each container. **Deprecated:** this option will
# be removed in future versions in favor of default_mounts_file.
default_mounts = [
]

# Path to the file specifying the defaults mounts for each container. The
# format of the config is /SRC:/DST, one mount per line. Notice that CRI-O reads
# its default mounts from the following two files:
#
#   1) /etc/containers/mounts.conf (i.e., default_mounts_file): This is the
#      override file, where users can either add in their own default mounts, or
#      override the default mounts shipped with the package.
#
#   2) /usr/share/containers/mounts.conf: This is the default file read for
#      mounts. If you want CRI-O to read from a different, specific mounts file,
#      you can change the default_mounts_file. Note, if this is done, CRI-O will
#      only add mounts it finds in this file.
#
#default_mounts_file = ""

# Maximum number of processes allowed in a container.
pids_limit = ${PIDS_LIMIT}

# Maximum sized allowed for the container log file. Negative numbers indicate
# that no size limit is imposed. If it is positive, it must be >= 8192 to
# match/exceed conmon's read buffer. The file is truncated and re-opened so the
# limit is never exceeded.
log_size_max = -1

# Whether container output should be logged to journald in addition to the kuberentes log file
log_to_journald = false

# Path to directory in which container exit files are written to by conmon.
container_exits_dir = "${CONTAINER_EXITS_DIR}"

# Path to directory for container attach sockets.
container_attach_socket_dir = "/var/run/crio"

# The prefix to use for the source of the bind mounts.
bind_mount_prefix = ""

# If set to true, all containers will run in read-only mode.
read_only = false

# Changes the verbosity of the logs based on the level it is set to. Options
# are fatal, panic, error, warn, info, debug and trace. This option supports
# live configuration reload.
log_level = "info"

# Filter the log messages by the provided regular expression.
# This option supports live configuration reload.
log_filter = ""

# The UID mappings for the user namespace of each container. A range is
# specified in the form containerUID:HostUID:Size. Multiple ranges must be
# separated by comma.
uid_mappings = ""

# The GID mappings for the user namespace of each container. A range is
# specified in the form containerGID:HostGID:Size. Multiple ranges must be
# separated by comma.
gid_mappings = ""

# The minimal amount of time in seconds to wait before issuing a timeout
# regarding the proper termination of the container. The lowest possible
# value is 30s, whereas lower values are not considered by CRI-O.
ctr_stop_timeout = 30

# **DEPRECATED** this option is being replaced by manage_ns_lifecycle, which is described below.
# manage_network_ns_lifecycle = false

# manage_ns_lifecycle determines whether we pin and remove namespaces
# and manage their lifecycle
manage_ns_lifecycle = true

# The directory where the state of the managed namespaces gets tracked.
# Only used when manage_ns_lifecycle is true.
namespaces_dir = "${NAMESPACES_DIR}"

# pinns_path is the path to find the pinns binary, which is needed to manage namespace lifecycle
pinns_path = "${PINNS_PATH}"

# The "crio.runtime.runtimes" table defines a list of OCI compatible runtimes.
# The runtime to use is picked based on the runtime_handler provided by the CRI.
# If no runtime_handler is provided, the runtime will be picked based on the level
# of trust of the workload. Each entry in the table should follow the format:
#
#[crio.runtime.runtimes.runtime-handler]
#  runtime_path = "/path/to/the/executable"
#  runtime_type = "oci"
#  runtime_root = "/path/to/the/root"
#
# Where:
# - runtime-handler: name used to identify the runtime
# - runtime_path (optional, string): absolute path to the runtime executable in
#   the host filesystem. If omitted, the runtime-handler identifier should match
#   the runtime executable name, and the runtime executable should be placed
#   in \$PATH.
# - runtime_type (optional, string): type of runtime, one of: "oci", "vm". If
#   omitted, an "oci" runtime is assumed.
# - runtime_root (optional, string): root directory for storage of containers
#   state.

[crio.runtime.runtimes.runc]
runtime_path = ""
runtime_type = "oci"
runtime_root = ""

[crio.runtime.runtimes.crun]
runtime_path = ""
runtime_type = "oci"
runtime_root = ""

# allowed_annotations is a slice of experimental annotations that this 
#  workload is allowed to process. The currently recognized values are: 
#  "io.kubernetes.cri-o.userns-mode" for configuring a user namespace for 
#  the pod. "io.kubernetes.cri-o.Devices" for configuring devices for the pod.

allowed_annotations = [
    "io.containers.trace-syscall",
]


# Kata Containers is an OCI runtime, where containers are run inside lightweight
# VMs. Kata provides additional isolation towards the host, minimizing the host attack
# surface and mitigating the consequences of containers breakout.

# Kata Containers with the default configured VMM
#[crio.runtime.runtimes.kata-runtime]

# Kata Containers with the QEMU VMM
#[crio.runtime.runtimes.kata-qemu]

# Kata Containers with the Firecracker VMM
#[crio.runtime.runtimes.kata-fc]

# The crio.image table contains settings pertaining to the management of OCI images.
#
# CRI-O reads its configured registries defaults from the system wide
# containers-registries.conf(5) located in /etc/containers/registries.conf. If
# you want to modify just CRI-O, you can change the registries configuration in
# this file. Otherwise, leave insecure_registries and registries commented out to
# use the system's defaults from /etc/containers/registries.conf.
[crio.image]

# Default transport for pulling images from a remote container storage.
default_transport = "docker://"

# The path to a file containing credentials necessary for pulling images from
# secure registries. The file is similar to that of /var/lib/kubelet/config.json
global_auth_file = ""

# The image used to instantiate infra containers.
# This option supports live configuration reload.
pause_image = "${PAUSE_IMAGE}"

# The path to a file containing credentials specific for pulling the pause_image from
# above. The file is similar to that of /var/lib/kubelet/config.json
# This option supports live configuration reload.
pause_image_auth_file = ""

# The command to run to have a container stay in the paused state.
# When explicitly set to "", it will fallback to the entrypoint and command
# specified in the pause image. When commented out, it will fallback to the
# default: "/pause". This option supports live configuration reload.
pause_command = "/pause"

# Path to the file which decides what sort of policy we use when deciding
# whether or not to trust an image that we've pulled. It is not recommended that
# this option be used, as the default behavior of using the system-wide default
# policy (i.e., /etc/containers/policy.json) is most often preferred. Please
# refer to containers-policy.json(5) for more details.
signature_policy = ""

# List of registries to skip TLS verification for pulling images. Please
# consider configuring the registries via /etc/containers/registries.conf before
# changing them here.
#insecure_registries = "[]"

# Controls how image volumes are handled. The valid values are mkdir, bind and
# ignore; the latter will ignore volumes entirely.
image_volumes = "mkdir"

# List of registries to be used when pulling an unqualified image (e.g.,
# "alpine:latest"). By default, registries is set to "docker.io" for
# compatibility reasons. Depending on your workload and usecase you may add more
# registries (e.g., "quay.io", "registry.fedoraproject.org",
# "registry.opensuse.org", etc.).
#registries = [
# ]


# The crio.network table containers settings pertaining to the management of
# CNI plugins.
[crio.network]

# The default CNI network name to be selected. If not set or "", then
# CRI-O will pick-up the first one found in network_dir.
# cni_default_network = ""

# Path to the directory where CNI configuration files are located.
network_dir = "${CNI_CONF_DIR}"

# Paths to directories where CNI plugin binaries are located.
plugin_dirs = [
	"${CNI_BIN_DIR}",
]

# A necessary configuration for Prometheus based metrics retrieval
[crio.metrics]

# Globally enable or disable metrics support.
# enable_metrics = false

# Specify enabled metrics collectors.
# Per default all metrics are enabled.
# It is possible, to prefix the metrics with "container_runtime_" and "crio_".
# For example, the metrics collector "operations" would be treated in the same
# way as "crio_operations" and "container_runtime_crio_operations".
# metrics_collectors = [
# 	"operations",
# 	"operations_latency_microseconds_total",
# 	"operations_latency_microseconds",
# 	"operations_errors",
# 	"image_pulls_by_digest",
# 	"image_pulls_by_name",
# 	"image_pulls_by_name_skipped",
# 	"image_pulls_failures",
# 	"image_pulls_successes",
# 	"image_pulls_layer_size",
# 	"image_layer_reuse",
# 	"containers_oom_total",
# 	"containers_oom",
# 	"processes_defunct",
# 	"operations_total",
# 	"operations_latency_seconds",
# 	"operations_latency_seconds_total",
# 	"operations_errors_total",
# 	"image_pulls_bytes_total",
# 	"image_pulls_skipped_bytes_total",
# 	"image_pulls_failure_total",
# 	"image_pulls_success_total",
# 	"image_layer_reuse_total",
# 	"containers_oom_count_total",
# ]
# The port on which the metrics server will listen.
# metrics_port = 9090
   
# Local socket path to bind the metrics server to
# metrics_socket = ""

# The certificate for the secure metrics server.
# If the certificate is not available on disk, then CRI-O will generate a
# self-signed one. CRI-O also watches for changes of this path and reloads the
# certificate on any modification event.
# metrics_cert = ""

# The certificate key for the secure metrics server.
# Behaves in the same way as the metrics_cert.
# metrics_key = ""

# A necessary configuration for OpenTelemetry trace data exporting
[crio.tracing]

# Globally enable or disable exporting OpenTelemetry traces.
# enable_tracing = false

# Address on which the gRPC trace collector listens on.
# tracing_endpoint = "0.0.0.0:4317"

# Number of samples to collect per million spans.
# tracing_sampling_rate_per_million = 0

# Necessary information pertaining to container and pod stats reporting.
[crio.stats]

# The number of seconds between collecting pod and container stats.
# If set to 0, the stats are collected on-demand instead.
# stats_collection_period = 0
EOF
    if [[ ${NATIVE_CGROUPDRIVER} == "cgroupfs" ]]; then
      CONTAINER_CGROUP="Environment=CONTAINER_CONMON_CGROUP=pod"
    elif [[ ${NATIVE_CGROUPDRIVER} == "systemd" ]]; then
      CONTAINER_CGROUP=""
    fi
    # 生成 crio 启动配置文件
    cat >${HOST_PATH}/roles/crio/templates/crio.service <<EOF
[Unit]
Description=OCI-based implementation of Kubernetes Container Runtime Interface
Documentation=https://github.com/github.com/cri-o/cri-o

[Service]
Type=notify
${CONTAINER_CGROUP}
Environment=PATH=${CONMON_ENV}:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
WorkingDirectory=${WORKINGDIRECTORY}
ExecStartPre=-/sbin/modprobe br_netfilter
ExecStartPre=-/sbin/modprobe overlay
ExecStart=${CRIO_PATH}/bin/crio --config ${CRIO_PATH}/etc/crio.conf --log-level info 
Restart=on-failure
RestartSec=5
LimitNOFILE=${HARD_SOFT}
LimitNPROC=${HARD_SOFT}
LimitCORE=infinity
LimitMEMLOCK=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
[Install]
WantedBy=multi-user.target

EOF
    # 生成 crio policy.json
    cat >${HOST_PATH}/roles/crio/files/policy.json <<EOF
{
    "default": [
        {
            "type": "insecureAcceptAnything"
        }
    ],
    "transports":
        {
            "docker-daemon":
                {
                    "": [{"type":"insecureAcceptAnything"}]
                }
        }
}
EOF
    # 生成 crio registries.conf
    cat >${HOST_PATH}/roles/crio/files/registries.conf <<EOF
# This is a system-wide configuration file used to
# keep track of registries for various container backends.
# It adheres to TOML format and does not support recursive
# lists of registries.

# The default location for this configuration file is /etc/containers/registries.conf.

# The only valid categories are: 'registries.search', 'registries.insecure',
# and 'registries.block'.

[registries.search]
registries = ['docker.io']

# If you need to access insecure registries, add the registry's fully-qualified name.
# An insecure registry is one that does not have a valid SSL certificate or only does HTTP.
[registries.insecure]
registries = []

# If you need to block pull access from a registry, uncomment the section below
# and add the registries fully-qualified name.
#
# Docker only
[registries.block]
registries = []
EOF
    # 生成 crictl crictl.yaml
    cat >${HOST_PATH}/roles/crio/files/crictl.yaml <<EOF
runtime-endpoint: "unix://${RUN_CRIO_SOCK}/crio.sock"
image-endpoint: "unix://${RUN_CRIO_SOCK}/crio.sock"
timeout: 10
debug: false
pull-image-on-create: true
disable-pull-on-run: false
EOF
    # 生成 cri-o ansible 部署文件
    cat >${HOST_PATH}/roles/crio/tasks/main.yml <<EOF
- name: btrfs
  shell: 'mount |grep \\${TOTAL_PATH}| grep btrfs'
  ignore_errors: yes
  register: btrfs_result

- name: btrfs
  shell: 'mount |grep \/| grep btrfs'
  ignore_errors: yes
  register: btr_result
- name: Create ${CRIO_PATH}
  file:
    path: "${CRIO_PATH}/{{ item }}"
    state: directory
  with_items:
      - run
      - etc
      - keys      
- name: copy crio
  copy: 
    src: bin 
    dest: "${CRIO_PATH}/" 
    owner: root 
    group: root 
    mode: 0755
- name: copy crictl
  copy: 
    src: crictl 
    dest: "/usr/bin/" 
    owner: root 
    group: root 
    mode: 0755
- name: Create hooks.d
  file:
    path: "${HOOKS_DIR}"
    state: directory
- name:  cri-o etc
  template: 
    src: '{{ item }}'
    dest: "${CRIO_PATH}/etc"
    owner: root 
    group: root
  with_items:
      - crio.conf
      - crio-umount.conf
- name: Create /etc/containers
  file:
    path: "/etc/containers"
    state: directory
- name:  containers
  copy: 
    src: '{{ item }}'
    dest: /etc/containers/
    owner: root 
    group: root
  with_items:
      - policy.json
      - registries.conf
- name:  containers etc
  copy: 
    src: '{{ item }}'
    dest: /etc
    owner: root 
    group: root
  with_items:
      - crictl.yaml
- name: Create /var/lib/containers/storage
  file:
    path: "/var/lib/containers/storage"
    state: directory
    owner: root
    group: root
- name: Create /run/containers/storage
  file:
    path: "/run/containers/storage"
    state: directory
    owner: root
    group: root
- name: Create ${CRIO_ROOT}
  file:
    path: "${CRIO_ROOT}"
    state: directory
    owner: root
    group: root
- name: Create ${RUNROOT}
  file:
    path: "${RUNROOT}"
    state: directory
    owner: root
    group: root  
- name: Mount CRIO data  volume
  mount:
    path: /var/lib/containers/storage
    src:  "${CRIO_ROOT}"
    opts: defaults,bind,nofail
    state: mounted
    fstype: none 
# - name: Mount CRIO exec volume
#   mount:
#     path: /run/containers/storage
#     src:  "${RUNROOT}"
#     opts: defaults,bind,nofail
#     state: mounted
#     fstype: none     
#- name: mount CRIO data 
#  lineinfile: 
#    dest: /etc/fstab
#    line: '${CRIO_ROOT} /var/lib/containers/storage none defaults,bind,nofail 0 0'
#- name: mount CRIO exec 
#  lineinfile: 
#    dest: /etc/fstab
#    line: '${RUNROOT} /run/containers/storage none defaults,bind,nofail 0 0' 
#    
#- name: mount CRIO
#  shell: mount -a
#  ignore_errors: yes       
- name:  copy to crio service
  template: 
    src: '{{ item }}' 
    dest: /lib/systemd/system/
  with_items:
      - crio.service
- name: Reload service daemon-reload
  shell: systemctl daemon-reload
- name: Enable service crio, and not touch the state
  service:
    name: crio
    enabled: yes
- name: Start service crio, if not restarted
  service:
    name: crio
    state: restarted      
EOF
    cat >${HOST_PATH}/crio.yml <<EOF
- hosts: all
  user: root
  roles:
    - crio
EOF
    return 0
  fi
  return 0
}
kubeletConfig() {
  colorEcho ${GREEN} "create for kubelet Config."
  # 创建 kube-apiserver playbook 目录
  if [[ ! -d "${HOST_PATH}/roles/kubelet/" ]]; then
    mkdir -p ${HOST_PATH}/roles/kubelet/{files,tasks,templates}
  else
    colorEcho ${GREEN} '文件夹已经存在'
  fi
  if [[ -e "${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}.tar.gz" ]]; then
    if [[ -e "${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/kubernetes/server/bin/kubelet" ]]; then
      # cp 二进制文件及ssl及kubeconfig 文件到 ansible 目录
      mkdir -p ${HOST_PATH}/roles/kubelet/files/{bin,ssl}
      mkdir -p ${HOST_PATH}/roles/kubelet/files/ssl/k8s
      \cp -pdr ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/kubernetes/server/bin/kubelet ${HOST_PATH}/roles/kubelet/files/bin/
      # 复制ssl
      \cp -pdr ${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem ${HOST_PATH}/roles/kubelet/files/ssl/k8s/
      # 复制bootstrap.kubeconfig 文件
      \cp -pdr ${HOST_PATH}/kubeconfig/bootstrap.kubeconfig ${HOST_PATH}/roles/kubelet/templates/
    elif [[ ! -e "${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/kubernetes/server/bin/kubelet" ]] || [[ ! -e "${HOST_PATH}/roles/kubelet/files/bin/kubelet" ]]; then
      # cp 二进制文件及ssl 文件到 ansible 目录
      mkdir -p ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}
      tar -xf ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}.tar.gz -C ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/
      # cp 二进制文件及ssl及kubeconfig 文件到 ansible 目录
      mkdir -p ${HOST_PATH}/roles/kubelet/files/{bin,ssl}
      mkdir -p ${HOST_PATH}/roles/kubelet/files/ssl/k8s
      \cp -pdr ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/kubernetes/server/bin/kubelet ${HOST_PATH}/roles/kubelet/files/bin/
      # 复制ssl
      \cp -pdr ${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem ${HOST_PATH}/roles/kubelet/files/ssl/k8s/
      # 复制bootstrap.kubeconfig 文件
      \cp -pdr ${HOST_PATH}/kubeconfig/bootstrap.kubeconfig ${HOST_PATH}/roles/kubelet/templates/
    fi
  else
    colorEcho ${RED} "kubernetes no download."
    exit 1
  fi
  # 生成 kubelet config 配置文件
  if [[ ${NATIVE_CGROUPDRIVER} == "cgroupfs" ]]; then
    CONTAINER_CGROUP="cgroupfs"
    KUBE_RESERVED=$(echo -e "- pods\n- kube-reserved\n- system-reserved")
  elif [[ ${NATIVE_CGROUPDRIVER} == "systemd" ]]; then
    CONTAINER_CGROUP="systemd"
    KUBE_RESERVED="- pods"
  fi
  K8S_TLS_CIPHER=$(echo $TLS_CIPHER | sed -e "s/\,/\\n-\ /g")
  KUBE_TLS_CIPHER=$(echo -e "- $K8S_TLS_CIPHER")
  cat >${HOST_PATH}/roles/kubelet/templates/kubelet.yaml <<EOF
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
staticPodPath: "${POD_MANIFEST_PATH}"
syncFrequency: ${SYNC_FREQUENCY}
fileCheckFrequency: 20s
httpCheckFrequency: 20s
address: {{ ${KUBELET_IPV4} }}
port: 10250
readOnlyPort: 0
tlsCipherSuites: 
${KUBE_TLS_CIPHER}
rotateCertificates: true
authentication:
  x509:
    clientCAFile: "${K8S_PATH}/ssl/k8s/k8s-ca.pem"
  webhook:
    enabled: true
    cacheTTL: 2m0s
  anonymous:
    enabled: false
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 5m0s
    cacheUnauthorizedTTL: 30s
registryPullQPS: 5
registryBurst: 10
eventRecordQPS: ${EVENT_QPS}
eventBurst: ${EVENT_BURST}
enableDebuggingHandlers: true
healthzPort: 10248
healthzBindAddress: {{ ${KUBELET_IPV4} }}
oomScoreAdj: -999
clusterDomain: ${CLUSTER_DNS_DOMAIN}
clusterDNS:
- ${CLUSTER_DNS_SVC_IP}
streamingConnectionIdleTimeout: 4h0m0s
nodeStatusUpdateFrequency: ${NODE_STATUS_UPDATE_FREQUENCY}
nodeStatusReportFrequency: 5m0s
nodeLeaseDurationSeconds: 40
imageMinimumGCAge: 2m0s
imageGCHighThresholdPercent: ${IMAGE_GC_HIGH_THRESHOLD}
imageGCLowThresholdPercent: ${IMAGE_GC_LOW_THRESHOLD}
volumeStatsAggPeriod: 1m0s
kubeletCgroups: "/systemd/system.slice"
cgroupsPerQOS: true
cgroupDriver: ${CONTAINER_CGROUP}
cpuManagerPolicy: none
cpuManagerReconcilePeriod: 10s
topologyManagerPolicy: none
runtimeRequestTimeout: 2m0s
hairpinMode: ${HAIRPIN_MODE}
maxPods: ${MAX_PODS}
podsPerCore: 0
podPidsLimit: -1
{% if  resolv_register.stat.exists == True %}
resolvConf: "/run/systemd/resolve/resolv.conf"   
{% else %}
resolvConf: "/etc/resolv.conf"
{% endif %}
cpuCFSQuota: true
cpuCFSQuotaPeriod: 100ms
maxOpenFiles: 1000000
contentType: application/vnd.kubernetes.protobuf
kubeAPIQPS: ${KUBELET_API_QPS}
kubeAPIBurst: ${KUBELET_API_BURST}
serializeImagePulls: ${SERIALIZE_IMAGE_PULLS}
evictionHard:
  imagefs.available: ${EVICTIONHARD_IMAGEFS}
  memory.available: ${EVICTIONHARD_MEMORY}
  nodefs.available: ${EVICTIONHARD_NODEFS}
evictionSoft:
  imagefs.available: 15%
  memory.available: ${EVICTIONHARD_MEMORY}
  nodefs.available: 15%
evictionSoftGracePeriod:
  imagefs.available: 2m
  memory.available: 2m
  nodefs.available: 2m
evictionPressureTransitionPeriod: ${EVICTION_PRESSURE_TRANSITION_PERIOD}
evictionMinimumReclaim:
  imagefs.available: ${EVICTIONHARD_MEMORY}
  memory.available: 0Mi
  nodefs.available: ${EVICTIONHARD_MEMORY}
enableControllerAttachDetach: true
makeIPTablesUtilChains: true
iptablesMasqueradeBit: 14
iptablesDropBit: 15
failSwapOn: false
containerLogMaxSize: 100Mi
containerLogMaxFiles: 10
configMapAndSecretChangeDetectionStrategy: Watch
systemReserved:
  cpu: ${SYSTEMRESERVED_CPU}
  ephemeral-storage: ${SYSTEMRESERVED_STORAGE}
  memory: ${SYSTEMRESERVED_MEMORY}
kubeReserved:
  cpu: ${KUBERESERVED_CPU}
  ephemeral-storage: ${KUBERESERVED_STORAGE}
  memory: ${KUBERESERVED_MEMORY}
systemReservedCgroup: "/systemd/system.slice"
kubeReservedCgroup: "/systemd/system.slice"
enforceNodeAllocatable:
${KUBE_RESERVED}
allowedUnsafeSysctls:
- kernel.msg*
- kernel.shm*
- kernel.sem
- fs.mqueue.*
- net.*
EOF
  # 生成 kubelet  配置文件
  cat >${HOST_PATH}/roles/kubelet/templates/kubelet <<EOF
KUBELET_OPTS="--bootstrap-kubeconfig=${K8S_PATH}/conf/bootstrap.kubeconfig \\
              --kubeconfig=${K8S_PATH}/conf/kubelet.kubeconfig \\
              --node-ip={{ ${KUBELET_IPV4} }} \\
              --hostname-override={{ ansible_hostname }} \\
              --cert-dir=${K8S_PATH}/ssl \\
              --runtime-cgroups=/systemd/system.slice \\
              --root-dir=/var/lib/kubelet \\
              --config=${K8S_PATH}/conf/kubelet.yaml \\
              --container-runtime-endpoint=${CONTAINER_RUNTIME_ENDPOINT} \\
              --containerd=${CONTAINERD_ENDPOINT} \\
              --pod-infra-container-image=${POD_INFRA_CONTAINER_IMAGE} \\
              --v=${LEVEL_LOG}"
EOF
  # 生成 kubelet  配置文件
  cat >${HOST_PATH}/roles/kubelet/templates/kubelet.service <<EOF
[Unit]
Description=Kubernetes Kubelet
Wants=network-online.target
After=network-online.target

[Service]
${EXEC_START_PRE}
LimitNOFILE=${HARD_SOFT}
LimitNPROC=${HARD_SOFT}
LimitCORE=infinity
LimitMEMLOCK=infinity
EnvironmentFile=-${K8S_PATH}/conf/kubelet
ExecStart=${K8S_PATH}/bin/kubelet \$KUBELET_OPTS
KillMode=process
Restart=always
StartLimitInterval=0
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF
  # kubelet 二进制安装playbook
  cat >${HOST_PATH}/roles/kubelet/tasks/main.yml <<EOF
#disable swap
- name: disable swap
  shell: "([ $(swapon -s | wc -l) -ge 1 ] && (swapoff -a && echo disable)) || echo already"
  ignore_errors: yes
  register: swapoff_result
  changed_when: "swapoff_result.stdout.strip() == 'disable'"
- stat: 
    path: /run/systemd/resolve/resolv.conf
  register: resolv_register
- name: Create  ${K8S_PATH}
  file:
    path: "${K8S_PATH}/{{ item }}"
    state: directory
  with_items:
      - log
      - conf
- name: Create ${POD_MANIFEST_PATH}
  file:
    path: "{{ item }}"
    state: directory
  with_items:
      - ${POD_RUNING_PATH}
      - ${POD_MANIFEST_PATH}
- name: Create /usr/libexec/kubernetes/kubelet-plugins/volume/exec/
  file:
    path: "/usr/libexec/kubernetes/kubelet-plugins/volume/exec/"
    state: directory
    owner: root
    group: root      
- name: Create /var/lib/kubelet
  file:
    path: "/var/lib/kubelet"
    state: directory
    owner: root
    group: root  
- name: Mount kubelet a volume
  mount:
    path: /var/lib/kubelet
    src:  "${POD_RUNING_PATH}"
    opts: defaults,bind,nofail
    state: mounted
    fstype: none    
#- name: mount kubelet 
#  lineinfile: 
#    dest: /etc/fstab
#    line: '${POD_RUNING_PATH} /var/lib/kubelet none defaults,bind,nofail 0 0'  
#- name: mount kubelet 
#  shell: mount -a
#  ignore_errors: yes   
- name: copy kubelet to ${K8S_PATH}
  copy: 
    src: bin 
    dest: ${K8S_PATH}/ 
    owner: root
    group: root 
    mode: 0755
- name: copy kubelet ssl
  copy: 
    src: ssl 
    dest: ${K8S_PATH}/
- name: copy to kubelet config
  template: 
    src: '{{ item }}'
    dest: ${K8S_PATH}/conf
  with_items:
      - kubelet
      - bootstrap.kubeconfig
      - kubelet.yaml
- name:  copy to kubelet service
  template: 
    src: '{{ item }}'
    dest: /lib/systemd/system/
  with_items:
      - kubelet.service
- name: Reload service daemon-reload
  shell: systemctl daemon-reload
- name: Enable service kubelet, and not touch the state
  service:
    name: kubelet
    enabled: yes
- name: Start service kubelet, if not restarted
  service:
    name: kubelet
    state: restarted
EOF
  cat >${HOST_PATH}/kubelet.yml <<EOF
- hosts: all
  user: root
  roles:
    - kubelet
EOF
  return 0
}
bootstrapConfig() {
  colorEcho ${GREEN} "create for k8s KubeConfig."
  if [[ ! -d "${HOST_PATH}/kubeconfig" ]]; then
    mkdir -p ${HOST_PATH}/kubeconfig
  else
    colorEcho ${GREEN} '文件夹已经存在'
  fi
  if [[ ! -n $(command -v kubectl) ]]; then
    colorEcho ${GREEN} "download kubectl FATAL kubectl "
    exit $?
  fi
  colorEcho ${GREEN} "create for k8s KubeConfig."
  if [[ ! -d "${HOST_PATH}/yaml" ]]; then
    mkdir -p ${HOST_PATH}/yaml
  else
    colorEcho ${GREEN} '文件夹已经存在'
  fi
  if [[ ! -e "${HOST_PATH}/kubeconfig/bootstrap.kubeconfig" ]]; then
    # 创建bootstrap配置
    TOKEN_ID=$(head -c 30 /dev/urandom | od -An -t x | tr -dc a-f3-9 | cut -c 3-8)
    TOKEN_SECRET=$(head -c 16 /dev/urandom | md5sum | head -c 16)
    BOOTSTRAP_TOKEN=${TOKEN_ID}.${TOKEN_SECRET}
    # 创建bootstrap  kubeconfig 配置
    # 设置集群参数
    kubectl config set-cluster ${CLUSTER_NAME} \
      --certificate-authority=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
      --embed-certs=true \
      --server=${KUBE_API_KUBELET} \
      --kubeconfig=${HOST_PATH}/kubeconfig/bootstrap.kubeconfig
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL bootstrap.kubeconfig."
      exit $?
    fi
    # 设置客户端认证参数
    kubectl config set-credentials system:bootstrap:${TOKEN_ID} \
      --token=${BOOTSTRAP_TOKEN} \
      --kubeconfig=${HOST_PATH}/kubeconfig/bootstrap.kubeconfig
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL bootstrap.kubeconfig."
      exit $?
    fi
    # 设置上下文参数
    kubectl config set-context default \
      --cluster=${CLUSTER_NAME} \
      --user=system:bootstrap:${TOKEN_ID} \
      --kubeconfig=${HOST_PATH}/kubeconfig/bootstrap.kubeconfig
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL bootstrap.kubeconfig."
      exit $?
    fi
    # 设置默认上下文
    kubectl config use-context default --kubeconfig=${HOST_PATH}/kubeconfig/bootstrap.kubeconfig
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "cfssl  FATAL bootstrap.kubeconfig."
      exit $?
    fi
    # 创建bootstrap secret yaml
    cat >${HOST_PATH}/yaml/bootstrap-secret.yaml <<EOF
---
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
EOF

    # 创建kubelet-bootstrap 授权
    cat >${HOST_PATH}/yaml/kubelet-bootstrap-rbac.yaml <<EOF
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
    # 生成集群授权yaml
    cat >${HOST_PATH}/yaml/kube-api-rbac.yaml <<EOF
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
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "kubelet bootstrap  FATAL."
      exit $?
    fi
  fi
  return 0
}
cniConfig() {
  colorEcho ${GREEN} "create for cni Config."
  # 创建 containerd playbook 目录
  if [[ ! -d "${HOST_PATH}/roles/cni/" ]]; then
    mkdir -p ${HOST_PATH}/roles/cni/{files,tasks}
  else
    colorEcho ${GREEN} '文件夹已经存在'
  fi
  if [[ -e "${DOWNLOAD_PATH}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz" ]]; then
    if [[ -e "${DOWNLOAD_PATH}/cni-plugins-linux-amd64-${CNI_VERSION}/bin/portmap" ]]; then
      # cp 二进制文件到 ansible 目录
      mkdir -p ${DOWNLOAD_PATH}/cni-plugins-linux-amd64-${CNI_VERSION}/bin
      tar -xf ${DOWNLOAD_PATH}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz -C ${DOWNLOAD_PATH}/cni-plugins-linux-amd64-${CNI_VERSION}/bin
      \cp -pdr ${DOWNLOAD_PATH}/cni-plugins-linux-amd64-${CNI_VERSION}/bin ${HOST_PATH}/roles/cni/files
    elif [[ ! -e "${DOWNLOAD_PATH}/cni-plugins-linux-amd64-${CNI_VERSION}/bin/portmap" ]] || [[ ! -e "${HOST_PATH}/roles/cni/files/bin/portmap" ]]; then
      mkdir -p ${DOWNLOAD_PATH}/cni-plugins-linux-amd64-${CNI_VERSION}/bin
      tar -xf ${DOWNLOAD_PATH}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz -C ${DOWNLOAD_PATH}/cni-plugins-linux-amd64-${CNI_VERSION}/bin
      \cp -pdr ${DOWNLOAD_PATH}/cni-plugins-linux-amd64-${CNI_VERSION}/bin ${HOST_PATH}/roles/cni/files
    fi
  else
    colorEcho ${RED} "cni no download."
    exit 1
  fi
  #cni 二进制安装playbook
  cat >${HOST_PATH}/roles/cni/tasks/main.yml <<EOF
- name: Create cni
  file:
    path: "${CNI_BIN_DIR}"
    state: directory
- name: Create cni etc
  file:
    path: "${CNI_CONF_DIR}"
    state: directory    
- name: copy to cni
  copy: 
    src: bin/
    dest: ${CNI_BIN_DIR}/ 
    owner: root 
    group: root 
    mode: 0755
EOF
  cat >${HOST_PATH}/cni.yml <<EOF
- hosts: all
  user: root
  roles:
    - cni
EOF
  return 0
}

iptablesConfig() {

  if [ ${IPTABLES_INSTALL} == "ON" ]; then
    colorEcho ${GREEN} "create for iptables Config."
    # 创建 iptables playbook 目录
    if [[ ! -d "${HOST_PATH}/roles/iptables/" ]]; then
      mkdir -p ${HOST_PATH}/roles/iptables/{files,tasks}
    else
      colorEcho ${GREEN} '文件夹已经存在'
    fi
    if [[ -e "${DOWNLOAD_PATH}/iptables-${IPTABLES_VERSION}.tar.bz2" ]]; then
      if [[ ! -e "${HOST_PATH}/roles/iptables/files/iptables-${IPTABLES_VERSION}.tar.bz2" ]]; then
        # 复制 iptables 源码到 playbook
        \cp -pdr ${DOWNLOAD_PATH}/iptables-${IPTABLES_VERSION}.tar.bz2 ${HOST_PATH}/roles/iptables/files/iptables-${IPTABLES_VERSION}.tar.bz2
      fi
    else
      colorEcho ${RED} "iptables no download."
      exit 1
    fi
    # iptables playbook 配置
    cat >${HOST_PATH}/roles/iptables/tasks/main.yml <<EOF
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
- name: Extract iptables-${IPTABLES_VERSION}.tar.bz2 into ${SOURCE_PATH}
  unarchive:
    src: iptables-${IPTABLES_VERSION}.tar.bz2
    dest: ${SOURCE_PATH}
  register: iptables_source_unpack
  when: ansible_os_family != 'Suse'
- name: configure to iptables
  shell: ./configure --disable-nftables
  args:
    chdir: "${SOURCE_PATH}/iptables-${IPTABLES_VERSION}"
  when: iptables_source_unpack.changed and ansible_os_family != 'Suse'
  register: iptables_configure
- name: make install
  become: yes
  shell:  make -j$(nproc) &&  make install
  args:
    chdir: "${SOURCE_PATH}/iptables-${IPTABLES_VERSION}"
  when: iptables_configure.changed and ansible_os_family != 'Suse' 
EOF
    cat >${HOST_PATH}/iptables.yml <<EOF
- hosts: all
  user: root
  roles:
    - iptables
EOF
  else
    colorEcho ${BLUE} '不升级iptables'
  fi
  return 0
}
controllerConfig() {
  colorEcho ${GREEN} "create for kube-controller-manager Config."
  # 创建 kube-controller-manager playbook 目录
  if [[ ! -d "${HOST_PATH}/roles/kube-controller-manager/" ]]; then
    mkdir -p ${HOST_PATH}/roles/kube-controller-manager/{files,tasks,templates}
  else
    colorEcho ${GREEN} '文件夹已经存在'
  fi
  if [[ -e "${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}.tar.gz" ]]; then
    if [[ -e "${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/kubernetes/server/bin/kube-controller-manager" ]]; then
      # cp 二进制文件及ssl及kubeconfig 文件到 ansible 目录
      mkdir -p ${HOST_PATH}/roles/kube-controller-manager/files/{ssl,bin}
      mkdir -p ${HOST_PATH}/roles/kube-controller-manager/files/ssl/k8s
      \cp -pdr ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/kubernetes/server/bin/kube-controller-manager ${HOST_PATH}/roles/kube-controller-manager/files/bin/
      # 复制kube-controller-manager.kubeconfig 文件
      \cp -pdr ${HOST_PATH}/kubeconfig/kube-controller-manager.kubeconfig ${HOST_PATH}/roles/kube-controller-manager/templates/
      # 复制ssl
      \cp -pdr ${HOST_PATH}/cfssl/pki/k8s/{k8s-controller-manager*.pem,k8s-ca*.pem} ${HOST_PATH}/roles/kube-controller-manager/files/ssl/k8s
    elif [[ ! -e "${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/kubernetes/server/bin/kube-controller-manager" ]] || [[ ! -e "${HOST_PATH}/roles/kube-controller-manager/files/bin/kube-controller-manager" ]]; then
      # cp 二进制文件及ssl 文件到 ansible 目录
      mkdir -p ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}
      tar -xf ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}.tar.gz -C ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/
      # cp 二进制文件及ssl及kubeconfig 文件到 ansible 目录
      mkdir -p ${HOST_PATH}/roles/kube-controller-manager/files/{ssl,bin}
      mkdir -p ${HOST_PATH}/roles/kube-controller-manager/files/ssl/k8s
      \cp -pdr ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/kubernetes/server/bin/kube-controller-manager ${HOST_PATH}/roles/kube-controller-manager/files/bin/
      # 复制kube-controller-manager.kubeconfig 文件
      \cp -pdr ${HOST_PATH}/kubeconfig/kube-controller-manager.kubeconfig ${HOST_PATH}/roles/kube-controller-manager/templates/
      # 复制ssl
      \cp -pdr ${HOST_PATH}/cfssl/pki/k8s/{k8s-controller-manager*.pem,k8s-ca*.pem} ${HOST_PATH}/roles/kube-controller-manager/files/ssl/k8s
    fi
  else
    colorEcho ${RED} "kubernetes no download."
    exit 1
  fi
  # 创建kube-controller-manager 启动配置文件
  cat >${HOST_PATH}/roles/kube-controller-manager/templates/kube-controller-manager <<EOF
KUBE_CONTROLLER_MANAGER_OPTS="--profiling \\
--concurrent-service-syncs=${CONCURRENT_SERVICE_SYNCS} \\
--concurrent-deployment-syncs=${CONCURRENT_DEPLOYMENT_SYNCS} \\
--concurrent-gc-syncs=${CONCURRENT_GC_SYNCS} \\
--leader-elect=true \\
--bind-address=0.0.0.0 \\
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
--requestheader-client-ca-file=${K8S_PATH}/ssl/k8s/k8s-ca.pem \\
--requestheader-allowed-names=aggregator \\
--requestheader-extra-headers-prefix=X-Remote-Extra- \\
--requestheader-group-headers=X-Remote-Group \\
--requestheader-username-headers=X-Remote-User \\
--node-monitor-grace-period=${NODE_MONITOR_GRACE_PERIOD} \\
--node-monitor-period=${NODE_MONITOR_PERIOD} \\
--node-startup-grace-period=${NODE_STARTUP_GRACE_PERIOD} \\
--terminated-pod-gc-threshold=${TERMINATED_POD_GC_THRESHOLD} \\
--cluster-signing-cert-file=${K8S_PATH}/ssl/k8s/k8s-ca.pem \\
--cluster-signing-key-file=${K8S_PATH}/ssl/k8s/k8s-ca-key.pem  \\
--cluster-signing-duration=${EXPIRY_TIME}0m0s \\
--root-ca-file=${K8S_PATH}/ssl/k8s/k8s-ca.pem \\
--service-account-private-key-file=${K8S_PATH}/ssl/k8s/k8s-ca-key.pem \\
--enable-garbage-collector=true \\
--controllers=*,bootstrapsigner,tokencleaner \\
--horizontal-pod-autoscaler-sync-period=10s \\
--tls-cert-file=${K8S_PATH}/ssl/k8s/k8s-controller-manager.pem \\
--tls-private-key-file=${K8S_PATH}/ssl/k8s/k8s-controller-manager-key.pem \\
--kube-api-qps=${KUBE_API_QPS} \\
--kube-api-burst=${KUBE_API_BURST} \\
--tls-cipher-suites=${TLS_CIPHER} \\
--v=${LEVEL_LOG}"
EOF
  # 创建kube-controller-manager 启动文件
  cat >${HOST_PATH}/roles/kube-controller-manager/templates/kube-controller-manager.service <<EOF
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
LimitNOFILE=${HARD_SOFT}
LimitNPROC=${HARD_SOFT}
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
  # 创建kube-controller-manager playbook
  cat >${HOST_PATH}/roles/kube-controller-manager/tasks/main.yml <<EOF
- name: create groupadd k8s
  group: name=k8s
- name: create name k8s
  user: name=k8s shell="/sbin/nologin k8s" group=k8s
- name: Create  ${K8S_PATH}
  file:
    path: "${K8S_PATH}/{{ item }}"
    state: directory
    owner: k8s
    group: root
  with_items:
      - log
      - conf
      - config
- name: Create /usr/libexec/kubernetes/kubelet-plugins/volume/exec/
  file:
    path: "/usr/libexec/kubernetes/kubelet-plugins/volume/exec/"
    state: directory
    owner: k8s
    group: root    
- name: copy kube-controller-manager
  copy: 
    src: bin 
    dest: ${K8S_PATH}/ 
    owner: k8s 
    group: root 
    mode: 0755
- name: copy  ssl
  copy: 
    src: '{{ item }}'
    dest: ${K8S_PATH}/ 
    owner: k8s 
    group: root
  with_items:
      - ssl
- name: kube-controller-manager conf
  template: 
    src: kube-controller-manager 
    dest: ${K8S_PATH}/conf 
    owner: k8s 
    group: root
- name: kube-controller-manager config
  template:
    src: kube-controller-manager.kubeconfig 
    dest: ${K8S_PATH}/config
    owner: k8s
    group: root
- name: Change file ownership, group and permissions k8s
  file:
    path: ${K8S_PATH}/
    owner: k8s
    group: root
- name: copy kube-controller-manager.service
  template: 
    src: kube-controller-manager.service
    dest: /lib/systemd/system/
- name: Reload service daemon-reload
  shell: systemctl daemon-reload
- name: Enable service kube-controller-manager, and not touch the state
  service:
    name: kube-controller-manager
    enabled: yes
- name: Start service kube-controller-manager, if not restarted
  service:
    name: kube-controller-manager
    state: restarted
EOF
  cat >${HOST_PATH}/kube-controller-manager.yml <<EOF
- hosts: all
  user: root
  roles:
    - kube-controller-manager
EOF
  return 0
}
schedulerConfig() {
  colorEcho ${GREEN} "create for kube-scheduler Config."
  # 创建 kube-scheduler playbook 目录
  if [[ ! -d "${HOST_PATH}/roles/kube-scheduler/" ]]; then
    mkdir -p ${HOST_PATH}/roles/kube-scheduler/{files,tasks,templates}
  else
    colorEcho ${GREEN} '文件夹已经存在'
  fi
  if [[ -e "${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}.tar.gz" ]]; then
    if [[ -e "${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/kubernetes/server/bin/kube-scheduler" ]]; then
      # cp 二进制文件及ssl及kubeconfig 文件到 ansible 目录
      mkdir -p ${HOST_PATH}/roles/kube-scheduler/files/{ssl,bin}
      mkdir -p ${HOST_PATH}/roles/kube-scheduler/files/ssl/k8s
      \cp -pdr ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/kubernetes/server/bin/kube-scheduler ${HOST_PATH}/roles/kube-scheduler/files/bin/
      # 复制kube-scheduler.kubeconfig 文件
      \cp -pdr ${HOST_PATH}/kubeconfig/kube-scheduler.kubeconfig ${HOST_PATH}/roles/kube-scheduler/templates/
      # 复制ssl
      \cp -pdr ${HOST_PATH}/cfssl/pki/k8s/{k8s-scheduler*.pem,k8s-ca.pem} ${HOST_PATH}/roles/kube-scheduler/files/ssl/k8s
    elif [[ ! -e "${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/kubernetes/server/bin/kube-scheduler" ]] || [[ ! -e "${HOST_PATH}/roles/kube-scheduler/files/bin/kube-scheduler" ]]; then
      # cp 二进制文件及ssl 文件到 ansible 目录
      mkdir -p ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}
      tar -xf ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}.tar.gz -C ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/
      # cp 二进制文件及ssl及kubeconfig 文件到 ansible 目录
      mkdir -p ${HOST_PATH}/roles/kube-scheduler/files/{ssl,bin}
      mkdir -p ${HOST_PATH}/roles/kube-scheduler/files/ssl/k8s
      \cp -pdr ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/kubernetes/server/bin/kube-scheduler ${HOST_PATH}/roles/kube-scheduler/files/bin/
      # 复制kube-scheduler.kubeconfig 文件
      \cp -pdr ${HOST_PATH}/kubeconfig/kube-scheduler.kubeconfig ${HOST_PATH}/roles/kube-scheduler/templates/
      # 复制ssl
      \cp -pdr ${HOST_PATH}/cfssl/pki/k8s/{k8s-scheduler*.pem,k8s-ca.pem} ${HOST_PATH}/roles/kube-scheduler/files/ssl/k8s
    fi
  else
    colorEcho ${RED} "kubernetes no download."
    exit 1
  fi
  # 创建kube-scheduler 启动配置文件
  cat >${HOST_PATH}/roles/kube-scheduler/templates/kube-scheduler <<EOF
KUBE_SCHEDULER_OPTS="--bind-address=0.0.0.0 \\
                   --leader-elect=true \\
                   --kubeconfig=${K8S_PATH}/config/kube-scheduler.kubeconfig \\
                   --authentication-kubeconfig=${K8S_PATH}/config/kube-scheduler.kubeconfig \\
                   --authorization-kubeconfig=${K8S_PATH}/config/kube-scheduler.kubeconfig \\
                   --tls-cert-file=${K8S_PATH}/ssl/k8s/k8s-scheduler.pem \\
                   --tls-private-key-file=${K8S_PATH}/ssl/k8s/k8s-scheduler-key.pem \\
                   --client-ca-file=${K8S_PATH}/ssl/k8s/k8s-ca.pem \\
                   --requestheader-allowed-names= \\
                   --requestheader-extra-headers-prefix=X-Remote-Extra- \\
                   --requestheader-group-headers=X-Remote-Group \\
                   --requestheader-username-headers=X-Remote-User \\
                   --kube-api-qps=${KUBE_API_QPS} \\
                   --authentication-tolerate-lookup-failure=false \\
                   --kube-api-burst=${KUBE_API_BURST} \\
                   --tls-cipher-suites=${TLS_CIPHER} \\
                   --v=${LEVEL_LOG}"
EOF
  # 创建kube-scheduler 启动文件
  cat >${HOST_PATH}/roles/kube-scheduler/templates/kube-scheduler.service <<EOF
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
LimitNOFILE=${HARD_SOFT}
LimitNPROC=${HARD_SOFT}
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
  # 创建kube-scheduler playbook
  cat >${HOST_PATH}/roles/kube-scheduler/tasks/main.yml <<EOF
- name: create groupadd k8s
  group: name=k8s
- name: create name k8s
  user: name=k8s shell="/sbin/nologin k8s" group=k8s
- name: Create  ${K8S_PATH}
  file:
    path: "${K8S_PATH}/{{ item }}"
    state: directory
    owner: k8s
    group: root
  with_items:
      - log
      - conf
      - config
- name: copy kube-scheduler
  copy: 
    src: bin 
    dest: ${K8S_PATH}/ 
    owner: k8s 
    group: root 
    mode: 0755
- name: copy  ssl
  copy: 
    src: '{{ item }}'
    dest: ${K8S_PATH}/ 
    owner: k8s 
    group: root
  with_items:
      - ssl
- name: kube-scheduler conf
  template: 
    src: kube-scheduler 
    dest: ${K8S_PATH}/conf 
    owner: k8s 
    group: root
- name: kube-scheduler config
  template: 
    src: kube-scheduler.kubeconfig 
    dest: ${K8S_PATH}/config 
    owner: k8s 
    group: root
- name: copy kube-scheduler.service
  template: 
    src: kube-scheduler.service  
    dest: /lib/systemd/system/
- name: Change file ownership, group and permissions k8s
  file:
    path: ${K8S_PATH}/
    owner: k8s
    group: root
- name: Reload service daemon-reload
  shell: systemctl daemon-reload
- name: Enable service kube-scheduler, and not touch the state
  service:
    name: kube-scheduler
    enabled: yes
- name: Start service kube-scheduler, if not started
  service:
    name: kube-scheduler
    state: restarted
EOF
  cat >${HOST_PATH}/kube-scheduler.yml <<EOF
- hosts: all
  user: root
  roles:
    - kube-scheduler
EOF
  return 0
}
kubeProxyConfig() {
  colorEcho ${GREEN} "create for kube-proxy Config."
  # 创建 kube-proxy playbook 目录
  if [[ ! -d "${HOST_PATH}/roles/kube-proxy/" ]]; then
    mkdir -p ${HOST_PATH}/roles/kube-proxy/{files,tasks,templates}
  else
    colorEcho ${GREEN} '文件夹已经存在'
  fi
  if [[ -e "${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}.tar.gz" ]]; then
    if [[ -e "${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/kubernetes/server/bin/kube-proxy" ]]; then
      # cp 二进制文件及ssl及kubeconfig 文件到 ansible 目录
      mkdir -p ${HOST_PATH}/roles/kube-proxy/files/bin
      \cp -pdr ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/kubernetes/server/bin/kube-proxy ${HOST_PATH}/roles/kube-proxy/files/bin/
      # 复制kube-proxy.kubeconfig 文件
      \cp -pdr ${HOST_PATH}/kubeconfig/kube-proxy.kubeconfig ${HOST_PATH}/roles/kube-proxy/templates/
    elif [[ ! -e "${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/kubernetes/server/bin/kube-proxy" ]] || [[ ! -e "${HOST_PATH}/roles/kube-proxy/files/bin/kube-proxy" ]]; then
      # cp 二进制文件及ssl 文件到 ansible 目录
      mkdir -p ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}
      tar -xf ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}.tar.gz -C ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/
      # cp 二进制文件及ssl及kubeconfig 文件到 ansible 目录
      mkdir -p ${HOST_PATH}/roles/kube-proxy/files/bin
      \cp -pdr ${DOWNLOAD_PATH}/kubernetes-server-linux-amd64-${KUBERNETES_VERSION}/kubernetes/server/bin/kube-proxy ${HOST_PATH}/roles/kube-proxy/files/bin/
      # 复制kube-proxy.kubeconfig 文件
      \cp -pdr ${HOST_PATH}/kubeconfig/kube-proxy.kubeconfig ${HOST_PATH}/roles/kube-proxy/templates/
    fi
  else
    colorEcho ${RED} "kubernetes no download."
    exit 1
  fi
  # 创建 kube-proxy 启动配置文件
    if [ $IPVS = true ]; then
  cat >${HOST_PATH}/roles/kube-proxy/templates/kube-proxy <<EOF
KUBE_PROXY_OPTS="--v=${LEVEL_LOG} \\
--masquerade-all=true \\
--proxy-mode=ipvs \\
--profiling=true \\
--ipvs-min-sync-period=5s \\
--ipvs-sync-period=5s \\
--ipvs-scheduler=rr \\
--conntrack-max-per-core=0 \\
--cluster-cidr=${CLUSTER_CIDR} \\
--metrics-bind-address=0.0.0.0 \\
--hostname-override={{ ansible_hostname }} \\
--kubeconfig=${K8S_PATH}/conf/kube-proxy.kubeconfig \\
--ipvs-exclude-cidrs=${MASTER_IP}/32"
EOF
else
  cat >${HOST_PATH}/roles/kube-proxy/templates/kube-proxy <<EOF
KUBE_PROXY_OPTS="--v=${LEVEL_LOG} \\
--masquerade-all=true \\
--proxy-mode=ipvs \\
--profiling=true \\
--ipvs-min-sync-period=5s \\
--ipvs-sync-period=5s \\
--ipvs-scheduler=rr \\
--conntrack-max-per-core=0 \\
--cluster-cidr=${CLUSTER_CIDR} \\
--metrics-bind-address=0.0.0.0 \\
--hostname-override={{ ansible_hostname }} \\
--kubeconfig=${K8S_PATH}/conf/kube-proxy.kubeconfig"
EOF
fi
  # 创建 kube-proxy 启动文件
  cat >${HOST_PATH}/roles/kube-proxy/templates/kube-proxy.service <<EOF
[Unit]
Description=Kubernetes Proxy
After=network.target

[Service]
LimitNOFILE=${HARD_SOFT}
LimitNPROC=${HARD_SOFT}
LimitCORE=infinity
LimitMEMLOCK=infinity
EnvironmentFile=-${K8S_PATH}/conf/kube-proxy
ExecStart=${K8S_PATH}/bin/kube-proxy \$KUBE_PROXY_OPTS
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
  # 创建kube-proxy ansible
  cat >${HOST_PATH}/roles/kube-proxy/tasks/main.yml <<EOF
- name: copy kube-proxy to ${K8S_PATH}
  copy: 
    src: bin 
    dest: ${K8S_PATH}/ 
    owner: root 
    group: root 
    mode: 0755
- name: copy to kube-proxy config
  template: 
    src: '{{ item }}' 
    dest: ${K8S_PATH}/conf
  with_items:
      - kube-proxy
      - kube-proxy.kubeconfig
- name:  copy to kube-proxy service
  template: 
    src: '{{ item }}' 
    dest: /lib/systemd/system/
  with_items:
      - kube-proxy.service
- name: Reload service daemon-reload
  shell: systemctl daemon-reload
- name: Enable service kube-proxy, and not touch the state
  service:
    name: kube-proxy
    enabled: yes
- name: Start service kube-proxy, if not restarted
  service:
    name: kube-proxy
    state: restarted
EOF
  cat >${HOST_PATH}/kube-proxy.yml <<EOF
- hosts: all
  user: root
  roles:
    - kube-proxy
EOF
  return 0
}
netPlugConfig() {
  if [ ${NET_PLUG} == "flannel" ]; then # 生成flannel 部署yaml
    colorEcho ${GREEN} "create for k8s yaml."
    if [[ ! -d "${HOST_PATH}/yaml" ]]; then
      mkdir -p ${HOST_PATH}/yaml
    else
      colorEcho ${GREEN} '文件夹已经存在'
    fi
    # 创建flannel yaml
    cat >${HOST_PATH}/yaml/kube-flannel.yaml <<EOF
---
kind: Namespace
apiVersion: v1
metadata:
  name: kube-flannel
  labels:
    k8s-app: flannel
    pod-security.kubernetes.io/enforce: privileged
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  labels:
    k8s-app: flannel
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
  - get
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - nodes/status
  verbs:
  - patch
- apiGroups:
  - networking.k8s.io
  resources:
  - clustercidrs
  verbs:
  - list
  - watch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  labels:
    k8s-app: flannel
  name: flannel
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: flannel
subjects:
- kind: ServiceAccount
  name: flannel
  namespace: kube-flannel
---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: flannel
  name: flannel
  namespace: kube-flannel
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: kube-flannel-cfg
  namespace: kube-flannel
  labels:
    tier: node
    k8s-app: flannel
    app: flannel
data:
  cni-conf.json: |
    {
      "name": "cni0",
      "cniVersion": "0.3.1",
      "plugins": [
        {
          "type": "flannel",
          "delegate": {
            "hairpinMode": true,
            "isDefaultGateway": true
          }
        },
        {
          "type": "portmap",
          "capabilities": {
            "portMappings": true
          }
        }
      ]
    }
  net-conf.json: |
    {
      "Network": "${CLUSTER_CIDR}",
      "Backend": {
        "Type": "vxlan"
      }
    }
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: kube-flannel-ds
  namespace: kube-flannel
  labels:
    tier: node
    app: flannel
    k8s-app: flannel
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
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/os
                operator: In
                values:
                - linux
      hostNetwork: true
      priorityClassName: system-node-critical
      tolerations:
        - effect: NoSchedule
          operator: Exists
        - key: CriticalAddonsOnly
          operator: Exists
        - effect: NoExecute
          operator: Exists
      serviceAccountName: flannel
      initContainers:
      - name: install-cni-plugin
        image: ${FLANNEL_CNI_PLUGIN}
        command:
        - cp
        args:
        - -f
        - /flannel
        - /opt/cni/bin/flannel
        volumeMounts:
        - name: cni-plugin
          mountPath: /opt/cni/bin
      - name: install-cni
        image: ${FLANNEL_VERSION}
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
        image: ${FLANNEL_VERSION}
        command:
        - /opt/bin/flanneld
        args:
        - --ip-masq
        - --kube-subnet-mgr
        resources:
          requests:
            cpu: "100m"
            memory: "50Mi"
        securityContext:
          privileged: false
          capabilities:
            add: ["NET_ADMIN", "NET_RAW"]
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: EVENT_QUEUE_DEPTH
          value: "5000"
        volumeMounts:
        - name: run
          mountPath: /run/flannel
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
        - name: xtables-lock
          mountPath: /run/xtables.lock
      volumes:
      - name: run
        hostPath:
          path: /run/flannel
      - name: cni-plugin
        hostPath:
          path: ${CNI_BIN_DIR}
      - name: cni
        hostPath:
          path: ${CNI_CONF_DIR}
      - name: flannel-cfg
        configMap:
          name: kube-flannel-cfg
      - name: xtables-lock
        hostPath:
          path: /run/xtables.lock
          type: FileOrCreate
EOF
    return 0
  elif [ ${NET_PLUG} == "kube-router" ]; then # 生成kube-router 部署yaml
    colorEcho ${GREEN} "create for k8s yaml."
    if [[ ! -d "${HOST_PATH}/yaml" ]]; then
      mkdir -p ${HOST_PATH}/yaml
    else
      colorEcho ${GREEN} '文件夹已经存在'
    fi
    cat >${HOST_PATH}/yaml/kube-router.yaml <<EOF
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
       "cniVersion":"0.3.1",
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
        image: ${KUBE_ROUTER_IMAGE}
        imagePullPolicy: Always
        args:
        - --run-router=true 
        - --run-firewall=true 
        - --run-service-proxy=false 
        - --advertise-cluster-ip=false 
        - --advertise-loadbalancer-ip=false 
        - --advertise-pod-cidr=true 
        - --advertise-external-ip=false
        - --hairpin-mode=true      
        - --cluster-asn=64512 
        - --metrics-path=/metrics 
        - --metrics-port=20241 
        - --enable-cni=true 
        - --enable-ibgp=true      
        - --enable-overlay=true 
        - --nodeport-bindon-all-ip=false 
        - --nodes-full-mesh=true 
        - --enable-pod-egress=true
        - --v=${LEVEL_LOG}
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
      initContainers:
      - name: install-cni
        image: ${KUBE_ROUTER_INIT}
        imagePullPolicy: Always
        command:
        - /bin/sh
        - -c
        - set -e -x;
            rm -f /etc/cni/net.d/*.conf;
            TMP=/etc/cni/net.d/.tmp-kuberouter-cfg;
            cp /etc/kube-router/cni-conf.json \${TMP};
            mv \${TMP} /etc/cni/net.d/10-kuberouter.conflist;
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
          path: ${CNI_CONF_DIR}
      - name: kube-router-cfg
        configMap:
          name: kube-router-cfg
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
apiVersion: rbac.authorization.k8s.io/v1
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
  - apiGroups:
      - "coordination.k8s.io"
    resources:
      - leases
    verbs:
      - get
      - create
      - update
  - apiGroups:
      - ""
    resources:
      - services/status
    verbs:
      - update
  - apiGroups:
      - "discovery.k8s.io"
    resources:
      - endpointslices
    verbs:
      - get
      - list
      - watch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
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
    return 0
  fi
  return 0
}
coreDNS() {
  cat >${HOST_PATH}/yaml/coredns.yaml <<EOF
# __MACHINE_GENERATED_WARNING__

apiVersion: v1
kind: ServiceAccount
metadata:
  name: coredns
  namespace: kube-system
  labels:
      kubernetes.io/cluster-service: "true"
      addonmanager.kubernetes.io/mode: Reconcile
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
    addonmanager.kubernetes.io/mode: Reconcile
  name: system:coredns
rules:
- apiGroups:
  - ""
  resources:
  - endpoints
  - services
  - pods
  - namespaces
  verbs:
  - list
  - watch
- apiGroups:
  - discovery.k8s.io
  resources:
  - endpointslices
  verbs:
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - get
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
    addonmanager.kubernetes.io/mode: EnsureExists
  name: system:coredns
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:coredns
subjects:
- kind: ServiceAccount
  name: coredns
  namespace: kube-system
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
  labels:
      addonmanager.kubernetes.io/mode: EnsureExists
data:
  Corefile: |
    .:53 {
        errors
        health {
            lameduck 5s
        }
        ready
        kubernetes ${CLUSTER_DNS_DOMAIN} in-addr.arpa ip6.arpa {
            pods verified
            endpoint_pod_names
            fallthrough in-addr.arpa ip6.arpa
            ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf {
            max_concurrent 1000
        }
        cache 30
        reload
        loadbalance
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coredns
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
    kubernetes.io/name: "CoreDNS"
spec:
  # replicas: not specified here:
  # 1. In order to make Addon Manager do not reconcile this replicas parameter.
  # 2. Default is 1.
  # 3. Will be tuned in real time if DNS horizontal auto-scaling is turned on.
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      k8s-app: kube-dns
  template:
    metadata:
      labels:
        k8s-app: kube-dns
      annotations:
        seccomp.security.alpha.kubernetes.io/pod: 'docker/default'
    spec:
      priorityClassName: system-cluster-critical
      serviceAccountName: coredns
      tolerations:
        - key: "CriticalAddonsOnly"
          operator: "Exists"
      nodeSelector:
        beta.kubernetes.io/os: linux
      containers:
      - name: coredns
        image: ${COREDNS_IMAGE}
        imagePullPolicy: Always
        resources:
          limits:
            memory: 100Mi
          requests:
            cpu: 100m
            memory: 70Mi
        args: [ "-conf", "/etc/coredns/Corefile" ]
        volumeMounts:
        - name: config-volume
          mountPath: /etc/coredns
          readOnly: true
        ports:
        - containerPort: 53
          name: dns
          protocol: UDP
        - containerPort: 53
          name: dns-tcp
          protocol: TCP
        - containerPort: 9153
          name: metrics
          protocol: TCP
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 60
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 5
        readinessProbe:
          httpGet:
            path: /ready
            port: 8181
            scheme: HTTP
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            add:
            - NET_BIND_SERVICE
            drop:
            - all
          readOnlyRootFilesystem: true
      dnsPolicy: Default
      volumes:
        - name: config-volume
          configMap:
            name: coredns
            items:
            - key: Corefile
              path: Corefile
---
apiVersion: v1
kind: Service
metadata:
  name: kube-dns
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
    kubernetes.io/name: "CoreDNS"
spec:
  selector:
    k8s-app: kube-dns
  clusterIP: ${CLUSTER_DNS_SVC_IP}
  ports:
  - name: dns
    port: 53
    protocol: UDP
  - name: dns-tcp
    port: 53
    protocol: TCP
  - name: metrics
    port: 9153
    protocol: TCP
EOF
}
environment() {
  # 生成环境变量配置方便创建kubeconfig 跟签发新的个人证书
  cat >${HOST_PATH}/environment.sh <<EOF
#!/bin/sh
export KUBE_APISERVER="${KUBE_APISERVER}"
export HOST_PATH="${HOST_PATH}"
export CERT_ST="${CERT_ST}"
export CERT_L="${CERT_L}"
export CERT_O="${CERT_O}"
export CERT_OU="${CERT_OU}"
export CERT_PROFILE="${CERT_PROFILE}"
export CLUSTER_DNS_DOMAIN="${CLUSTER_DNS_DOMAIN}"
export CLUSTER_DNS_SVC_IP="${CLUSTER_DNS_SVC_IP}"
export KUBECONFIG=${HOST_PATH}/kubeconfig/admin.kubeconfig
EOF
  return 0
}
checkETCD() {
  export ETCD_CACERT=${HOST_PATH}/cfssl/pki/etcd/etcd-ca.pem
  export ETCD_CERT=${HOST_PATH}/cfssl/pki/etcd/etcd-client.pem
  export ETCD_KEY=${HOST_PATH}/cfssl/pki/etcd/etcd-client-key.pem
  ETCD_IP=$(echo $ETCD_SERVER_IPS | sed -e "s/\"//g")
  array=(${ETCD_IP//,/ })

  for var in ${array[@]}; do
    curl -k --connect-timeout 5 --cacert ${ETCD_CACERT} --cert ${ETCD_CERT} --key ${ETCD_KEY} https://$var:2379/health
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "$var etcd health FATAL."
      exit $?
    else
      colorEcho ${GREEN} "$var etcd health is OK."
    fi
  done
  if [ ${K8S_EVENTS} == "ON" ]; then
    ETCD_IP=$(echo $ETCD_EVENTS_IPS | sed -e "s/\"//g") #  ETCD_EVENTS_IPS
    array=(${ETCD_IP//,/ })

    for var in ${array[@]}; do
      curl -k --connect-timeout 5 --cacert ${ETCD_CACERT} --cert ${ETCD_CERT} --key ${ETCD_KEY} https://$var:2379/health
      if [[ $? -ne 0 ]]; then
        colorEcho ${RED} "$var etcd events health FATAL."
        exit $?
      else
        colorEcho ${GREEN} "$var etcd events health is OK."
      fi
    done
  fi
  return 0
}
checkK8SMaster() {
  export K8S_CACERT=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem
  export K8S_CERT=${HOST_PATH}/cfssl/pki/k8s/k8s-apiserver-admin.pem
  export K8S_KEY=${HOST_PATH}/cfssl/pki/k8s/k8s-apiserver-admin-key.pem
  curl -k --connect-timeout 5 --cacert ${K8S_CACERT} --cert ${K8S_CERT} --key ${K8S_KEY} ${KUBE_APISERVER}/healthz
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "${KUBE_APISERVER} K8SMaster  health FATAL."
    exit $?
  else
    colorEcho ${GREEN} "${KUBE_APISERVER} K8SMaster  health is OK."
  fi
  return 0
}
selectEnv() {
  if [ ${NET_PLUG} == "flannel" ]; then
    NETPLUG=kube-flannel.yaml
  elif [ ${NET_PLUG} == "kube-router" ]; then
    NETPLUG=kube-router.yaml
  fi
  if [ ${RUNTIME} == "DOCKER" ]; then
    RUNTIME_FILE=docker.yml
  elif [ ${RUNTIME} == "CONTAINERD" ]; then
    RUNTIME_FILE=containerd.yml
  elif [ ${RUNTIME} == "CRIO" ]; then
    RUNTIME_FILE=crio.yml
  fi
  if [ ${IPTABLES_INSTALL} == "ON" ]; then
    IPTABLES_FILE=iptables.yml
  else
    IPTABLES_FILE=""
  fi
  if [ ${PACKAGE_SYSCTL} == "ON" ]; then
    PACKAGE_SYSCTL_FILE=package-sysctl.yml
  else
    PACKAGE_SYSCTL_FILE=""
  fi
  if [ ${K8S_EVENTS} == ON ]; then
    EVENTS_ETCD="##########  etcd EVENTS 部署 ansible-playbook -i ${ETCD_EVENTS_IPS}, ${PACKAGE_SYSCTL_FILE}  events-etcd.yml --ssh-common-args=\"-o StrictHostKeyChecking=no\" ${ASK_PASS}"
  else
    EVENTS_ETCD=""
  fi
}
README.md() {
  #colorEcho ${BLUE} "开启选择使用插件"
  selectEnv
  #colorEcho ${BLUE} "验证ansible 连接服务器是否需求输入密码"
  checkAnsible # 检查ansible 连接是否需要输入密码
  cat >${HOST_PATH}/README.md <<EOF
########## mkdir -p /root/.kube
##########复制admin kubeconfig 到root用户作为kubectl 工具默认密钥文件
########## \cp -pdr ${HOST_PATH}/kubeconfig/admin.kubeconfig /root/.kube/config
##########　kubectl 可以读取环境变量 export KUBECONFIG=${HOST_PATH}/kubeconfig/admin.kubeconfig
###################################################################################
##########  ansible 及ansible-playbook 单个ip ip结尾一点要添加“,”符号 ansible-playbook -i 192.168.0.1, xxx.yml
##########  source ${HOST_PATH}/environment.sh 设置环境变量生效方便后期新增证书等
##########  etcd 部署 ansible-playbook -i ${ETCD_SERVER_IPS}, ${PACKAGE_SYSCTL_FILE} etcd.yml --ssh-common-args="-o StrictHostKeyChecking=no" ${ASK_PASS}
${EVENTS_ETCD}
##########  kube-apiserver 部署 ansible-playbook -i ${K8S_APISERVER_VIP}, ${PACKAGE_SYSCTL_FILE} kube-apiserver.yml --ssh-common-args="-o StrictHostKeyChecking=no" ${ASK_PASS}
##########  部署完成验证集群 kubectl cluster-info  kubectl api-versions  kubectl get cs
##########  提交bootstrap到K8S集群 kubectl apply -f ${HOST_PATH}/yaml/bootstrap-secret.yaml
##########  提交授权到K8S集群 kubectl apply -f ${HOST_PATH}/yaml/kubelet-bootstrap-rbac.yaml kubectl apply -f ${HOST_PATH}/yaml/kube-api-rbac.yaml 
##########  安装其它组件 ansible-playbook -i ${K8S_APISERVER_VIP}, ${IPTABLES_FILE} cni.yml ${RUNTIME_FILE} kube-ha-proxy.yml  kubelet.yml kube-controller-manager.yml kube-scheduler.yml kube-proxy.yml --ssh-common-args="-o StrictHostKeyChecking=no" ${ASK_PASS}
##########  node 节点部署  ansible-playbook -i ${NODE_IP}, ${PACKAGE_SYSCTL_FILE} ${IPTABLES_FILE} cni.yml ${RUNTIME_FILE} kube-ha-proxy.yml  kubelet.yml kube-proxy.yml --ssh-common-args="-o StrictHostKeyChecking=no" ${ASK_PASS}
##########  部署网络插件 kubectl apply -f ${HOST_PATH}/yaml/${NETPLUG}
##########  部署coredns插件 kubectl apply -f ${HOST_PATH}/yaml/coredns.yaml
##########  查看node 节点是否注册到K8S kubectl get node kubectl get csr 如果有节点 
##########  给 master ingress 添加污点 防止其它服务使用这些节点:kubectl taint nodes  k8s-master-01 node-role.kubernetes.io/master=:NoSchedule kubectl taint nodes  k8s-ingress-01 node-role.kubernetes.io/ingress=:NoSchedule
##########  windows 证书访问 openssl pkcs12 -export -inkey k8s-apiserver-admin-key.pem -in k8s_apiserver-admin.pem -out client.p12
########## kubectl proxy --port=8001 &  把kube-apiserver 端口映射成本地 8001 端口      
########## 查看kubelet节点配置信息 NODE_NAME="k8s-node-04"; curl -sSL "http://localhost:8001/api/v1/nodes/\${NODE_NAME}/proxy/configz" | jq '.kubeletconfig|.kind="KubeletConfiguration"|.apiVersion="kubelet.config.k8s.io/v1beta1"' > kubelet_configz_\${NODE_NAME} 
EOF
  return 0
}
installInitScript() {
  colorEcho ${BLUE} "下载K8S 组件"
  downloadK8S
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "下载K8S 组件出错."
    exit $?
  fi
  colorEcho ${BLUE} "安装 ansible."
  ansibleInstall
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "安装 ansible出错."
    exit $?
  fi
  colorEcho ${BLUE} "安装 kubectl."
  kubectlInstall
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "安装 kubectl出错."
    exit $?
  fi
  colorEcho ${BLUE} "安装 证书签名工具cfssl."
  cfsslInstall
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "安装 证书签名工具cfssl出错."
    exit $?
  fi
  colorEcho ${BLUE} "生成 etcd Cert."
  etcdCert
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "生成 etcd Cert出错."
    exit $?
  fi
  colorEcho ${BLUE} "生成 k8s Cert."
  k8sCert
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "生成 k8s Cert出错."
    exit $?
  fi
  colorEcho ${BLUE} "生成 etcd ansible-playbook 部署yml."
  etcdConfig
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "生成 etcd ansible-playbook 部署yml错误."
    exit $?
  fi
  colorEcho ${BLUE} "生成 k8sKubeConfig."
  k8sKubeConfig
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "生成 k8sKubeConfig错误."
    exit $?
  fi
  colorEcho ${BLUE} "生成 kube-apiserver 部署yml."
  KubeApiserverConfig
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "生成 kube-apiserver 部署yml错误."
    exit $?
  fi
  colorEcho ${BLUE} "生成 kube-apiserver 部署yml."
  KubeApiserverConfig
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "生成 kube-apiserver 部署yml错误."
    exit $?
  fi
  colorEcho ${BLUE} "生成kube-Ha-Proxy 部署yml."
  kubeHaProxy
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "生成 kube-Ha-Proxy 部署yml错误."
    exit $?
  fi
  colorEcho ${BLUE} "生成package-Sysctl 部署yml."
  packageSysctl
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "生成 package-Sysctl 部署yml错误."
    exit $?
  fi
  colorEcho ${BLUE} "生成runtime-Config 部署yml."
  runtimeConfig
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "生成 runtime-Config 部署yml错误."
    exit $?
  fi
  colorEcho ${BLUE} "生成bootstrap-Config 部署yaml."
  bootstrapConfig
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "生成 bootstrap-Config 部署yaml错误."
    exit $?
  fi
  colorEcho ${BLUE} "生成kubelet-Config 部署yml."
  kubeletConfig
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "生成 kubelet-Config 部署yml错误."
    exit $?
  fi
  colorEcho ${BLUE} "生成cni-Config 部署yml."
  cniConfig
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "生成 cni-Config 部署yml错误."
    exit $?
  fi
  colorEcho ${BLUE} "生成iptables-Config 部署yml."
  iptablesConfig
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "生成iptables-Config 部署yml错误."
    exit $?
  fi
  colorEcho ${BLUE} "生成kube-controller-manager 部署yml."
  controllerConfig
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "生成kube-controller-manager 部署yml错误."
    exit $?
  fi
  colorEcho ${BLUE} "生成kube-scheduler 部署yml."
  schedulerConfig
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "生成kube-scheduler 部署yml错误."
    exit $?
  fi
  colorEcho ${BLUE} "生成kube-proxy 部署yml."
  kubeProxyConfig
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "生成kube-proxy 部署yml错误."
    exit $?
  fi
  colorEcho ${BLUE} "生成net Plug Config 部署yaml."
  netPlugConfig
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "生成net Plug Config 部署yaml错误."
    exit $?
  fi
  colorEcho ${BLUE} "生成coreDNS 部署yaml."
  coreDNS
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "生成coreDNS 部署yaml错误."
    exit $?
  fi
  colorEcho ${BLUE} "生成environment."
  environment
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "生成environment错误."
    exit $?
  fi
  colorEcho ${BLUE} "生成README.md."
  README.md
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "生成README.md错误."
    exit $?
  fi
}
checkAnsible() {
  ansible -i ${K8S_VIP}, all -m ping --ssh-common-args="-o StrictHostKeyChecking=no" >/dev/null 2>&1
  if [[ $? -ne 0 ]]; then
    ASK_PASS="-k"
  else
    ASK_PASS=""
  fi
  return 0
}
installK8SPackage() {
  colorEcho ${BLUE} "开启选择使用插件"
  selectEnv
  colorEcho ${BLUE} " 验证ansible 连接服务器是否需求输入密码"
  checkAnsible # 检查ansible 连接是否需要输入密码
  colorEcho ${BLUE} "部署etcd 集群"
  ETCD_SERVER_IPS=$(echo $ETCD_SERVER_IPS | sed -e "s/\"//g")
  ansible-playbook -i ${ETCD_SERVER_IPS}, ${PACKAGE_SYSCTL_FILE} etcd.yml --ssh-common-args="-o StrictHostKeyChecking=no" ${ASK_PASS}
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "${ETCD_SERVER_IPS} etcd  部署失败."
    exit $?
  else
    colorEcho ${GREEN} "${ETCD_SERVER_IPS} etcd  集群 部署成功."
  fi
  if [ ${K8S_EVENTS} == "ON" ]; then
    ETCD_EVENTS_IPS=$(echo $ETCD_EVENTS_IPS | sed -e "s/\"//g")
    colorEcho ${BLUE} "部署etcd events 集群"
    ansible-playbook -i ${ETCD_EVENTS_IPS}, ${PACKAGE_SYSCTL_FILE} events-etcd.yml --ssh-common-args="-o StrictHostKeyChecking=no" ${ASK_PASS}
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "${ETCD_EVENTS_IPS} etcd events  部署失败."
      exit $?
    else
      colorEcho ${GREEN} "${ETCD_EVENTS_IPS} etcd events 集群 部署成功."
    fi
  fi
  colorEcho ${BLUE} "检查etcd 集群"
  checkETCD
  colorEcho ${BLUE} "部署 kube-apiserver"
  K8S_APISERVER_VIP=$(echo $K8S_APISERVER_VIP | sed -e "s/\"//g")
  ansible-playbook -i ${K8S_APISERVER_VIP}, ${PACKAGE_SYSCTL_FILE} kube-apiserver.yml --ssh-common-args="-o StrictHostKeyChecking=no" ${ASK_PASS}
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "${K8S_APISERVER_VIP} kube-apiserver  部署失败."
    exit $?
  else
    colorEcho ${GREEN} "${K8S_APISERVER_VIP} kube-apiserver 集群 部署成功."
  fi
  colorEcho ${BLUE} "检查checkK8SMaster 集群"
  checkK8SMaster
  colorEcho ${BLUE} "kubectl kubeconfig 配置"
  export KUBECONFIG=${HOST_PATH}/kubeconfig/admin.kubeconfig
  if [[ -n $(command -v kubectl) ]]; then
    kubectl=$(command -v kubectl)
    colorEcho ${BLUE} "集群提交bootstrap secret"
    $kubectl apply -f ${HOST_PATH}/yaml/bootstrap-secret.yaml
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "${HOST_PATH}/yaml/bootstrap-secret.yaml  部署失败."
      exit $?
    else
      colorEcho ${GREEN} "${HOST_PATH}/yaml/bootstrap-secret.yaml 部署成功."
    fi
    colorEcho ${BLUE} "bootstrap  rbac 绑定"
    $kubectl apply -f ${HOST_PATH}/yaml/kubelet-bootstrap-rbac.yaml
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "${HOST_PATH}/yaml/kubelet-bootstrap-rbac.yaml 部署失败."
      exit $?
    else
      colorEcho ${GREEN} "${HOST_PATH}/yaml/kubelet-bootstrap-rbac.yaml 部署成功."
    fi
    colorEcho ${BLUE} "K8S 组件  rbac 绑定"
    $kubectl apply -f ${HOST_PATH}/yaml/kube-api-rbac.yaml
    if [[ $? -ne 0 ]]; then
      colorEcho ${RED} "${HOST_PATH}/yaml/kube-api-rbac.yaml  部署失败."
      exit $?
    else
      colorEcho ${GREEN} "${HOST_PATH}/yaml/kube-api-rbac.yaml 部署成功."
    fi
  else
    colorEcho ${RED} "kubectl 文件不可用."
    exit $?
  fi
  colorEcho ${BLUE} " 部署K8S  kube-controller-manager kube-scheduler 服务器组件"
  ansible-playbook -i ${K8S_APISERVER_VIP}, ${IPTABLES_FILE} cni.yml ${RUNTIME_FILE} kube-ha-proxy.yml kubelet.yml kube-controller-manager.yml kube-scheduler.yml kube-proxy.yml --ssh-common-args="-o StrictHostKeyChecking=no" ${ASK_PASS}
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "kube-controller-manager kube-scheduler  部署失败."
    exit $?
  else
    colorEcho ${GREEN} "kube-controller-manager kube-scheduler 部署成功."
  fi
  colorEcho ${BLUE} " node 节点部署."
  ansible-playbook -i ${NODE_IP}, ${PACKAGE_SYSCTL_FILE} ${IPTABLES_FILE} cni.yml ${RUNTIME_FILE} kube-ha-proxy.yml kubelet.yml kube-proxy.yml --ssh-common-args="-o StrictHostKeyChecking=no" ${ASK_PASS}
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "node 节点  部署失败."
    exit $?
  else
    colorEcho ${GREEN} "node 节点 部署成功."
  fi
  colorEcho ${BLUE} "网络插件部署"
  $kubectl apply -f ${HOST_PATH}/yaml/${NETPLUG}
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "kubectl apply -f ${HOST_PATH}/yaml/${NETPLUG}  部署失败."
    exit $?
  else
    colorEcho ${GREEN} "kubectl apply -f ${HOST_PATH}/yaml/${NETPLUG} 部署成功."
  fi
  colorEcho ${BLUE} "coredns 部署"
  $kubectl apply -f ${HOST_PATH}/yaml/coredns.yaml
  if [[ $? -ne 0 ]]; then
    colorEcho ${RED} "kubectl apply -f ${HOST_PATH}/yaml/coredns.yaml  部署失败."
    exit $?
  else
    colorEcho ${GREEN} "kubectl apply -f ${HOST_PATH}/yaml/coredns.yaml 部署成功."
  fi
  $kubectl get nodes
  $kubectl get cs
  $kubectl cluster-info
  $kubectl get pod -A
  return 0
}
main() {
  colorEcho ${BLUE} "集群配置生成"
  installInitScript || return $?
  if [ ${INSTALL_K8S} == "ON" ]; then
    colorEcho ${BLUE} "自动部署开始"
    installK8SPackage || return $?
  else
    colorEcho ${RED} "手动部署请查看脚本当前目录README.md 文件进行部署"
  fi
  colorEcho ${RED} "访问k8s 集群 可以 source ${HOST_PATH}/environment.sh 或者 cp -pdr ${HOST_PATH}/kubeconfig/admin.kubeconfig /root/.kube/config 这样kubectl 可以直接访问K8S集群！"
  colorEcho ${RED} "手动部署请查看脚本当前目录README.md 文件进行部署"
  colorEcho ${RED} "添加node 节点 多IP 192.168.3.10,192.168.3.11, 以 192.168.3.10 IP 为例： 直接执行 ansible-playbook -i 192.168.3.10, ${PACKAGE_SYSCTL_FILE} ${IPTABLES_FILE} cni.yml ${RUNTIME_FILE} kube-ha-proxy.yml  kubelet.yml kube-proxy.yml --ssh-common-args=\"-o StrictHostKeyChecking=no\" ${ASK_PASS} "
  return 0
}
main
