##  prometheus 部署说明
```
# 签发证书并生成secrets 
# deploy.sh 如果不是使用脚本生成并安装的请打开deploy.sh 修改变量改成自己环境
# 修改prometheus-Ingress.yaml 改成自己的Ingress 域名
# 添加节点数prometheus-k8s.yaml replicas: 3 修改cpu 内存 存储大小 这部署同时支持 hpa 自定义参数扩缩容，同时整合istio支持 不再需要部署prometheus-operator
# 部署 prometheus  kubectl apply -f .
# kubectl get pod  -n  monitoring | grep prometheus-k8s kubectl get service  -n  monitoring | grep prometheus-k8s
# monitor 文件夹是etcd Kube-Scheduler Kube-Controller-Manager Kubelet 监控yaml 二进制方式请修改IP Kubelet 以service 方式发现监控所以使用外部DaemonSet方式部署的应用这里以node-exporter为当然也可以使用网络插件来做
# 可以使用kube-prometheus 项目的rules 文件及grafana dashboard 文件
# 添加监控外部节点
vi Jenkins.yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    k8s-app: jenkins
  name: jenkins
  namespace: monitoring
  annotations:
    prometheus.io/port: "8080"
    prometheus.io/path: "/prometheus" # 监控路径一般默认 metrics
    prometheus.io/scrape: "true"
    #prometheus.io/scheme: "https" # 添加https 业务见面支持 默认http
spec:
  clusterIP: None
  ports:
  - name: api
    port: 8080
    protocol: TCP
    targetPort: 8080
  sessionAffinity: None
  type: ClusterIP
---
apiVersion: v1
kind: Endpoints
metadata:
  labels:
    k8s-app: jenkins
  name: jenkins
  namespace: monitoring
subsets:
- addresses:
  - ip: 192.168.1.121
  - ip: 192.168.2.11 
  ports:
  - name: api
    port: 8080
    protocol: TCP
```