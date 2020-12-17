# rbd storageClass 部署
```
#进入ceph 创建存储空间
ceph osd pool ls
#创建 pool
ceph osd pool create kube 50
#创建授权ceph
ceph auth get-or-create client.kube mon 'allow r' osd 'allow rwx pool=kube' -o kube.keyring
#测试kube.keyring 是否 可用
ceph -n client.kube --keyring=kube.keyring health
#[root@ceph-adm ~]# ceph -n client.kube --keyring=kube.keyring health
HEALTH_OK
ceph -n client.kube --keyring=kube.keyring osd pool ls
#[root@ceph-adm ~]# ceph -n client.kube --keyring=kube.keyring osd pool ls
rbd
kube
#获取key base64
client.admin
ceph auth get-key client.admin | base64
#[root@ceph-adm ~]# ceph auth get-key client.admin | base64
QVFDcCtybGFsaU9XTGhBQWoyZTI1NUd1ZU9SSnl4NXpUeHFrWVE9PQ==
client.kube
ceph auth get-key client.kube | base64
#[root@ceph-adm ~]# ceph auth get-key client.kube | base64
QVFDMTY5ZGN1a2dETWhBQVpDY2hOQ09mY1lwWGZXMU5HRU4wSGc9PQ==
# 修改 secrets.yaml 改成自己获取值
# 修改class.yaml 改成自己ceph mon 地址
# 部署rbd storageClass kubectl apply -f .
# 测试 能自己创建pvc 并成功写入文件 kubectl apply -f test/.
```
