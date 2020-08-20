## prometheus 监控部署说明
```
additional-configs-secret.yaml 为注释自动发现监控使用 不需要每个写serviceMonitor 同时修改为支持自定义hpa
prometheus-Ingress.yaml 修改为自己的域名方便外部访问
prometheus-prometheus.yaml 添加外部存储 默认使用临时目录 添加etcd 外部监控的证书文件跟istio 监控证书
prometheus-secrets.yaml 是etcd istio 证书根据自己的情况修改 监控etcd 必须修改证书
```