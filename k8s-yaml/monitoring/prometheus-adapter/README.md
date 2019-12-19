##  prometheus-adapter 部署说明
```
# 签发证书并生成secrets 
# deploy.sh 如果不是使用脚本生成并安装的请打开deploy.sh 修改变量改成自己环境
# 如果是kube17号版本请 mv prometheus-adapter-apiService.yaml prometheus-adapter-apiService.yaml.bak 如果使用adapter 提供metrics.k8s.io 就会获取不到pod 数据所以重名文件不执行不影响自定义hpa
# 部署 prometheus  kubectl apply -f .
# kubectl get pod  -n  monitoring | grep prometheus-adapter kubectl get service  -n  monitoring | grep prometheus-adapter
# 测试自定义监控HPA test目录有测试项目
```