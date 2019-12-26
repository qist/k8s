ARG ARCH="amd64"
ARG OS="linux"
FROM busybox:glibc
LABEL maintainer="The Prometheus Authors <87984115@qq.com>"

ARG ARCH="amd64"
ARG OS="linux"
ADD elasticsearch_exporter /bin/elasticsearch_exporter

EXPOSE      9114
ENTRYPOINT  [ "/bin/elasticsearch_exporter" ]

