## kubernetes1.13.1集群安装包管理工具helm

### 参考文档
```
https://github.com/goharbor/harbor-helm
https://docs.helm.sh/using_helm/#installing-helm
https://github.com/goharbor/harbor/blob/master/docs/kubernetes_deployment.md
https://github.com/goharbor/harbor-helm/blob/master/docs/High%20Availability.md
https://li-sen.github.io/2018/10/08/k8s%E9%83%A8%E7%BD%B2%E9%AB%98%E5%8F%AF%E7%94%A8harbor/
https://www.cnblogs.com/ericnie/p/8463127.html
https://www.bountysource.com/issues/60265705-error-looks-like-https-kubernetes-charts-storage-googleapis-com-is-not-a-valid-chart-repository-or-cannot-be-reached-pipline-error-exit-status-1
```

### 一、安装helm客户端
```
[root@elasticsearch01 ~] wget https://storage.googleapis.com/kubernetes-helm/helm-v2.12.3-linux-amd64.tar.gz
[root@elasticsearch01 ~] tar zxvf helm-v2.12.3-linux-amd64.tar.gz 
[root@elasticsearch01 ~] cd linux-amd64/
[root@elasticsearch01 linux-amd64]mv helm tiller /usr/local/bin/
[root@elasticsearch01 linux-amd64]# helm version
Client: &version.Version{SemVer:"v2.12.3", GitCommit:"eecf22f77df5f65c823aacd2dbd30ae6c65f186e", GitTreeState:"clean"}
Error: could not find tiller
```


### 二、安装tiller
依赖关系
socat 
需要在各个节点上安装socat
yum install socat

**1、创建rbac角色**
```
[root@elasticsearch01 helm]# vim helm-rbac.yaml
[root@elasticsearch01 helm]# kubectl create -f helm-rbac.yaml 
serviceaccount/tiller created
clusterrolebinding.rbac.authorization.k8s.io/tiller created
```

**2、初始化安装tiller**
```
[root@elasticsearch01 helm]# helm init
Creating /root/.helm 
Creating /root/.helm/repository 
Creating /root/.helm/repository/cache 
Creating /root/.helm/repository/local 
Creating /root/.helm/plugins 
Creating /root/.helm/starters 
Creating /root/.helm/cache/archive 
Creating /root/.helm/repository/repositories.yaml 
Adding stable repo with URL: https://kubernetes-charts.storage.googleapis.com 
Error: Looks like "https://kubernetes-charts.storage.googleapis.com" is not a valid chart repository or cannot be reached: Get https://kubernetes-charts.storage.googleapis.com/index.yaml: read tcp 10.2.8.44:49020->216.58.220.208:443: read: connection reset by peer
```

报错一
更换国内源
```
[root@elasticsearch01 helm]# helm repo add stable https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
"stable" has been added to your repositories

[root@elasticsearch01 helm]# helm init
$HELM_HOME has been configured at /root/.helm.
Warning: Tiller is already installed in the cluster.
(Use --client-only to suppress this message, or --upgrade to upgrade Tiller to the current version.)
Happy Helming!

[root@elasticsearch01 helm]# helm repo update
Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈ 
```

```
[root@elasticsearch01 helm]# kubectl get pods -n kube-system
NAME                                   READY   STATUS             RESTARTS   AGE
coredns-7748f7f6df-2c7ws               1/1     Running            0          21d
coredns-7748f7f6df-chhwx               1/1     Running            0          21d
kubernetes-dashboard-cb55bd5bd-p644x   1/1     Running            0          15d
kubernetes-dashboard-cb55bd5bd-vlmdh   1/1     Running            0          22d
metrics-server-788c48df64-cfnnx        1/1     Running            0          13d
metrics-server-788c48df64-v75gr        1/1     Running            0          13d
tiller-deploy-69ffbf64bc-rxcj8         0/1     ImagePullBackOff   0          6m13s
[root@elasticsearch01 helm]# 
```


报错二
更换国内docker镜像（gcr.io/kubernetes-helm/tiller:v2.12.3），或者下载镜像后重新打标签
```
[root@elasticsearch01 helm]# kubectl describe pod/tiller-deploy-69ffbf64bc-rxcj8  -n kube-system
Name:               tiller-deploy-69ffbf64bc-rxcj8
Namespace:          kube-system
Priority:           0
PriorityClassName:  <none>
Node:               10.2.8.34/10.2.8.34
Start Time:         Fri, 25 Jan 2019 09:46:25 +0800
Labels:             app=helm
                    name=tiller
                    pod-template-hash=69ffbf64bc
Annotations:        <none>
Status:             Pending
IP:                 10.254.73.7
Controlled By:      ReplicaSet/tiller-deploy-69ffbf64bc
Containers:
  tiller:
    Container ID:   
    Image:          gcr.io/kubernetes-helm/tiller:v2.12.3
    Image ID:       
    Ports:          44134/TCP, 44135/TCP
    Host Ports:     0/TCP, 0/TCP
    State:          Waiting
      Reason:       ImagePullBackOff
    Ready:          False
    Restart Count:  0
    Liveness:       http-get http://:44135/liveness delay=1s timeout=1s period=10s #success=1 #failure=3
    Readiness:      http-get http://:44135/readiness delay=1s timeout=1s period=10s #success=1 #failure=3
    Environment:
      TILLER_NAMESPACE:    kube-system
      TILLER_HISTORY_MAX:  0
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-f8hz7 (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             False 
  ContainersReady   False 
  PodScheduled      True 
Volumes:
  default-token-f8hz7:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-f8hz7
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:
  Type     Reason     Age                   From                Message
  ----     ------     ----                  ----                -------
  Normal   Scheduled  10m                   default-scheduler   Successfully assigned kube-system/tiller-deploy-69ffbf64bc-rxcj8 to 10.2.8.34
  Normal   Pulling    8m36s (x4 over 10m)   kubelet, 10.2.8.34  pulling image "gcr.io/kubernetes-helm/tiller:v2.12.3"
  Warning  Failed     8m21s (x4 over 10m)   kubelet, 10.2.8.34  Failed to pull image "gcr.io/kubernetes-helm/tiller:v2.12.3": rpc error: code = Unknown desc = Error response from daemon: Get https://gcr.io/v2/: net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)
  Warning  Failed     8m21s (x4 over 10m)   kubelet, 10.2.8.34  Error: ErrImagePull
  Normal   BackOff    5m51s (x15 over 10m)  kubelet, 10.2.8.34  Back-off pulling image "gcr.io/kubernetes-helm/tiller:v2.12.3"
  Warning  Failed     49s (x36 over 10m)    kubelet, 10.2.8.34  Error: ImagePullBackOff
```

可以通过阿里云容器服务节后github构建海外镜像到国内
```
[root@elasticsearch02 ~]# docker pull registry.cn-beijing.aliyuncs.com/minminmsn/tiller:v2.12.3
v2.12.3: Pulling from minminmsn/tiller
407ea412d82c: Pull complete 
b384553aa9a9: Pull complete 
9015cc67398b: Pull complete 
b4d55549c9ed: Pull complete 
Digest: sha256:bbc6dbfc37b82de97da58ce9a99b17db8f474b3deb51130c36f463849c69bd3b
Status: Downloaded newer image for registry.cn-beijing.aliyuncs.com/minminmsn/tiller:v2.12.3
[root@elasticsearch02 ~]# docker tag registry.cn-beijing.aliyuncs.com/minminmsn/tiller:v2.12.3 gcr.io/kubernetes-helm/tiller:v2.12.3
[root@elasticsearch02 ~]# docker images |grep tiller
gcr.io/kubernetes-helm/tiller                                     v2.12.3             336eb7f809d0        5 minutes ago       81.4MB
registry.cn-beijing.aliyuncs.com/minminmsn/tiller                 v2.12.3             336eb7f809d0        5 minutes ago       81.4MB
```

等一会儿查看tiller pod正常运行了
```
[root@elasticsearch01 helm]# kubectl get pods -n kube-system
NAME                                   READY   STATUS    RESTARTS   AGE
coredns-7748f7f6df-2c7ws               1/1     Running   0          21d
coredns-7748f7f6df-chhwx               1/1     Running   0          21d
kubernetes-dashboard-cb55bd5bd-p644x   1/1     Running   0          15d
kubernetes-dashboard-cb55bd5bd-vlmdh   1/1     Running   0          22d
metrics-server-788c48df64-cfnnx        1/1     Running   0          13d
metrics-server-788c48df64-v75gr        1/1     Running   0          13d
tiller-deploy-69ffbf64bc-rxcj8         1/1     Running   0          28m


[root@elasticsearch01 helm]# kubectl log pod/tiller-deploy-69ffbf64bc-rxcj8  -n kube-system
log is DEPRECATED and will be removed in a future version. Use logs instead.
[main] 2019/01/25 02:13:01 Starting Tiller v2.12.3 (tls=false)
[main] 2019/01/25 02:13:01 GRPC listening on :44134
[main] 2019/01/25 02:13:01 Probes listening on :44135
[main] 2019/01/25 02:13:01 Storage driver is ConfigMap
[main] 2019/01/25 02:13:01 Max history per release is 0

[root@elasticsearch01 helm]# helm version
Client: &version.Version{SemVer:"v2.12.3", GitCommit:"eecf22f77df5f65c823aacd2dbd30ae6c65f186e", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.12.3", GitCommit:"eecf22f77df5f65c823aacd2dbd30ae6c65f186e", GitTreeState:"clean"}
```
