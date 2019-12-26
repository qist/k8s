ARG ARCH="amd64"
ARG OS="linux"
FROM busybox:glibc
LABEL maintainer="The Prometheus Authors <87984115@qq.com>"

ARG ARCH="amd64"
ARG OS="linux"
COPY nginx-vts-exporter /bin/nginx-vts-exporter

EXPOSE      9913
ENTRYPOINT  [ "/bin/nginx-vts-exporter" ]
