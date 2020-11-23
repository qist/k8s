#!/bin/bash
cat << EOF | tee ${HOST_PATH}/cfssl/k8s/kubernetes-dashboard.json
{
  "CN": "kubernetes-dashboard",
  "hosts": [""], 
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
            "C": "CN",
            "ST": "$CERT_ST",
            "L": "$CERT_L",
            "O": "$CERT_O",
            "OU": "$CERT_OU"
    }
  ]
}
EOF
cfssl gencert \
        -ca=${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem \
        -ca-key=${HOST_PATH}/cfssl/pki/k8s/k8s-ca-key.pem \
        -config=${HOST_PATH}/cfssl/ca-config.json \
        -profile=${CERT_PROFILE} \
         ${HOST_PATH}/cfssl/k8s/kubernetes-dashboard.json | \
         cfssljson -bare ./kubernetes-dashboard
cat << EOF | tee ./kubernetes-dashboard-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard-certs
  namespace: kubernetes-dashboard
type: Opaque
data:
  dashboard.crt: `cat ./kubernetes-dashboard.pem|base64 | tr -d '\n'`
  dashboard.key: `cat ./kubernetes-dashboard-key.pem|base64 | tr -d '\n'`
EOF