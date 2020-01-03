#!/bin/bash
cat << EOF | tee ./dashboard-tls-cert-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: dashboard-tls-cert
  namespace: kubernetes-dashboard
type: Opaque
data:
  tls.crt: `cat 域名证书文件地址|base64 | tr -d '\n'`
  tls.key: `cat 域名密钥文件地址|base64 | tr -d '\n'`
EOF