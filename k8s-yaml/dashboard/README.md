# kubernetes-dashboard 部署说明

新版dashboard 首先部署cert-manager安装

* [cert-manager安装](./cert-manager安装.md)

修改 登录过期时间

```yaml
# 找到 Deployment kubernetes-dashboard-api
          args:
            - --enable-insecure-login
            - --namespace=kubernetes-dashboard
            - --token-ttl=43200 # 添加过期时间
```

## 修改  dashboard ingress 打开kubernetes-dashboard.yaml 改成自己的域名

```text
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
    cert-manager.io/issuer: selfsigned
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - localhost
      secretName: kubernetes-dashboard-certs
  rules:
    - host: localhost
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kubernetes-dashboard-web
                port:
                  name: web
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: kubernetes-dashboard-api
                port:
                  name: api
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

#获取dashboard.kubeconfig 使用token   值
DASHBOARD_LOGIN_TOKEN=$(kubectl describe secret -n kube-system dashboard-admin-token | grep -E '^token' | awk '{print $2}')

# ${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem 改成自己的集群ca 文件路径  ${KUBE_APISERVER} api master ip 端口
echo ${DASHBOARD_LOGIN_TOKEN}
kubectl config set-cluster kubernetes \
  --certificate-authority=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=dashboard.kubeconfig
# 设置客户端认证参数，使用上面创建的 Token
kubectl config set-credentials dashboard_user \
  --token=${DASHBOARD_LOGIN_TOKEN} \
  --kubeconfig=dashboard.kubeconfig

# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=dashboard_user \
  --kubeconfig=dashboard.kubeconfig

# 设置默认上下文
kubectl config use-context default --kubeconfig=dashboard.kubeconfig
```