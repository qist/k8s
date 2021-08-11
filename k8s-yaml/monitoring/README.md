# prometheus 配置 blackbox-exporter 配置 alertmanager 配置都会自动刷新不需要手动重载
支持 自定义 hpa 扩容
## prometheus 监控部署说明
prometheus 存储 现在使用临时存储 生产记得修改 prometheus.yaml 修改
### 创建命名空间
`kubectl create namespace monitoring`
### 创建etcd 证书secret
```
kubectl -n monitoring create secret generic etcd-certs \
--from-file=/opt/rocky/cfssl/pki/etcd/etcd-ca.pem \
--from-file=/opt/rocky/cfssl/pki/etcd/etcd-client.pem \
--from-file=/opt/rocky/cfssl/pki/etcd/etcd-client-key.pem
```
### 创建监控rule
```
# rule 为规则存放文件夹
kubectl -n monitoring create configmap prometheus-k8s-rulefiles --from-file rule
## 报警规则更新
# 删除监控报警规则
kubectl -n monitoring delete configmap prometheus-k8s-rulefiles
# 再次创建规则 实现报警规则更新
kubectl -n monitoring create configmap prometheus-k8s-rulefiles --from-file rule
```
### 部署 prometheus
```
# 进入prometheus 目录
# blackbox-exporter-files-discover.yaml 文件为监控外部站点配置文件
kubectl apply -f .
# rule 规则目录文件夹
```
部署custom-metrics-api 后在部署prometheus-adapter
### service 监控写法
```
# 集群 内部 Service 监控
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    app: prometheus-k8s
  name: prometheus-k8s
  annotations:
    prometheus.io/scrape: 'true' # 多端口 prometheus.io/port: '9090'  # 监控路径 prometheus.io/path: '/metrics' # 监控http协议 prometheus.io/scheme: 'http' 或者https
  namespace: monitoring
spec:
  ports:
  - name: web
    port: 9090
    targetPort: web
  selector:
    app: prometheus-k8s
  sessionAffinity: ClientIP
EOF
# 集群外部 Service 模式监控
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  annotations:
    prometheus.io/port: "10257"
    prometheus.io/scrape: "true"
    prometheus.io/scheme: "https"
  labels:
    k8s-app: kube-controller-manager
  name: kube-controller-manager
  namespace: monitoring
spec:
  clusterIP: None
  ports:
  - name: https-metrics
    port: 10257
    protocol: TCP
    targetPort: 10257
  sessionAffinity: None
  type: ClusterIP
---
apiVersion: v1
kind: Endpoints
metadata:
  labels:
    k8s-app: kube-controller-manager
  name: kube-controller-manager
  namespace: monitoring
subsets:
- addresses:
  - ip: 192.168.2.175
  - ip: 192.168.2.176
  - ip: 192.168.2.177
  ports:
  - name: https-metrics
    port: 10257
    protocol: TCP
EOF
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  annotations:
    prometheus.io/port: "10259"
    prometheus.io/scrape: "true"
    prometheus.io/scheme: "https"
  labels:
    k8s-app: kube-scheduler
  name: kube-scheduler
  namespace: monitoring
spec:
  clusterIP: None
  ports:
  - name: https-metrics
    port: 10259
    protocol: TCP
    targetPort: 10259
  sessionAffinity: None
  type: ClusterIP
---
apiVersion: v1
kind: Endpoints
metadata:
  labels:
    k8s-app: kube-scheduler
  name: kube-scheduler
  namespace: monitoring
subsets:
- addresses:
  - ip: 192.168.2.175
  - ip: 192.168.2.176
  - ip: 192.168.2.177
  ports:
  - name: https-metrics
    port: 10259
    protocol: TCP
EOF
# etcd 独立tls 监控
cat << EOF | kubectl apply -f -
---
apiVersion: v1
kind: Service
metadata:
  labels:
    k8s-app: etcd
  name: etcd
  namespace: monitoring
spec:
  clusterIP: None
  ports:
  - name: https-metrics
    port: 2379
    protocol: TCP
    targetPort: 2379
  sessionAffinity: None
  type: ClusterIP
---
apiVersion: v1
kind: Endpoints
metadata:
  labels:
    k8s-app: etcd
  name: etcd
  namespace: monitoring
subsets:
- addresses:
  - ip: 192.168.2.175
  - ip: 192.168.2.176
  - ip: 192.168.2.177
  ports:
  - name: https-metrics
    port: 2379
    protocol: TCP
EOF
```
### POD 监控写法
```
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    component: kube-apiserver-ha-proxy
    tier: control-plane
  annotations:
    prometheus.io/port: "8404"  # 多端口指定监控端口 prometheus.io/port: '8084'  # 监控路径 prometheus.io/path: '/metrics' # 监控http协议 prometheus.io/scheme: 'http' 或者https
    prometheus.io/scrape: "true"
  name: kube-apiserver-ha-proxy
  namespace: kube-system
spec:
  containers:
  - args:
    - "CP_HOSTS=192.168.2.175,192.168.2.176,192.168.2.177"
    image: docker.io/juestnow/nginx-proxy:1.21.0
    imagePullPolicy: IfNotPresent
    name: kube-apiserver-ha-proxy
    env:
    - name: CPU_NUM
      value: "4"
    - name: BACKEND_PORT
      value: "5443"
    - name: HOST_PORT
      value: "6443"
    - name: CP_HOSTS
      value: "192.168.2.175,192.168.2.176,192.168.2.177"
  hostNetwork: true
  priorityClassName: system-cluster-critical
status: {}
### daemonsets deployments statefulsets 写法
spec:
  selector:
    matchLabels:
      k8s-app: traefik
  template:
    metadata:
      creationTimestamp: null
      labels:
        k8s-app: traefik
      annotations:
        prometheus.io/port: '8080'  # 多端口指定监控端口 prometheus.io/port: '8080'  # 监控路径 prometheus.io/path: '/metrics' # 监控http协议 prometheus.io/scheme: 'http' 或者https
        prometheus.io/scrape: 'true'
```
### blackbox-exporter 集群内部监控注释方法

```
# service 写法 http 模式 监控

cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    app: prometheus-k8s
  name: prometheus-k8s
  annotations:
    prometheus.io/web: 'true' # 开启http 监控   # prometheus.io/tls: 'https' # 默认http  # 多端口指定监控端口 prometheus.io/port: '9090' 
    prometheus.io/healthz: "/-/healthy" #监控url
  namespace: monitoring
spec:
  ports:
  - name: web
    port: 9090
    targetPort: web
  selector:
    app: prometheus-k8s
  sessionAffinity: ClientIP
EOF
# service 写法 tcp 模式 监控
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    app: prometheus-k8s
  name: prometheus-k8s
  annotations:
    prometheus.io/tcp: 'true' # 开启tcp 监控 所以端口都会监控
  namespace: monitoring
spec:
  ports:
  - name: web
    port: 9090
    targetPort: web
  selector:
    app: prometheus-k8s
  sessionAffinity: ClientIP
EOF
# # service 写法 icmp 模式 监控
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    app: prometheus-k8s
  name: prometheus-k8s
  annotations:
    prometheus.io/icmp: 'true' # ping service name
  namespace: monitoring
spec:
  ports:
  - name: web
    port: 9090
    targetPort: web
  selector:
    app: prometheus-k8s
  sessionAffinity: ClientIP
EOF
### blackbox-exporter 集群内部ingresses监控注释方法 由于prometheus 不还不支持1.22 ingresses api 所以只能监控1.22版本一下ingresses
cat << EOF | kubectl apply -f -
kind: Ingress
apiVersion: networking.k8s.io/v1
metadata:
  name: prometheus-dashboard
  annotations:
    prometheus.io/probed: 'true' # 开启ingresses 监控
  namespace: monitoring
spec:
  rules:
    - host: prometheus.tycng.com
      http:
        paths:
          - pathType: ImplementationSpecific
            path: /
            backend:
              service: 
                name: prometheus-k8s
                port: 
                  number: 9090

EOF
```
### blackbox-exporter 集群外部监控
```
# 修改 blackbox-exporter-files-discover.yaml
kubectl apply -f blackbox-exporter-files-discover.yaml
# 会自动刷新
```