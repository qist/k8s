# nfs storageClass 部署
```
# 修改nfs-deployment.yaml server path 改成自己nfs 服务器配置
# 修改storageClass.yaml 改成自己喜欢的名字 修改是否为默认存储  storageclass.kubernetes.io/is-default-class: "true"   # true|false
# 部署nfs storageClass kubectl apply -f .
# 测试 能自己创建pvc 并成功写入文件 kubectl apply -f test/.
```
