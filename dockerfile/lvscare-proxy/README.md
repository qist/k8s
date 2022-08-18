# lvscare proxy 配置

```bash
# 下载二进制文件
wget https://github.com/labring/lvscare/releases/download/v1.1.3-beta.8/lvscare_1.1.3-beta.8_linux_amd64.tar.gz
tar -xvf lvscare_1.1.3-beta.8_linux_amd64.tar.gz

```

## 编译

```bash
# 编译docker镜像
docker build --network=host -t juestnow/lvscare-proxy:v1.1.3-beta.8-amd64 .
# 测试
docker run -d -e "vip=100.100.100.100" -e "K8S_VIP_PORT=6443" --net=host --privileged juestnow/lvscare-proxy:v1.1.3-beta.8-amd64 care --vs 100.100.100.100:6443 --rs 192.168.2.175:5443 --rs 192.168.2.176:5443 --rs 192.168.2.177:5443 --health-path / --health-schem https
# 提交仓库
docker push juestnow/lvscare-proxy:v1.1.3-beta.8-amd64

```