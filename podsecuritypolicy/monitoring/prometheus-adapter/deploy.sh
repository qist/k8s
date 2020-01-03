#!/bin/bash
cat << EOF | tee ${HOST_PATH}/cfssl/k8s/apiserver.json
{
  "CN": "apiserver",
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
         ${HOST_PATH}/cfssl/k8s/apiserver.json | \
         cfssljson -bare ./apiserver
cat << EOF | tee ./apiserver-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: volume-serving-cert
  name: volume-serving-cert
  namespace: monitoring
type: Opaque
data:
  apiserver.crt: `cat ./apiserver.pem|base64 | tr -d '\n'`
  apiserver.key: `cat ./apiserver-key.pem|base64 | tr -d '\n'`
---
EOF
