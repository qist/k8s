# podman build 修改构建格式为dokcer 不然push 到harbor 报错500

```shell
export BUILDAH_FORMAT=docker
podman build -t harbor.xxxx.com/library/aliyun-exporter -f Dockerfile
podman push harbor.xxxx.com/library/aliyun-exporter
```
