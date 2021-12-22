# 创建命名空间
```
kubectl create namespace clusterstorage
```
# nfs storageClass 部署
```
# 修改storageclass-nfs.yaml server path 改成自己nfs 服务器配置
# 修改csi-nfs-controller.yaml csi-nfs-node.yaml  pods-mount-dir registration-dir socket-dir kubelet-registration-path 等参数 修改路径对应kubelet volume-plugin-dir 参数
# 部署nfs storageClass kubectl apply -f .
# 测试 能自己创建pvc 并成功写入文件 kubectl apply -f test/.
# service nfslock start
# systemctl enable nfslock.service
```
