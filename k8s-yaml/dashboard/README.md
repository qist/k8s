# kubernetes-dashboard 部署说明

新版dashboard 首先部署cert-manager安装

* [cert-manager安装](./cert-manager安装.md)

# Add kubernetes-dashboard repository
```bash
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
```
# Deploy a Helm Release named "kubernetes-dashboard" using the kubernetes-dashboard chart
```bash
helm upgrade --install kubernetes-dashboard \
             kubernetes-dashboard/kubernetes-dashboard \
             --create-namespace \
             --namespace kubernetes-dashboard \
             --set kong.enabled=false

# 如果要安装kong 就删除--set kong.enabled=false
```

```yaml
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: kubernetes-issuer
  namespace: kubernetes-dashboard
spec:
  selfSigned: {}
EOF
```

## 修改  dashboard ingress 创建改成自己的域名

```bash
kubectl apply -f - <<EOF
kind: Ingress
apiVersion: networking.k8s.io/v1
metadata:
  name: kubernetes-dashboard
  namespace: kubernetes-dashboard
  labels:
    app.kubernetes.io/name: nginx-ingress
    app.kubernetes.io/part-of: kubernetes-dashboard
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: kubernetes-issuer
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - dashboard.tycng.com
      secretName: kubernetes-dashboard-certs
  rules:
    - host: dashboard.tycng.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kubernetes-dashboard-web
                port:
                  name: web
          - path: /api/v1/login
            pathType: Prefix
            backend:
              service:
                name: kubernetes-dashboard-auth
                port:
                  name: auth   
          - path: /api/v1/csrftoken/login
            pathType: Prefix
            backend:
              service:
                name: kubernetes-dashboard-auth
                port:
                  name: auth   
          - path: /api/v1/me
            pathType: Prefix
            backend:
              service:
                name: kubernetes-dashboard-auth
                port:
                  name: auth          
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: kubernetes-dashboard-api
                port:
                  name: api
          - path: /metrics
            pathType: Prefix
            backend:
              service:
                name: kubernetes-dashboard-api
                port:
                  name: api
EOF
```

## 创建登录kubeconfig

```bash
#创建 用户
kubectl create sa dashboard-admin -n kube-system
# 授权用户 访问权限
kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin

# 1.24及以上版本使用
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: dashboard-admin-token
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: dashboard-admin
type: kubernetes.io/service-account-token
EOF

#获取dashboard 使用token   值
kubectl describe secret -n kube-system dashboard-admin-token | grep -E '^token' | awk '{print $2}'
