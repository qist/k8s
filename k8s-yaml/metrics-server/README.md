##  metrics-server 部署说明
```
# autotls 目录自动生成证书
# tls目录 手动签发证书 签发证书并生成secrets  deploy.sh 如果不是使用脚本生成并安装的请打开deploy.sh 修改变量改成自己环境
# metrics-server-deployment.yaml image: juestnow/metrics-server-amd64:v0.3.6 可以修改成自己私有仓库
# 不使用自动生成secrets yaml 手动创建secrets kubectl -n kube-system create secret generic metrics-server-certs --from-file=metrics-server-key.pem --from-file=metrics-server.pem
# 部署 metrics-server  kubectl apply -f .
# kubectl get pod  -n  kube-system | grep metrics-server kubectl get service  -n  kube-system | grep metrics-server  
```