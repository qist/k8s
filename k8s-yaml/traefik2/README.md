##  traefik 2版本部署
```
# 配置污点
#kubectl taint nodes  k8s-ingress-01 node-role.kubernetes.io/ingress=:NoSchedule 
#kubectl taint nodes  k8s-ingress-02 node-role.kubernetes.io/ingress=:NoSchedule
# 创建 label 不创建是不能部署的或者删除yaml 文件 nodeSelector项
#kubectl label nodes k8s-ingress-01  ingress=yes
#kubectl label nodes k8s-ingress-02  ingress=yes
# 修改 traefik-dashboard.yaml 改成自己的域名
# 修改 traefik-secret.yaml 添加外部域名证书 与nginx 证书一样
# 部署api 及 rbac
kubectl apply -f .
# 部署 链路跟踪与traefik 服务 如果链路跟踪外部已经部署好了可以使用外部url 记得修改traefik-daemonset-xxx-https.yaml Zipkin与jaeger
# 选择一个进行部署 进入对应目录
kubectl apply -f .
# 粘性会话配置
---
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: prometheus
  namespace: monitoring
spec:
  entryPoints:
    - web
  routes:
  - match: Host(`prometheus.tycng.com`)
    kind: Rule
    services:
    - name: prometheus-k8s
      port: 9090
      # 配置粘性会话 删除就取消粘性会话
      sticky: 
        cookie: {}
      passHostHeader: true
      responseForwarding:
        flushInterval: 100ms
```