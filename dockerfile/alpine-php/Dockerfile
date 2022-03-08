# 基础镜像
FROM alpine

# 作者信息
LABEL MAINTAINER="PHP 7.4.1 Docker Maintainers 87984115@qq.com"

# 修改源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装ca 证书
RUN apk update && \
    apk add --no-cache ca-certificates 

# 设置环境变量

ENV PHP_VERSION 7.4.1

# 编译安装PHP
RUN PHP_CONFIG="\
    --prefix=/usr/local \
    --exec-prefix=/usr/local \
     --sysconfdir=/etc \
     --with-config-file-path=/etc \
     --with-curl \
     --with-gettext \
     --with-iconv-dir \
     --with-kerberos \
     --with-libdir=lib64 \
     --with-mysqli \
     --with-openssl \
     --with-pdo-mysql \
     --with-pdo-sqlite \
     --with-pear \
     --with-xmlrpc \
     --with-xsl \
     --with-zlib \
     --with-zlib-dir \
     --with-mhash \
     --with-openssl-dir \
     --enable-fpm \
     --enable-bcmath \
     --enable-inline-optimization \
     --enable-mbregex \
     --enable-mbstring \
     --enable-opcache \
     --enable-pcntl \
     --enable-shmop \
     --enable-soap \
     --enable-sockets \
     --enable-sysvsem \
     --enable-xml \
     --enable-maintainer-zts \
     --enable-mysqlnd \
     " \
     && addgroup -S nginx \
     && adduser -D -S -h /www -s /sbin/nologin -G nginx nginx \
     && apk  add  --no-cache --virtual .build-deps \
        gcc \
        libc-dev \
        make \
        openssl-dev \
        pcre-dev \
        zlib-dev \
        linux-headers \
        curl \
        gnupg \
        libxslt-dev \
        gd-dev \
        geoip-dev \
        g++  \
        libstdc++ wget \
        libjpeg  \
        libpng \
        libpng-dev \
        freetype \
        freetype-dev \
        libxml2 \
        libxml2-dev \
        mysql \
        pcre-dev  \
        curl-dev \
        openssl \
        openssl-dev \
        libmcrypt \
        libmcrypt-dev \
        autoconf \
        libjpeg-turbo-dev \
        libmemcached \
        libmemcached-dev \
        gettext \
        krb5-dev \
        sqlite-dev \
        oniguruma-dev \
        gettext-dev \
        libzip \
        file \
        git \
        libzip-dev \
        && curl -fSL  https://www.php.net/distributions/php-$PHP_VERSION.tar.gz -o /tmp/php-$PHP_VERSION.tar.gz \
        && git clone -b v3.1.3 https://github.com/php-memcached-dev/php-memcached.git /tmp/php-memcached \
        && cd /tmp \
        && tar -xzf php-$PHP_VERSION.tar.gz \
        && cd  /tmp/php-$PHP_VERSION \
        && ./configure $PHP_CONFIG --enable-debug \
        && make -j$(getconf _NPROCESSORS_ONLN) \
        && make install \
        && cd /tmp/php-memcached \
        && phpize \
        && ./configure --with-php-config=/usr/local/bin/php-config \
           --disable-memcached-sasl \
        && make -j$(getconf _NPROCESSORS_ONLN) \
        && make install \
        && rm -rf /tmp/* \
        && apk del .build-deps \
        && apk  add  --no-cache  \
           curl \
           wget \
           libjpeg \
           libpng  \
           freetype \
           libxml2 \
           libxslt \
           libmcrypt  \
           libmemcached \
           gettext \
           oniguruma \
           sqlite-libs \
           libzip \
        && ln -sf /dev/stdout /usr/local/var/log/php-fpm.log \
        && rm -rf /var/cache/apk/*
# copy 配置到镜像中 
       
COPY php.ini /etc/php.ini
COPY php-fpm.conf /etc/php-fpm.conf
COPY php-fpm.d /etc/php-fpm.d
COPY localtime /etc/localtime
RUN echo extension=`find /usr/local/lib/ -name memcached.so`>>/etc/php.ini
# 开放端口
EXPOSE 9000

STOPSIGNAL SIGTERM

CMD ["/usr/local/sbin/php-fpm", "--fpm-config", "/etc/php-fpm.conf", "--pid", "/var/run/php-fpm.pid"]
