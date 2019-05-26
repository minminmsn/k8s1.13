**参考文档**
```
https://www.jianshu.com/p/4143b5cef39f
https://www.cnblogs.com/niloay/p/6261784.html
https://blog.csdn.net/qq_35981283/article/details/80738451
https://cloud.tencent.com/developer/article/1188404
http://www.cnblogs.com/zhujingzhi/p/9746760.html#_label0
```


**选择底层操作系统**
通常是从一个底层的操作系统来开始构建一个Docker镜像的，也就是Dockerfile的FROM指令提及的。在某些情况下，你也许会从一个已有的基础镜像开始，这时你已经选择了底层操作系统镜像。但是如果你需要选择一个底层操作系统镜像，那么常用的镜像和对应的大小如下所示：
```
REPOSITORY                                 TAG                 IMAGE ID            CREATED             SIZE
ubuntu                                     19.04               9b17fc7d6848        5 days ago          75.4MB
alpine                                     3.9                 055936d39205        10 days ago         5.53MB
busybox                                    latest              64f5d945efcc        11 days ago         1.2MB
centos                                     7.6.1810            f1cb7c7d58b7        2 months ago        202MB
```

**制作基础系统镜像alpine、centos、ubuntu**
注意：
所有基础镜像及部署软件都要指定好具体版本，禁用last tag

- 下载alpine基础镜像
```
[root@VM_8_24_centos ~]# docker pull alpine:v3.9
Error response from daemon: manifest for alpine:v3.9 not found
[root@VM_8_24_centos ~]# docker pull alpine:3.9
3.9: Pulling from library/alpine
Digest: sha256:769fddc7cc2f0a1c35abb2f91432e8beecf83916c421420e6a6da9f8975464b6
Status: Downloaded newer image for alpine:3.9
[root@VM_8_24_centos ~]# docker images
REPOSITORY                    TAG                 IMAGE ID            CREATED             SIZE
alpine                        3.9                 055936d39205        10 days ago         5.53MB
```

- 登陆私有镜像库
```
[root@VM_8_24_centos ~]# docker login core-harbor.minminmsn.com
Username: admin
Password: 
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

- 打标签上传到私有镜像库
```
[root@VM_8_24_centos ~]# docker tag library/alpine:3.9  core-harbor.minminmsn.com/public/alpine:3.9
[root@VM_8_24_centos ~]# docker push core-harbor.minminmsn.com/public/alpine:3.9
The push refers to repository [core-harbor.minminmsn.com/public/alpine]
f1b5933fe4b5: Pushed 
3.9: digest: sha256:bf1684a6e3676389ec861c602e97f27b03f14178e5bc3f70dce198f9f160cce9 size: 528
```

- 同样方法制作centos、ubuntu系统基础镜像
```
[root@VM_8_24_centos ~]# docker images
REPOSITORY                                 TAG                 IMAGE ID            CREATED             SIZE
core-harbor.minminmsn.com/public/ubuntu   19.04               9b17fc7d6848        5 days ago          75.4MB
ubuntu                                     19.04               9b17fc7d6848        5 days ago          75.4MB
core-harbor.minminmsn.com/public/alpine   3.9                 055936d39205        10 days ago         5.53MB
alpine                                     3.9                 055936d39205        10 days ago         5.53MB
core-harbor.minminmsn.com/public/centos   7.6.1810            f1cb7c7d58b7        2 months ago        202MB
centos                                     7.6.1810            f1cb7c7d58b7        2 months ago        202MB
```


**在centos基础镜像上制作jre镜像**

- 下载jre包
```
[work@VM_8_24_centos jre-centos]# wget https://github.com/frekele/oracle-java/releases/download/8u212-b10/jre-8u212-linux-x64.tar.gz
[work@VM_8_24_centos jre-centos]# ls
jre-8u212-linux-x64.tar.gz
```

- 编辑Dockerfile
```
[work@VM_8_24_centos jre-centos]# cat Dockerfile 
# 基础镜像
FROM core-harbor.minminmsn.com/public/centos:7.6.1810

# 维护信息
MAINTAINER minyt <minyongtao@minminmsn.com>

# 文件复制到镜像
ADD jre-8u212-linux-x64.tar.gz /usr/local/

# 设置环境变量
ENV JAVA_HOME /usr/local/jre1.8.0_212
ENV PATH ${PATH}:${JAVA_HOME}/bin

# 容器启动时运行的命令
CMD ["java", "-version"]
```

- 制作镜像
```
[root@VM_8_24_centos data]# cd jre-centos/
[root@VM_8_24_centos jre-centos]# ls
Dockerfile  jre-8u212-linux-x64.tar.gz
[root@VM_8_24_centos jre-centos]# docker build -t core-harbor.minminmsn.com/public/jre-centos:1.8.0_212 .
Sending build context to Docker daemon  87.89MB
Step 1/6 : FROM core-harbor.minminmsn.com/public/centos:7.6.1810
 ---> f1cb7c7d58b7
Step 2/6 : MAINTAINER minyt <minyongtao@minminmsn.com>
 ---> Using cache
 ---> d0fb7c193008
Step 3/6 : ADD jre-8u212-linux-x64.tar.gz /usr/local/
 ---> 674cf9135825
Step 4/6 : ENV JAVA_HOME /usr/local/jre1.8.0_212
 ---> Running in 1c4a7c7a19ad
Removing intermediate container 1c4a7c7a19ad
 ---> ab2fc886e944
Step 5/6 : ENV PATH ${PATH}:${JAVA_HOME}/bin
 ---> Running in 3107ba5ae7b9
Removing intermediate container 3107ba5ae7b9
 ---> f14d2948c92d
Step 6/6 : CMD ["java", "-version"]
 ---> Running in 99374bccaa27
Removing intermediate container 99374bccaa27
 ---> f27d47159f1e
Successfully built f27d47159f1e
Successfully tagged core-harbor.minminmsn.com/public/jre-centos:1.8.0_212
```

- 查看镜像
```
[root@VM_8_24_centos jre-centos]# docker images 
REPOSITORY                                     TAG                 IMAGE ID            CREATED             SIZE
core-harbor.minminmsn.com/public/jre-centos   1.8.0_212           f27d47159f1e        17 seconds ago      441MB
```

- 上传镜像到私有镜像库
```
[root@VM_8_24_centos jre-centos]# docker push core-harbor.minminmsn.com/public/jre-centos:1.8.0_212
The push refers to repository [core-harbor.minminmsn.com/public/jre-centos]
b9049811dc7d: Pushed 
89169d87dbe2: Mounted from public/jdk-centos 
1.8.0_212: digest: sha256:5c909a0c33aaa13b3a3ce48fd0f60356a32c5a697d99f39f08e92f1c6ba7bd57 size: 741
```

- 运行验证jre镜像
```
[root@VM_8_24_centos jre-centos]# docker run core-harbor.minminmsn.com/public/jre-centos:1.8.0_212
java version "1.8.0_212"
Java(TM) SE Runtime Environment (build 1.8.0_212-b10)
Java HotSpot(TM) 64-Bit Server VM (build 25.212-b10, mixed mode)
```
