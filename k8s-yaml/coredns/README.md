# 修改coredns 配置

```yaml
# Ubuntu 系统 配置网卡dns 服务ip   不能让CoreDNS的上游DNS服务器使用127.0.0.53,因为会导致死循环 或者修改prometheus :9153  forward . /etc/resolv.conf 改成外部IP 
apiVersion: v1
data:
  Corefile: |
    .:53 {
        errors
        health {
            lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
            pods insecure
            endpoint_pod_names
            fallthrough in-addr.arpa ip6.arpa
            ttl 30
        }
        prometheus :9153
        forward . 192.168.1.169:53
        cache 30
        reload
        loadbalance
    }
kind: ConfigMap
metadata:
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
  name: coredns
  namespace: kube-system
~
# __PILLAR__DNS__MEMORY__LIMIT__ 最大内存使用
# __PILLAR__DNS__DOMAIN__ 集群域名
# __PILLAR__DNS__SERVER__ SERVICE IP
# 使用一键脚本生成请 source environment.sh
export CLUSTER_DNS_DOMAIN="cluster.local"
export CLUSTER_DNS_SVC_IP="10.66.0.2"
sed -i -e "s/__PILLAR__DNS__DOMAIN__/${CLUSTER_DNS_DOMAIN}/" -e "s/__PILLAR__DNS__SERVER__/${CLUSTER_DNS_SVC_IP}/" -e "s/__PILLAR__DNS__MEMORY__LIMIT__/100Mi/" coredns.yaml
```
