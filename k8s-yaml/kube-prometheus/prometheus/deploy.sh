#!/bin/bash
cat << EOF | tee ${HOST_PATH}/cfssl/k8s/cert-chain.json
{
  "CN": "cert-chain",
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
         ${HOST_PATH}/cfssl/k8s/cert-chain.json | \
         cfssljson -bare ./cert-chain
cat << EOF | tee ./prometheus-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: istio-certs
  name: istio-certs
  namespace: monitoring
type: Opaque
data:
  cert-chain.pem: `cat ./cert-chain.pem|base64 | tr -d '\n'`
  key.pem: `cat ./cert-chain-key.pem|base64 | tr -d '\n'`
  root-cert.pem: `cat ${HOST_PATH}/cfssl/pki/k8s/k8s-ca.pem |base64 | tr -d '\n'`
---
apiVersion: v1
kind: Secret
metadata:
  labels:
    k8s-app: etcd-certs
  name: etcd-certs
  namespace: monitoring
type: Opaque
data:
  etcd-ca.pem: `cat ${HOST_PATH}/cfssl/pki/etcd/etcd-ca.pem |base64 | tr -d '\n'`
  etcd-client.pem: `cat ${HOST_PATH}/cfssl/pki/etcd/etcd-client.pem |base64 | tr -d '\n'`
  etcd-client-key.pem: `cat ${HOST_PATH}/cfssl/pki/etcd/etcd-client-key.pem |base64 | tr -d '\n'`
EOF