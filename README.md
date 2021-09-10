# 项目说明
### YAMLFormatspecification  项目 K8S yaml 参数说明

### containerd K8S 容器运行时部署 ansible 模式部署

### dockerfile 一些常见的dockerfile 文件

### ipv4andipv6 K8S 双栈部署脚本 生成ansible 可部署脚本

### k8s-kernel-sysctl K8S 宿主机相关优化

### k8s-yaml K8S 一些常规yaml
 
### kata-containers kata-containers ansible 部署脚本

### k8s-install.sh 一键自动ansible 部署 K8S 集群支持1.15及以上的版本

### kubens 命名空间切换脚本

# 配置污点
#kubectl taint nodes  k8s-ingress-01 node-role.kubernetes.io/ingress=:NoSchedule 
#kubectl taint nodes  k8s-ingress-02 node-role.kubernetes.io/ingress=:NoSchedule
# 创建 label 不创建是不能部署的或者删除yaml 文件 nodeSelector项
#kubectl label nodes k8s-ingress-01  ingress=yes
#kubectl label nodes k8s-ingress-02  ingress=yes
