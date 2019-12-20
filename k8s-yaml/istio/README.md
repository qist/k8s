##  istio 版本部署
```
# 使用Helm v3 版本部署
# 下载 Helm v3.0.2 
wget  https://get.helm.sh/helm-v3.0.2-linux-amd64.tar.gz
# 解压下载文件
tar -xv helm-v3.0.2-linux-amd64.tar.gz
# 复制文件到/bin 目录
cp ./linux-amd64/helm /bin
# 下载istio 
curl -L https://istio.io/downloadIstio | sh -
# 等待下载完成 现在版本是1.4.2
cd istio-1.4.2
# 创建命名空间
kubectl apply -f install/kubernetes/namespace.yaml
# istio api
helm install install/kubernetes/helm/istio-init --name-template istio-init --namespace istio-system
#查询api 是否安装
kubectl get crds | grep 'istio.io' | wc -l
root@Qist:istio-1.4.2# kubectl get crds | grep 'istio.io' | wc -l
23 
vim install/kubernetes/helm/istio/charts/gateways/values.yaml
#修改gateways values.yaml 文件 删除nodePort 当然也可不用删除
#参数gateways.istio-ingressgateway.type=NodePort 
#参数gateways.istio-ingressgateway.type=ClusterIP 必须删除nodePort
vim install/kubernetes/helm/istio/charts/gateways/templates/service.yaml
#添加 clusterIP: None # 方便暴露其它tcp 端口
  clusterIP: None
  ports:
# 创建prometheus 
cat <<EOF | kubectl create -f -
kind: Service
apiVersion: v1
metadata:
  name: prometheus 
  namespace: istio-system
spec:
  type: ExternalName
  sessionAffinity: None
  externalName: prometheus-k8s.monitoring.svc.cluster.local
EOF
# 安装istio cniBinDir  cniConfDir 跟部署node节点目录一致
helm install  install/kubernetes/helm/istio --name-template istio --namespace istio-system --timeout=300s  \
--set gateways.istio-ingressgateway.type=ClusterIP   \
--set gateways.istio-egressgateway.enabled=true \
--set mixer.policy.enabled=true \
--set prometheus.enabled=false \
--set tracing.enabled=true \
--set tracing.ingress.enabled=true \
--set tracing.ingress.hosts={"tracing.tycng.com"} \
--set tracing.contextPath=/ \
--set kiali.enabled=true \
--set kiali.ingress.enabled=true \
--set kiali.ingress.hosts={"kiali.tycng.com"} \
--set kiali.contextPath=/ \
--set kiali.dashboard.viewOnlyMode=true \
--set kiali.dashboard.grafanaURL=http://monitor.tycng.com \
--set kiali.dashboard.jaegerURL=http://tracing.tycng.com \
--set kiali.createDemoSecret=true \
--set istio_cni.enabled=true   \
--set istio-cni.cniBinDir=/apps/cni/bin   \
--set istio-cni.cniConfDir=/apps/cni/etc/net.d   \
--set istio-cni.excludeNamespaces={"istio-system,monitoring,kubernetes-dashboard,kube-system"}  \
--set global.proxy.clusterDomain="cluster.local" \
--set global.proxy.accessLogFile="/dev/stdout" \
--set global.proxy.logLevel="info" \
--set global.disablePolicyChecks=false \
--set global.proxy.autoInject=disabled
# 添加namespace标签
kubectl label namespace default istio-injection=enabled
# 查询添加标签
 kubectl get namespace -L istio-injection
# cni 部署
helm install install/kubernetes/helm/istio-cni --name-template istio-cni --namespace istio-system \
--set cniBinDir=/apps/cni/bin \
--set cniConfDir=/apps/cni/etc/net.d   \
--set excludeNamespaces={"istio-system,monitoring,kubernetes-dashboard,kube-system"}
```
##  istio 更新
```
#检查是否安装 istio-cni  插件
helm status istio-cni --namespace istio-system
#由于istio-cni 安装在非kube-system命名空间 先卸载istio-cni
helm uninstall istio-cni --namespace istio-system
# cni 部署
helm install install/kubernetes/helm/istio-cni --name-template istio-cni --namespace istio-system \
--set cniBinDir=/apps/cni/bin \
--set cniConfDir=/apps/cni/etc/net.d   \
--set excludeNamespaces={"istio-system,monitoring,kubernetes-dashboard,kube-system"}
# 升级istio-init
helm upgrade --install istio-init install/kubernetes/helm/istio-init  --namespace istio-system --force
# 升级istio
helm upgrade --install istio install/kubernetes/helm/istio --namespace istio-system --timeout=300s  \
--set gateways.istio-ingressgateway.type=ClusterIP   \
--set gateways.istio-egressgateway.enabled=true \
--set mixer.policy.enabled=true \
--set prometheus.enabled=false \
--set tracing.enabled=true \
--set tracing.ingress.enabled=true \
--set tracing.ingress.hosts={"tracing.tycng.com"} \
--set tracing.contextPath=/ \
--set kiali.enabled=true \
--set kiali.ingress.enabled=true \
--set kiali.ingress.hosts={"kiali.tycng.com"} \
--set kiali.contextPath=/ \
--set kiali.dashboard.viewOnlyMode=true \
--set kiali.dashboard.grafanaURL=http://monitor.tycng.com \
--set kiali.dashboard.jaegerURL=http://tracing.tycng.com \
--set kiali.createDemoSecret=true \
--set istio_cni.enabled=true   \
--set istio-cni.cniBinDir=/apps/cni/bin   \
--set istio-cni.cniConfDir=/apps/cni/etc/net.d   \
--set istio-cni.excludeNamespaces={"istio-system,monitoring,kubernetes-dashboard,kube-system"}  \
--set global.proxy.clusterDomain="cluster.local" \
--set global.proxy.accessLogFile="/dev/stdout" \
--set global.proxy.logLevel="info" \
--set global.disablePolicyChecks=false \
--set global.proxy.autoInject=disabled
# 替换tracing 跟踪器为zipkin
添加--set tracing.provider=zipkin \
```

