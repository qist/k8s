# cert-manager 安装

cert-manager 是一种自动执行证书管理的工具

官网：https://cert-manager.io/

## 安装cert-manager：

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
# crds 安装
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.crds.yaml
# 安装  cert-manager
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.13.3
```

## 创建自签CA

```yaml
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-issuer
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: selfsigned-ca
  namespace: cert-manager
spec:
  isCA: true
  commonName: selfsigned-ca
  secretName: root-secret
  privateKey:
    algorithm: ECDSA
    size: 256
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
    group: cert-manager.io
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ca-issuer
spec:
  ca:
    secretName: root-secret
EOF
```

说明：

issuer与clusterissuer两个签发资源，issuer只能在同一命名空间内签发证书，clusterissuer可以在所有命名空间内签发证书。如果是issuer，则证书secret所属的namspace应与issuer一致；如果是clusterissuer，则证书所属的namespace应与cert-manager安装的namespace一致。

上面用的是cert-manager的自签证书做为CA，也可以自已定义个CA放在secret里，然后做为clusterissuer来进行后续的签发。

应用后使用如下命令查看clusterissuer与certificate：

`kubectl get clusterissuer`

`kubectl get certificate -A`

状态READY为true说明签发正常，否则可以使用describe查看错误原因。

## 测试

```yaml
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Service
metadata:
  labels:
    app: nginx
  name: nginx-test
spec:
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 80
  selector:
    app: nginx
  type: ClusterIP
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test
  labels:
    app: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
EOF

# 新建ingress
cat <<EOF | kubectl apply -f -
kind: Ingress
apiVersion: networking.k8s.io/v1
metadata:
  name: nginx-test
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: ca-issuer
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        -  www.test.com
      secretName: test-tls
  rules:
    - host:  www.test.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx-test
                port:
                  name: http
EOF
```

在注解中定义cert-manager.io/cluster-issuer，并指定clusterissuer的名称；
如为issuer则使用cert-manager.io/issuer注解。
spec.tls.hosts.secretName定义secret的名称，自动签发的证书会写在这个secret里。

应用后，会发现新生成secret：

```txt
root@Qist:~# kubectl get secrets
NAME       TYPE                DATA   AGE
test-tls   kubernetes.io/tls   3      84s
```

手动签发certificate，ingress直接使用这个secret（关闭注解）

```yaml
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-tls
spec:
  dnsNames:
  - www.test.com
  issuerRef:
    group: cert-manager.io
    kind: ClusterIssuer
    name: ca-issuer
  secretName: test-tls
  duration: 87600h #10年
  usages:
  - digital signature
  - key encipherment
EOF
```
具体参数：https://cert-manager.io/docs/reference/api-docs/#cert-manager.io/v1.CertificateSpec

## 卸载cert-manager

```bash
# 查看 crds
kubectl get Issuers,ClusterIssuers,Certificates,CertificateRequests,Orders,Challenges --all-namespaces
# 卸载 cert-manager
helm --namespace cert-manager delete cert-manager
# 删除命名空间
kubectl delete namespace cert-manager
# vX.Y.Z 改成集群对应版本号 删除crds
kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/vX.Y.Z/cert-manager.crds.yaml  
# 删除 webhook 
kubectl delete apiservice v1beta1.webhook.cert-manager.io
```