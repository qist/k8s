##   全局podsecuritypolicy 及 kubelet 创建server 证书 同时开启拓扑感知与服务路由
```
# 配置版本为K8S v1.17.0版本
# 此目录下面的全部已经配置好podsecuritypolicy 
# 可以参考官方文档
https://kubernetes.io/docs/concepts/policy/pod-security-policy/
# kubelet server 证书必须手动签发
kubectl get csr |grep system:node | grep Pending| while read name number; do     kubectl  certificate approve  $name ; done 
# 运行所有的pod 必须配置psp
# 放行整个集群 psp 配置pspall.yaml kubectl apply -f pspall.yaml 这样就不用每个pod 设置psp 
```