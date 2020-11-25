# 项目说明
```
变量说明
HOST_PORT: 监听端口
CP_HOSTS: 后端IP列表
BACKEND_PORT: 后端转发端口
docker run -tid --net=host -e "CP_HOSTS=192.168.2.175,192.168.2.176,192.168.2.177" -e "HOST_PORT=6443" -e "BACKEND_PORT=5443" juestnow/nginx-proxy:1.19.5
```
# 添加外部访问健康检测
```
8404 端口监控端口
http://ip:8404/stats
prometheus 监控
http://ip:8404/metrics

- job_name: 'nginx'
  static_configs:
  - targets: ['ip:8404']
```