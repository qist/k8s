##  alertmanager 部署
```
# 减少或者增加节点请修改 replicas: 3 节点数  args --cluster.peer=alertmanager-main-0.alertmanager-operated.monitoring.svc:6783 减少请删除 peer 增加就添加peer 
# 配置文件使用 base64 加密更具自己修改然后加密： `cat alertmanager.yaml|base64 | tr -d '\n'`
kubectl apply -f alertmanager.yaml
```