### **准备好应用程序**

```
[root@VM_8_24_centos testapp]# ls
Dockerfile  testapp-test.tar.gz
```


**编写Dockerfile**

```
[root@VM_8_24_centos testapp]# cat Dockerfile 
# 基础镜像
FROM core-harbor.minminmsn.com/public/jre-centos:1.8.0_212

# 维护信息
MAINTAINER minyt <minyongtao@minminmsn.com>

# 文件复制到镜像
RUN mkdir -p /data1/testapp-app && mkdir -p /data1/logs/testapp-app && mkdir -p /data1/run/testapp-app
ADD testapp-test.tar.gz /data1/testapp-app/

# 设置环境变量
# ENV JAVA_HOME /usr/local/jre1.8.0_212
# ENV PATH ${PATH}:${JAVA_HOME}/bin

# 容器启动时运行的命令
CMD ["/data1/testapp-app/bin/launch.sh", "start"]

# 暴漏端口
EXPOSE 10030

```


**制作应用程序镜像**

```
[root@VM_8_24_centos testapp]# docker build -t core-harbor.minminmsn.com/public/testapp:2.0 .
Sending build context to Docker daemon  58.24MB
Step 1/6 : FROM core-harbor.minminmsn.com/public/jre-centos:1.8.0_212
 ---> f27d47159f1e
Step 2/6 : MAINTAINER minyt <minyongtao@minminmsn.com>
 ---> Using cache
 ---> 3d2b8caf725b
Step 3/6 : RUN mkdir -p /data1/testapp-app && mkdir -p /data1/logs/testapp-app && mkdir -p /data1/run/testapp-app
 ---> Running in 8034eb452bfa
Removing intermediate container 8034eb452bfa
 ---> eea12a3c6093
Step 4/6 : ADD testapp-test.tar.gz /data1/testapp-app/
 ---> 1d155c1cd571
Step 5/6 : CMD ["/data1/testapp-app/bin/launch.sh", "start"]
 ---> Running in c7dab4cffaf9
Removing intermediate container c7dab4cffaf9
 ---> 45a1da4c0742
Step 6/6 : EXPOSE 10030
 ---> Running in 2618620aa185
Removing intermediate container 2618620aa185
 ---> b1d3a82bb34d
Successfully built b1d3a82bb34d
Successfully tagged core-harbor.minminmsn.com/public/testapp:2.0
```

### **本地启动镜像测试**

```
[root@VM_8_24_centos testapp]# docker run -d -p 10030:10030  core-harbor.minminmsn.com/public/testapp:2.0
ce1cf6f8e29554187d8fc810f94e35b80ca0902d0e8fc7d43bc7f5fa5d9a7dc2
[root@VM_8_24_centos testapp]# netstat -tulpn |grep 10030
tcp6       0      0 :::10030                :::*                    LISTEN      28037/docker-proxy  
```


### **浏览器访问测试**

```
http://10.2.8.24:10030/
{"returncode":0,"message":"OK"}
```


### **上传到私有镜像库**

```
[root@VM_8_24_centos testapp]# docker push core-harbor.minminmsn.com/public/testapp:2.0
The push refers to repository [core-harbor.minminmsn.com/public/testapp]
04b815b81c42: Pushed 
8dae5abda95b: Pushed 
b9049811dc7d: Layer already exists 
89169d87dbe2: Layer already exists 
2.0: digest: sha256:db7f866ec3f531161c2f6a82667f03896657c34ccaf25b310d519abac175c25e size: 1160
```


### **在kubernetes上发布测试**


**准备testapp.yaml文件**

```
[root@elasticsearch01 testapp]# cat testapp.yaml 
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  labels:
    app.kubernetes.io/name: testapp
    app.kubernetes.io/part-of: ingress-nginx

  name: testapp
  namespace: ingress-nginx
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: testapp
      app.kubernetes.io/part-of: ingress-nginx
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      labels:
        app.kubernetes.io/name: testapp
        app.kubernetes.io/part-of: ingress-nginx
    spec:
      containers:
        - image: core-harbor.minminmsn.com/public/testapp:2.0
          name: testapp
          ports:
            - containerPort: 10030
              protocol: TCP
      restartPolicy: Always
      volumes:
        - emptyDir: {}
          name: data

---
apiVersion: v1
kind: Service
metadata:
  name: testapp
  namespace: ingress-nginx
  labels:
    app.kubernetes.io/name: testapp
    app.kubernetes.io/part-of: ingress-nginx

spec:
  ports:
    - port: 10030
      protocol: TCP
      targetPort: 10030
  selector:
    app.kubernetes.io/name: testapp
    app.kubernetes.io/part-of: ingress-nginx
  type: NodePort

---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: testapp-ingress
  namespace: ingress-nginx
  rules:
    - host: testapp.minminmsn.com
      http:
        paths:
        - path: /
          backend:
            serviceName: testapp
            servicePort: 10030
```


**部署应用**

```
[root@elasticsearch01 testapp]# kubectl create -f testapp.yaml 
deployment.extensions/testapp created
service/testapp created
ingress.extensions/testapp-ingress created
```