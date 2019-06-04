# 基础镜像
FROM core-harbor.minminmsn.com/public/jre-centos:1.8.0_212

# 维护信息
MAINTAINER admin <admin@minminmsn.com>

# 文件复制到镜像
RUN mkdir -p /data1/isc-api-gateway-app && mkdir -p /data1/logs/isc-api-gateway-app && mkdir -p /data1/run/isc-api-gateway-app
ADD docker/java/testapp/isc-api-gateway-test.tar.gz /data1/isc-api-gateway-app/

# 设置环境变量
# ENV JAVA_HOME /usr/local/jre1.8.0_212
# ENV PATH ${PATH}:${JAVA_HOME}/bin

# 容器启动时运行的命令
CMD ["/data1/isc-api-gateway-app/bin/launch.sh", "start"]

# 暴漏端口
EXPOSE 10030
