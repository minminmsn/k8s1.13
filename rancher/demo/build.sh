#!/usr/bin/env sh

echo '-- build --'

mvn clean package spring-boot:repackage -DskipTests
mv target/*.jar target/app.jar

# setup namespace
PROFILE=`echo ${CICD_GIT_BRANCH} | awk '{sub(/release\//,""); print $0}'`
NS_POSTFIX=`echo ${CICD_GIT_BRANCH} | awk '{sub(/release\//,""); print $0}'`
NS=tech-${NS_POSTFIX}
NS=`echo ${NS} | awk '{sub(/-$/,""); print $0}'`
sed -i "s/{NS}/${NS}/g" kubernetes.yaml
sed -i "s/{PROFILE}/${PROFILE}/g" kubernetes.yaml

env
