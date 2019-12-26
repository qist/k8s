#!/bin/bash
go get github.com/justwatchcom/elasticsearch_exporter
cp -pdr $GOBIN/elasticsearch_exporter ./
#docker build -t elasticsearch_exporter .
# docker tag elasticsearch_exporter juestnow/elasticsearch_exporter
# docker build -t juestnow/elasticsearch_exporter .