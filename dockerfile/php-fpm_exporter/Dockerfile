ARG ARCH="amd64"
ARG OS="linux"
FROM busybox:glibc
LABEL maintainer="The Prometheus Authors <87984115@qq.com>"

ARG ARCH="amd64"
ARG OS="linux"
ENV PHP_FPM_SCRAPE_URI "unix:///var/run/php-fpm.sock;/status"
COPY php-fpm_exporter /bin/php-fpm_exporter

EXPOSE      9253
CMD  [ "/bin/php-fpm_exporter", "server" ]
