# 基础镜像
FROM alpine

# 作者信息
LABEL MAINTAINER="iptables Docker Maintainers 87984115@qq.com"

# 修改源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装ca 证书
RUN apk update && \
    apk add --no-cache ca-certificates iptables && \
    rm -rf /var/cache/apk/*

ADD lvscare /usr/bin/lvscare
ADD lvscare-proxy /usr/bin/lvscare-proxy

#添加执行权限
RUN  chmod +x /usr/bin/lvscare \
     && chmod +x /usr/bin/lvscare-proxy

STOPSIGNAL SIGTERM

ENTRYPOINT ["/usr/bin/lvscare-proxy"]