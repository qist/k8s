## 修改coredns 配置
```
# __PILLAR__DNS__MEMORY__LIMIT__ 最大内存使用
# __PILLAR__DNS__DOMAIN__ 集群域名
# __PILLAR__DNS__SERVER__ SERVICE IP
# 使用一键脚本生成请 source environment.sh
export CLUSTER_DNS_DOMAIN="cluster.local"
export CLUSTER_DNS_SVC_IP="10.66.0.2"
sed -i -e "s/__PILLAR__DNS__DOMAIN__/${CLUSTER_DNS_DOMAIN}/" -e "s/__PILLAR__DNS__SERVER__/${CLUSTER_DNS_SVC_IP}/" -e "s/__PILLAR__DNS__MEMORY__LIMIT__/500Mi/" coredns.yaml
```