# csi cephfs 部署 支持ceph 14 及以上版本 低于建议部署cephfs-provisioner
配置参考
https://github.com/ceph/ceph-csi/blob/devel/docs/deploy-cephfs.md
https://github.com/ceph/ceph-csi/blob/devel/docs/capabilities.md
# 修改csi-config-map.yaml  secret.yaml
# csi-config-map.yaml 跟 rbd 公用的
```
# 然后部署 
kubectl apply -f .
```
