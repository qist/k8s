# 创建命名空间
```
kubectl create namespace clusterstorage
```
#进入ceph 创建存储空间
```
ceph osd pool ls
```
#创建 pool
```
ceph osd pool create kube 50
```
#创建授权ceph
```
ceph auth get-or-create client.kube mon 'allow r' osd 'allow rwx pool=kube' -o kube.keyring
```
#测试kube.keyring 是否 可用
```
ceph -n client.kube --keyring=kube.keyring health
#[root@ceph-adm ~]# ceph -n client.kube --keyring=kube.keyring health
HEALTH_OK
ceph -n client.kube --keyring=kube.keyring osd pool ls
#[root@ceph-adm ~]# ceph -n client.kube --keyring=kube.keyring osd pool ls
rbd
kube
```
#获取key 
```
client.kube
ceph auth get-key client.kube 
#[root@ceph-adm ~]# ceph auth get-key client.kube 
AQApbtJd+5MpMxAApoLnIKuN74Cc3bJUgr7Xyg==
```
# csi rbd 部署
先部署vault
```
kubectl apply -f vault/*
```
# 修改csi-config-map.yaml  secret.yaml storageclass.yaml
# csi-config-map.yaml 跟 cephfs 公用的
```
# 然后部署 
kubectl apply -f .
```
