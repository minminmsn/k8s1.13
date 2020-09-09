FROM core-harbor.minminmsn.com/public/centos-jdk8:v1.0.7
MAINTAINER minminmsn

ADD ./target/*.jar /opt/app.jar

EXPOSE 8080

CMD ["bash", "-c", "java $JAVA_OPTS -jar /opt/app.jar $APP_ARGS"]
