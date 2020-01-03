##  grafana 部署
```
# 直接执行
kubectl apply -f .
# 导入 dashboards
cd dashboards 
# 修改import-dashboards.sh 改成自己域名或者IP+端口 然后执行import-dashboards.sh 脚本
#如果有导入错误的请手动导入错误文件
kubectl get pod -n monitoring | grep grafana
kubectl exec -ti grafana-k8s-5b4cb4b44-nmrkz /bin/sh
# 安装插件
grafana-cli plugins install grafana-piechart-panel
# kill 1 号进程重启grafana
```