# 项目说明
```
变量说明
HOST_PORT: 监听端口
CP_HOSTS: 后端IP列表
BACKEND_PORT: 后端转发端口
docker run -tid --net=host -e CP_HOSTS=192.168.2.175,192.168.2.176,192.168.2.177 -e HOST_PORT=6443 BACKEND_PORT=5443 juestnow/haproxy-proxy:2.1.7
57590 端口监控端口
http://ip:57590/admin?stats 账号密码 admin
```