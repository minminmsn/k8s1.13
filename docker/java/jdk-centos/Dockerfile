# 基础镜像
FROM core-harbor.minminmsn.com/public/centos:7.6.1810


# 维护信息
MAINTAINER minminmsn <admin@minminmsn.com>

# 文件复制到镜像
ADD jdk-8u212-linux-x64.tar.gz /usr/local/

# 设置环境变量
ENV JAVA_HOME /usr/local/jdk1.8.0_212
ENV CLASSPATH $JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
ENV PATH $PATH:$JAVA_HOME/bin

# 容器启动时运行的命令
CMD ["java", "-version"]