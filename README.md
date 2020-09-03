## 微服务容器化持续交付

### 总体流程
- 在开发机开发代码后提交到gitlab
- 通过镜像打包项目上线触发walle或jenkins进行构建，walle或jenkins将代码打成docker镜像，push到私有镜像库
- 通过服务上线项目将在k8s-master上执行rc、service的创建，进而创建Pod，从私服拉取镜像，根据该镜像启动容器


### 架构图
![](https://github.com/minminmsn/k8s1.13/blob/master/Architecture.png)


### Walle相关


### Docker相关
- **Docker镜像制作**

  - 系统基础镜像制作

  - JAVA镜像制作

  - 应用程序镜像制作


### Kube-Prometheus相关
- **kubernetes集群**
```
http://grafana-k8s.minminmsn.com 
admin
admin
```

### Fluentd-elasticsearch相关
- **集群容器运行日志收集**
[Kubernetes集群容器运行日志收集](https://github.com/minminmsn/k8s1.13/blob/master/fluentd-elasticsearch/Kubernetes%E6%97%A5%E5%BF%97%E6%94%B6%E9%9B%86.md)


### Kubernetes相关
- **Kubernetes1.13文档**
   - [kubernetes1.13.1+etcd3.3.10+flanneld0.10集群部署](https://github.com/minminmsn/k8s1.13/blob/master/kubernetes/kubernetes1.13.1%2Betcd3.3.10%2Bflanneld0.10%E9%9B%86%E7%BE%A4%E9%83%A8%E7%BD%B2.md)
   - [kubernetes1.13.1部署kuberneted-dashboard v1.10.1](https://github.com/minminmsn/k8s1.13/blob/master/kubernetes-dashboard-amd64/Kubernetes1.13.1%E9%83%A8%E7%BD%B2Kuberneted-dashboard%20v1.10.1.md)
   - [kubernetes1.13.1部署coredns](https://github.com/minminmsn/k8s1.13/blob/master/coredns/kubernetes1.13.1%E9%9B%86%E7%BE%A4%E9%83%A8%E7%BD%B2coredns.md)
   - [kubernetes1.13.1部署ingress-nginx并配置https转发dashboard]( https://github.com/minminmsn/k8s1.13/blob/master/ingress-nginx/kubernetes1.13.1%E9%83%A8%E7%BD%B2ingress-nginx%E5%B9%B6%E9%85%8D%E7%BD%AEhttps%E8%BD%AC%E5%8F%91dashboard.md)
   - [kubernetes1.13.1部署metrics-server0.3.1](https://github.com/minminmsn/k8s1.13/blob/master/metrics-server/kubernetes1.13.1%E9%83%A8%E7%BD%B2metrics-server0.3.1.md)
   - [kubernetes1.13.1集群使用ceph rbd存储块](https://github.com/minminmsn/k8s1.13/blob/master/volumes/rbd/k8s%E9%9B%86%E7%BE%A4%E4%BD%BF%E7%94%A8ceph%20rbd%E5%9D%97%E5%AD%98%E5%82%A8.md)
   - [kubernetes1.13.1集群结合ceph rbd部署最新版本jenkins](https://github.com/minminmsn/k8s1.13/blob/master/jenkins/k8s1.13.1%E9%9B%86%E7%BE%A4%E7%BB%93%E5%90%88ceph%20rbd%E9%83%A8%E7%BD%B2%E6%9C%80%E6%96%B0%E7%89%88%E6%9C%ACjenkins.md)
   - [kubernetes1.13.1集群安装包管理工具helm](https://github.com/minminmsn/k8s1.13/blob/master/helm/kubernetes1.13.1%E9%9B%86%E7%BE%A4%E5%AE%89%E8%A3%85%E5%8C%85%E7%AE%A1%E7%90%86%E5%B7%A5%E5%85%B7helm.md)
   - [kubernetes1.13.1集群集成harbor-helm](https://github.com/minminmsn/k8s1.13/blob/master/harbor-helm/kubernetes1.13.1%E9%9B%86%E7%BE%A4%E9%9B%86%E6%88%90harbor-helm.md)
   - [kubernetes1.13.1集群全栈监控方案kube-prometheus](https://github.com/minminmsn/k8s1.13/blob/master/kube-prometheus/kubernetes%E9%9B%86%E7%BE%A4%E5%85%A8%E6%A0%88%E7%9B%91%E6%8E%A7%E6%8A%A5%E8%AD%A6%E6%96%B9%E6%A1%88kube-prometheus.md)
   - [kubernetes1.13.1集群上使用Helm部署2.4.6版本Rancher集群](https://github.com/minminmsn/k8s1.13/blob/master/rancher/K8s%E9%9B%86%E7%BE%A4%E4%B8%8A%E4%BD%BF%E7%94%A8Helm%E9%83%A8%E7%BD%B22.4.6%E7%89%88%E6%9C%ACRancher%E9%9B%86%E7%BE%A4.md)

### 随喜赞叹
![](https://github.com/minminmsn/k8s1.13/blob/master/minminmsn.png)