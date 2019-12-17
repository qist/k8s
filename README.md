```
########## mkdir -p /root/.kube
##########复制admin kubeconfig 到root用户作为kubectl 工具默认密钥文件
########## \cp -pdr /opt/aaa/kubeconfig/admin.kubeconfig /root/.kube/config
###################################################################################
##########  ansible 及ansible-playbook 单个ip ip结尾一点要添加“,”符号 ansible-playbook -i 192.168.0.1, xxx.yml
##########  source /opt/aaa/environment.sh 设置环境变量生效方便后期新增证书等
##########  etcd 部署 ansible-playbook -i "192.168.2.247","192.168.2.248","192.168.2.249" etcd.yml
##########  etcd EVENTS 部署 ansible-playbook -i "192.168.2.250","192.168.2.251","192.168.2.252", events-etcd.yml
##########  kube-apiserver 部署 ansible-playbook -i "192.168.2.247","192.168.2.248","192.168.2.249","192.168.2.250","192.168.2.251", kube-apiserver.yml 
##########  haproxy 部署 ansible-playbook -i "192.168.2.247","192.168.2.248","192.168.2.249","192.168.2.250","192.168.2.251", haproxy.yml
##########  keepalived 节点IP "192.168.2.247","192.168.2.248","192.168.2.249","192.168.2.250","192.168.2.251" 安装keepalived使用IP 如果大于三个节点安装keepalived 记得HA1_ID 唯一的也就是priority的值
##########  keepalived 也可以全部部署为BACKUP STATE_x 可以使用默认值 IFACE 网卡名字默认ens3 ROUTER_ID 全局唯一ID   HA1_ID为priority值  
##########  keepalived 部署 节点1 ansible-playbook -i 节点ip1, keepalived.yml -e IFACE=ens3 -e ROUTER_ID=HA1 -e HA1_ID=100 -e HA2_ID=110 -e HA3_ID=120 -e STATE_3=MASTER
##########  keepalived 部署 节点2 ansible-playbook -i 节点ip2, keepalived.yml -e IFACE=ens3 -e ROUTER_ID=HA2 -e HA1_ID=110 -e HA2_ID=120 -e HA3_ID=100 -e STATE_2=MASTER
##########  keepalived 部署 节点3 ansible-playbook -i 节点ip3, keepalived.yml -e IFACE=ens3 -e ROUTER_ID=HA3 -e HA1_ID=120 -e HA2_ID=100 -e HA3_ID=110 -e STATE_1=MASTER
##########  kube-controller-manager kube-scheduler  ansible-playbook -i "192.168.2.247","192.168.2.248","192.168.2.249","192.168.2.250","192.168.2.251", kube-controller-manager.yml kube-scheduler.yml
##########  部署完成验证集群 kubectl cluster-info  kubectl api-versions  kubectl get cs 1.16 kubectl 显示不正常 
##########  提交bootstrap 跟授权到K8S 集群 kubectl apply -f /opt/aaa/yaml/bootstrap-secret.yaml 
##########  提交授权到K8S集群 kubectl apply -f /opt/aaa/yaml/kubelet-bootstrap-rbac.yaml kubectl apply -f /opt/aaa/yaml/kube-api-rbac.yaml
##########  系统版本为centos7 或者 ubuntu18 请先升级 iptables ansible-playbook -i  要安装node ip列表, iptables.yml
##########  安装K8S node 使用kube-router ansible部署 ansible-playbook -i 要安装node ip列表 package.yml lxcfs.yml docker.yml kubelet.yml
##########  安装K8S node 使用 flannel 网络插件ansible部署ansible-playbook -i 要安装node ip列表 package.yml lxcfs.yml docker.yml kubelet.yml kube-proxy.yml
##########  部署自动挂载日期与lxcfs 到pod的 PodPreset  kubectl apply -f /opt/aaa/yaml/allow-lxcfs-tz-env.yaml -n kube-system  " kube-system 命名空间名字"PodPreset 只是当前空间生效所以需要每个命名空间执行
##########  查看node 节点是否注册到K8S kubectl get node kubectl get csr 如果有节点 kube-router 方式部署 kubectl apply -f /opt/aaa/yaml/kube-router.yaml 等待容器部署完成查看node ip a | grep kube-bridge
##########  flannel 网络插件部署 kubectl apply -f /opt/aaa/yaml/flannel.yaml 等待容器部署完成查看node 节点网络 ip a| grep flannel.1
##########  给 master ingress 添加污点 防止其它服务使用这些节点:kubectl taint nodes  k8s-master-01 node-role.kubernetes.io/master=:NoSchedule kubectl taint nodes  k8s-ingress-01 node-role.kubernetes.io/ingress=:NoSchedule
##########  calico 网络插件部署 50节点内 wget https://docs.projectcalico.org/v3.10/manifests/calico.yaml  大于50节点 wget https://docs.projectcalico.org/v3.10/manifests/calico-typha.yaml
########## 如果cni配置没放到默认路径请创建软链 ln -s /apps/cni/etc /etc/cni 同时修改yaml hostPath路径 同时修改CALICO_IPV4POOL_CIDR 参数为 10.80.0.0/12 CALICO_IPV4POOL_IPIP: Never 启用bgp模式
##########  windows 证书访问 openssl pkcs12 -export -inkey k8s-apiserver-admin-key.pem -in k8s_apiserver-admin.pem -out client.p12
########## kubectl proxy --port=8001 &  把kube-apiserver 端口映射成本地 8001 端口      
########## 查看kubelet节点配置信息 NODE_NAME="k8s-node-04"; curl -sSL "http://localhost:8001/api/v1/nodes/${NODE_NAME}/proxy/configz" | jq '.kubeletconfig|.kind="KubeletConfiguration"|.apiVersion="kubelet.config.k8s.io/v1beta1"' > kubelet_configz_${NODE_NAME}
```
