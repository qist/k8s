# 基础镜像
FROM alpine

# 作者信息
LABEL MAINTAINER="qist Docker Maintainers 87984115@qq.com"

# 修改源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装ca 证书
RUN apk update && \
    apk add --no-cache ca-certificates 

# 设置环境变量

ENV HAPROXY_VERSION 2.5.4
ENV HAPROXY_URL http://www.haproxy.org/download/2.5/src/haproxy-2.5.4.tar.gz

# 代理
# ENV http_proxy http://192.168.0.151:7890
# ENV https_proxy http://192.168.0.151:7890
# 工作目录
WORKDIR /tmp

# 编译安装HAPROXY
RUN HAPROXY_CONFIG="\
     TARGET="linux-musl" \
     USE_PCRE=1 \
     USE_PCRE_JIT=1 \
     USE_OPENSSL=1 \
     USE_ZLIB=1 \
     USE_REGPARM=1 \
     USE_LINUX_TPROXY=1 \
     USE_CPU_AFFINITY=1 \
     DEFINE=-DTCP_USER_TIMEOUT=18 \
     EXTRA_OBJS="addons/promex/service-prometheus.o" \
     PREFIX=/usr \
     " \
     && apk  add  --no-cache --virtual .build-deps \
        gcc \
		libc-dev \
		linux-headers \
		pcre-dev \
		make \
		openssl \
		openssl-dev \
		pcre2-dev \
		readline-dev \
		tar \
		zlib-dev \
        curl \
        git \
        cmake \
        g++ \
        && curl -fSL "$HAPROXY_URL" -o /tmp/haproxy-${HAPROXY_VERSION}.tar.gz \
        && cd /tmp \
        && tar -xzf haproxy-${HAPROXY_VERSION}.tar.gz \
        && cd  /tmp/haproxy-${HAPROXY_VERSION} \
        && make -j$(getconf _NPROCESSORS_ONLN) all $HAPROXY_CONFIG \
        && make install-bin  $HAPROXY_CONFIG \
        && git clone https://github.com/microsoft/mimalloc.git /tmp/mimalloc \
        && mkdir -p /tmp/mimalloc/out/release \
        && cd /tmp/mimalloc/out/release \
        && cmake -DMI_SECURE=OFF ../.. \
        && make install \
        && apk del .build-deps       

# 构建confd nginx 镜像

FROM alpine 
# 作者信息
LABEL MAINTAINER="qist Docker Maintainers 87984115@qq.com"

# 修改源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装ca 证书
RUN apk update && \
    apk add --no-cache ca-certificates 

# 设置环境变量

ENV HAPROXY_VERSION 2.5.4
ENV HAPROXY_URL http://www.haproxy.org/download/2.5/src/haproxy-2.5.4.tar.gz
# 监听端口
ENV HOST_PORT 6443
ENV LD_PRELOAD=/usr/local/lib/libmimalloc.so
# 后端转发端口
ENV BACKEND_PORT 5443
RUN  apk add  --no-cache  \ 
           curl \
           wget \
           pcre \
        && addgroup -S haproxy \
        && adduser -D -S -s /sbin/nologin -G haproxy haproxy \
        && mkdir -p /etc/confd \
        && mkdir -p /etc/haproxy
#COPY 编译结果  

COPY --from=0  /usr/sbin/haproxy /usr/sbin/haproxy
COPY --from=0  /usr/local/lib /usr/local/lib
ADD confd  /usr/sbin/confd
ADD conf.d /etc/confd/conf.d 
ADD templates /etc/confd/templates
ADD haproxy-proxy /usr/bin/haproxy-proxy


#添加执行权限
RUN  chmod +x /usr/sbin/confd \
     && chmod +x /usr/bin/haproxy-proxy

STOPSIGNAL SIGUSR1
EXPOSE 8404

ENTRYPOINT ["/usr/bin/haproxy-proxy"]

