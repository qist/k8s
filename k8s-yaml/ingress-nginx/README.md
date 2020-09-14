##  ingress-nginx
```
# ingress-nginx-ipv4.yaml 支持 1.16 及以上版本
# ingress-nginx-ipv6.yaml 双栈 集群访问IPV6 使用
# 官方项目地址: https://github.com/kubernetes/ingress-nginx/blob/master/deploy/static/provider/baremetal/deploy.yaml
# 创建测项目
#  部署一个应用
kubectl create deployment myip --image=cloudnativelabs/whats-my-ip 
# 暴露端口
kubectl expose deployment myip --port=8080 --target-port=8080
# 创建 Ingress
cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: myip
spec:
  ingressClassName: nginx # 1.18 以上使用
  rules:
  - host: myip.qql.com
    http:
      paths:
      - path: /
        pathType: Prefix # 1.18 以上使用
        backend:
          serviceName: myip 
          servicePort: 8080
EOF
```

