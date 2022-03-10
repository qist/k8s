# 基础镜像
FROM alpine

# 作者信息
LABEL MAINTAINER="Qist Docker Maintainers 87984115@qq.com"

# 修改源 国内开启
#RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装ca 证书
RUN apk update && \
    apk add --no-cache ca-certificates 

# 设置环境变量

ENV NGINX_VERSION 1.21.6 

ENV OPENSSL_VERSION 1.1.1m

# ENV http_proxy http://192.168.0.151:7890
# ENV https_proxy http://192.168.0.151:7890

# 编译安装NGINX


WORKDIR /tmp

RUN NGINX_CONFIG="\
      --prefix=/etc/nginx \
      --sbin-path=/usr/sbin/nginx \
      --conf-path=/etc/nginx/nginx.conf \
      --error-log-path=/var/log/nginx/error.log \
      --http-log-path=/var/log/nginx/access.log \
      --pid-path=/var/run/nginx.pid \
      --lock-path=/var/run/nginx.lock \
      --http-client-body-temp-path=/var/cache/nginx/client_temp \
      --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
      --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
      --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
      --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
      --with-pcre \
      --user=nginx \
      --group=nginx \
      --with-compat \
      --with-file-aio \
      --with-threads \
      --with-http_addition_module \
      --with-http_auth_request_module \
      --with-http_dav_module \
      --with-http_flv_module \
      --with-http_gunzip_module \
      --with-http_gzip_static_module \
      --with-http_mp4_module \
      --with-http_random_index_module \
      --with-http_realip_module \
      --with-http_secure_link_module \
      --with-http_slice_module \
      --with-http_ssl_module \
      --with-http_stub_status_module \
      --with-http_sub_module \
      --with-http_v2_module \
      --with-ipv6 \
      --with-openssl=../openssl-$OPENSSL_VERSION \
      --with-openssl-opt=enable-tls1_3 \
      --with-mail \
      --with-mail_ssl_module \
      --with-stream \
      --with-stream_realip_module \
      --with-stream_ssl_module \
      --with-stream_ssl_preread_module \
      --with-ld-opt=-Wl,--as-needed \
      --add-module=../nginx-module-stream-sts \
      --add-module=../nginx-module-sts \      
      --add-module=../ngx_healthcheck_module \
     " \
     && addgroup -S nginx \
     && adduser -D -S -h /www -s /sbin/nologin -G nginx nginx \
     && apk  add  --no-cache --virtual .build-deps \
        gcc \
        libc-dev \
        make \
        pcre-dev \
        zlib-dev \
        linux-headers \
        curl \
        gnupg \
        libxslt-dev \
        gd-dev \
        geoip-dev \
        libstdc++ wget \
        libjpeg  \
        libpng \
        libpng-dev \
        freetype \
        freetype-dev \
        libxml2 \
        libxml2-dev \
        curl-dev \
        libmcrypt \
        libmcrypt-dev \
        autoconf \
        libjpeg-turbo-dev \
        libmemcached \
        libmemcached-dev \
        gettext \
        gettext-dev \
        libzip \
        git \
        libzip-dev \
        cmake \
        g++ \
        && curl -fSL  https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz -o /tmp/openssl-$OPENSSL_VERSION.tar.gz \
        && curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o /tmp/nginx-$NGINX_VERSION.tar.gz \
        && cd /tmp \
        && git clone https://github.com/zhouchangxun/ngx_healthcheck_module.git /tmp/ngx_healthcheck_module \
        && git clone https://github.com/vozlt/nginx-module-stream-sts.git /tmp/nginx-module-stream-sts \
        && git clone https://github.com/vozlt/nginx-module-sts.git /tmp/nginx-module-sts \
        && git clone https://github.com/microsoft/mimalloc.git /tmp/mimalloc \
        && tar -xzf openssl-$OPENSSL_VERSION.tar.gz \
        && tar -xzf nginx-$NGINX_VERSION.tar.gz \
        && cd  /tmp/nginx-$NGINX_VERSION \
        && git apply ../ngx_healthcheck_module/nginx_healthcheck_for_nginx_1.19+.patch \
        && ./configure $NGINX_CONFIG \
        && make -j$(getconf _NPROCESSORS_ONLN) \
        && make install \
        && mkdir -p /tmp/mimalloc/out/release \
        && cd /tmp/mimalloc/out/release \
        && cmake -DMI_SECURE=OFF ../.. \
        && make install \
        && apk del .build-deps        

# 构建confd nginx 镜像

FROM alpine 
# 作者信息
LABEL MAINTAINER="Qist Docker Maintainers 87984115@qq.com"

# 修改源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装ca 证书
RUN apk update && \
    apk add --no-cache ca-certificates 

# 设置环境变量
ENV LD_PRELOAD=/usr/local/lib/libmimalloc.so
# nginx 进行使用cpu 数量
ENV CPU_NUM 4
# nginx 监听端口
ENV HOST_PORT 6443
# kube-apiserver 端口 
ENV BACKEND_PORT 5443
RUN  mkdir -p /var/lib/nginx/cache \
     && apk add  --no-cache  \ 
           curl \
           wget \
           pcre \
          && addgroup -S nginx \
          && adduser -D -S -h /var/lib/nginx -s /sbin/nologin -G nginx nginx \
          && chown -R nginx:nginx /var/lib/nginx \
          && mkdir -p /var/log/nginx \
          && rm -rf /var/cache/apk/* \
          && mkdir -p /etc/confd \
          && mkdir -p /var/cache/nginx/client_temp
#COPY 编译结果  

COPY --from=0  /usr/sbin/nginx /usr/sbin/nginx
COPY --from=0  /etc/nginx  /etc/nginx
COPY --from=0  /usr/local/lib /usr/local/lib
ADD confd  /usr/sbin/confd
ADD conf.d /etc/confd/conf.d 
ADD templates /etc/confd/templates
ADD nginx-proxy /usr/bin/nginx-proxy
#添加执行权限
RUN  chmod +x /usr/sbin/confd \
     && chmod +x /usr/bin/nginx-proxy
STOPSIGNAL SIGTERM

ENTRYPOINT ["/usr/bin/nginx-proxy"]

