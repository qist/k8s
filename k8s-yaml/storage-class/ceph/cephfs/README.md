# cephfs storageClass 部署
```
# 获取ceph secret  base64
ceph auth get-key client.admin | base64
# [root@ceph-adm ~]# ceph auth get-key client.admin | base64
QVFDcCtybGFsaU9XTGhBQWoyZTI1NUd1ZU9SSnl4NXpUeHFrWVE9PQ==
# 修改secret.yaml 改成自己获取 ceph secret
# 修改class.yaml  改成自己ceph mon 服务器地址
# 部署cephfs storageClass kubectl apply -f .
# 测试 能自己创建pvc 并成功写入文件 kubectl apply -f test/.
```
