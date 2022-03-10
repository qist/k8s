# 基础镜像
FROM alpine

# 作者信息
LABEL  MAINTAINER="nginx 1.21.6 Docker Maintainers 87984115@qq.com"

# 修改源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装ca 证书
RUN apk update && \
    apk add --no-cache ca-certificates 

# 设置环境变量

ENV NGINX_VERSION 1.21.6 

ENV OPENSSL_VERSION 1.1.1m


# 编译安装NGINX


RUN NGINX_CONFIG="\
     --prefix=/var/lib/nginx \
     --sbin-path=/usr/bin/nginx \
     --conf-path=/etc/nginx/nginx.conf \
     --error-log-path=/var/log/nginx/error.log \
     --http-log-path=/var/log/nginx/access.log \
     --pid-path=/var/run/nginx.pid \
     --lock-path=/var/run/nginx.lock \
     --http-client-body-temp-path=/var/lib/nginx/cache/client_temp \
     --http-proxy-temp-path=/var/lib/nginx/cache/proxy_temp \
     --http-fastcgi-temp-path=/var/lib/nginx/cache/fastcgi_temp \
     --http-uwsgi-temp-path=/var/lib/nginx/cache/uwsgi_temp \
     --http-scgi-temp-path=/var/lib/nginx/cache/scgi_temp \
     --user=nginx \
     --group=nginx \
     --with-compat \
     --with-pcre \
     --with-http_ssl_module \
     --with-http_realip_module \
     --with-http_addition_module \
     --with-http_sub_module \
     --with-http_dav_module \
     --with-http_flv_module \
     --with-http_mp4_module \
     --with-http_gunzip_module \
     --with-http_gzip_static_module \
     --with-http_random_index_module \
     --with-http_secure_link_module \
     --with-http_stub_status_module \
     --with-http_auth_request_module \
     --with-threads \
     --with-stream \
     --with-stream_ssl_module \
     --with-stream_realip_module \
     --with-stream_ssl_preread_module \
     --with-openssl=../openssl-$OPENSSL_VERSION \
     --with-http_slice_module \
     --with-mail \
     --with-mail_ssl_module \
     --with-file-aio \
     --with-http_v2_module \
     --with-ipv6 \
     --with-openssl-opt=enable-tls1_3 \
     --add-module=../echo-nginx-module \
     --add-module=../nginx_upstream_check_module \
     --add-module=../nginx-upsync-module \
     --add-module=../mod_zip \
     --add-module=../ngx_cache_purge \
     --add-module=../ngx_upstream_jdomain \
     --add-module=../headers-more-nginx-module \
     --add-module=../nginx-upstream-dynamic-servers \
     --add-module=../nginx-module-vts \
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
        patch \
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
        cmake \
        g++ \
        libzip-dev \
        && curl -fSL https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz -o /tmp/openssl-$OPENSSL_VERSION.tar.gz \
        && curl -fSL https://nginx.org/download/nginx-$NGINX_VERSION.tar.gz -o /tmp/nginx-$NGINX_VERSION.tar.gz \
        && git clone https://github.com/FRiCKLE/ngx_cache_purge.git  /tmp/ngx_cache_purge \
        && git clone https://github.com/xiaokai-wang/nginx_upstream_check_module.git /tmp/nginx_upstream_check_module \
        && git clone https://github.com/evanmiller/mod_zip.git /tmp/mod_zip \
        && git clone https://github.com/wdaike/ngx_upstream_jdomain.git /tmp/ngx_upstream_jdomain \
        && git clone https://github.com/GUI/nginx-upstream-dynamic-servers.git /tmp/nginx-upstream-dynamic-servers \
        && git clone https://github.com/vozlt/nginx-module-vts.git /tmp/nginx-module-vts \
        && git clone https://github.com/openresty/echo-nginx-module.git /tmp/echo-nginx-module \
        && git clone https://github.com/weibocom/nginx-upsync-module.git /tmp/nginx-upsync-module \
        && git clone https://github.com/openresty/headers-more-nginx-module.git /tmp/headers-more-nginx-module \
        && git clone https://github.com/microsoft/mimalloc.git /tmp/mimalloc \        
        && cd /tmp \
        && tar -xzf openssl-$OPENSSL_VERSION.tar.gz \
        && tar -xzf nginx-$NGINX_VERSION.tar.gz \
        && cd  /tmp/nginx-$NGINX_VERSION \
        && patch -p1 < ../nginx_upstream_check_module/check_1.12.1+.patch \
        && mkdir -p /var/lib/nginx/cache \
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

#COPY 编译结果  

COPY --from=0  /usr/bin/nginx /usr/bin/nginx
COPY --from=0  /etc/nginx  /etc/nginx
COPY --from=0  /var/lib/nginx /var/lib/nginx
COPY --from=0  /usr/local/lib /usr/local/lib

# 安装ca 证书
RUN apk update && \
    apk add --no-cache ca-certificates 
RUN  mkdir -p /var/lib/nginx/cache \
     && apk add  --no-cache  \ 
           curl \
           wget \
           pcre \
          && addgroup -S nginx \
          && adduser -D -S -h /var/lib/nginx -s /sbin/nologin -G nginx nginx \          
          && mkdir -p /var/log/nginx \
          && chown -R nginx:nginx /var/lib/nginx \
          && rm -rf /var/cache/apk/* \
          && ln -sf /dev/stdout /var/log/nginx/access.log \
          && ln -sf /dev/stderr /var/log/nginx/error.log \
          && mkdir -p /var/cache/nginx/client_temp

# 设置环境变量 
ENV LD_PRELOAD=/usr/local/lib/libmimalloc.so
# copy 配置到镜像中       
COPY nginx.conf /etc/nginx/nginx.conf
COPY conf.d /etc/nginx/conf.d
COPY vhost /etc/nginx/vhost
COPY localtime /etc/localtime

# 开放端口
EXPOSE 80 443 8080

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
