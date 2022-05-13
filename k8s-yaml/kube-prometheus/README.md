# prometheus 监控部署说明

```yaml
请先部署setup 等待pod 启动完成在部署其它服务
custom-metrics-api 要先于prometheus-adapter 部署
prometheus-serviceMonitor 文件夹是常见几个serviceMonitor 部署
blackbox-exporter 监控集群的service ingresses 自动发现
service  添加  annotations:
    prometheus.io/probe: 'true' 
--------------------------
kind: Service
apiVersion: v1
metadata:
  name: blackbox-exporter
  namespace: monitoring
  labels:
    app.kubernetes.io/instance: blackbox
    app.kubernetes.io/name: blackbox-exporter
  annotations:
    prometheus.io/probe: 'true'
spec:
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 9115
  selector:
    app.kubernetes.io/instance: blackbox
    app.kubernetes.io/name: blackbox-exporter
  type: ClusterIP
---------------------------------------------
ingresses 方式 添加   annotations:
    prometheus.io/probed: 'true'
---------------------------------------------
kind: Ingress
apiVersion: extensions/v1beta1
metadata:
  name: blackbox-exporter
  namespace: monitoring
  annotations:
    prometheus.io/probed: 'true'
spec:
  rules:
    - host: blackbox.tycng.com
      http:
        paths:
          - path: /
            backend:
              serviceName: blackbox-exporter
              servicePort: http
# blackbox-exporter-files-discover.yaml 批量 站点监控配置文件
```
