##  grafana 部署
```
# grafana-ingress 对外服务域名请修改文件 grafana-ingress.yaml
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
# 多环境 使用 environment-dashboards 目录下展示
# kill 1 号进程重启grafana
# mysql 监控请添加参数  --collect.perf_schema.file_events --collect.perf_schema.eventswaits --collect.perf_schema.indexiowaits --collect.perf_schema.tableiowaits --collect.perf_schema.tablelocks --collect.info_schema.processlist
```