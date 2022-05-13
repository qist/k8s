# istio 版本部署

## 使用Helm v3 版本部署

## 下载 Helm v3.0.2

```shell
wget  https://get.helm.sh/helm-v3.0.2-linux-amd64.tar.gz
```

## 解压下载文件

```shell
tar -xv helm-v3.0.2-linux-amd64.tar.gz
```

## 复制文件到/bin 目录

```shell
cp ./linux-amd64/helm /bin
```

## 下载最新版本

```shell
#curl -L https://istio.io/downloadIstio | sh -
```

## 指定版本下载

```shell
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.11.2 TARGET_ARCH=x86_64 sh -
```

## 创建命名空间

```shell
kubectl create namespace istio-system
```

## 创建crd

```shell
helm install istio-base manifests/charts/base -n istio-system
```

## 部署istiod

```shell
helm install istiod manifests/charts/istio-control/istio-discovery \
--set global.hub="docker.io/istio" \
--set global.tag="1.11.2" \
--set istio_cni.enabled=true   \
--set global.proxy.clusterDomain="cluster.local" \
--set global.proxy.accessLogFile="/dev/stdout" \
--set global.proxy.logLevel="info" \
--set global.disablePolicyChecks=false \
--set global.proxy.autoInject=disabled \
-n istio-system --timeout=300s --no-hooks 
```

## 部署cni

```shell
helm install istio-cni manifests/charts/istio-cni --namespace istio-system \
--set cni.cniBinDir=/opt/cni/bin \
--set cni.cniConfDir=/etc/cni/net.d \
--set cni.excludeNamespaces={"istio-system,monitoring,kubernetes-dashboard,kube-system,clusterstorage,ingress-nginx"}
```

## 部署 ingress

```shell
helm install istio-ingress manifests/charts/gateways/istio-ingress \
--set global.hub="docker.io/istio" \
--set global.tag="1.11.2" \
--set gateways.istio-ingressgateway.type=ClusterIP \
-n istio-system
```

## 添加namespace标签

```shell
kubectl label namespace default istio-injection=enabled
```

## 查询添加标签

```shell
 kubectl get namespace -L istio-injection
 ```

## 其它插件安装目录

* [添加apm插件](./addons)

```shell
# 修改 kiali.yaml
    external_services:
      custom_dashboards:
        enabled: true
      grafana:
        enabled: true
        in_cluster_url: "http://grafana:3000"
        url: "http://monitor.tycng.com/"  # 改成自己的grafana 地址 外网能访问的
kubectl apply -f ./addons/.
```

grafana dashboard 导入 IstioWasmExtensionDashboard 不支持containerd 运行时

* [dashboard](./addons/dashboard)

## 测试项目

* [测试项目](./test)

## 卸载

```shell  
helm ls -n istio-system
helm delete istio-egress -n istio-system
helm delete istio-ingress -n istio-system
helm delete istiod -n istio-system
helm delete istio-cni -n istio-system
helm delete istio-base -n istio-system
kubectl delete namespace istio-system 
```

## 删除crd

```shell
kubectl get crd | grep --color=never 'istio.io' | awk '{print $1}' \
    | xargs -n1 kubectl delete crd
```
