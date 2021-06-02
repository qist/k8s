#!/bin/bash
cat << EOF | tee ${HOST_PATH}/cfssl/k8s/metrics-server.json
{
  "CN": "metrics-server",
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
         ${HOST_PATH}/cfssl/k8s/metrics-server.json | \
         cfssljson -bare ./metrics-server
cat ${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem >> ./metrics-server.pem
cat << EOF | tee ./metrics-server-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server-certs
  namespace: kube-system
type: Opaque
data:
  metrics-server.pem: `cat ./metrics-server.pem|base64 | tr -d '\n'`
  metrics-server-key.pem: `cat ./metrics-server-key.pem|base64 | tr -d '\n'`
EOF