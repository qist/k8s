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
# 转发 kubernetes-dashboard  1.18 版本以下写法
cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: HTTPS
    nginx.ingress.kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/use-regex: "true"
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  rules:
  - host: dashboard.test.com
    http:
      paths:
      - backend:
          serviceName: kubernetes-dashboard
          servicePort: 443
  tls:
  - secretName: tls-cert
EOF
# 转发 kubernetes-dashboard  1.18 版本以上写法
cat << EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: HTTPS
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/use-regex: "true"
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
spec:
  ingressClassName: nginx
  rules:
  - host: dashboard.test.com
    http:
      paths:
      - backend:
          serviceName: kubernetes-dashboard
          servicePort: 443
        pathType: ImplementationSpecific
  tls:
  - secretName: tls-cert
EOF
```

