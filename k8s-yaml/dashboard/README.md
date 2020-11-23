##  kubernetes-dashboard 部署说明
```
# autotls 文件夹官方yaml tls 文件夹需要自签名证书
# 签发证书并生成secrets 
# deploy.sh 如果不是使用脚本生成并安装的请打开deploy.sh 修改变量改成自己环境
# 创建Ingress-secret Ingress-secret.sh 方便办公网络访问kubernetes-dashboard 一定要使用访问 使用Traefik 提供Ingress 服务 修改Ingress-secret.sh tls.crt 路径  tls.key 路径
# 修改TraefikIngress.yaml host改成自己的域名
# 部署 kubernetes-dashboard kubectl apply -f .
# kubectl get pod  -n  kubernetes-dashboard | grep kubernetes-dashboard kubectl get service  -n  kubernetes-dashboard | grep kubernetes-dashboard 
# 执行dashboard-kubeconfig.sh 生成登陆kubeconfig 文件 几个修改证书路径
```