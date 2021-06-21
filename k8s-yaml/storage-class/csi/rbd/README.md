# csi rbd 部署
先部署vault
```
kubectl apply -f vault/*
```
# 修改csi-config-map.yaml  secret.yaml
# csi-config-map.yaml 跟 cephfs 公用的
```
# 然后部署 
kubectl apply -f .
```
