### kubernetes1.13.1部署coredns
> 参考文档
https://www.cnblogs.com/aguncn/p/7217884.html
https://github.com/coredns/deployment/issues/111
https://blog.csdn.net/ccy19910925/article/details/80762025
https://github.com/coredns/deployment/tree/master/kubernetes
https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/#coredns



### 一、修改部署文件环境变量  
在官网下载https://github.com/coredns/deployment/tree/master/kubernetes 配置文件主要是deploy.sh和coredns.yam.sed，由于不是从kube-dns转到coredns，所以要注释掉kubectl相关操作，修改REVERSE_CIDRS、DNS_DOMAIN、CLUSTER_DNS_IP等变量为实际值，具体命令./deploy.sh -s -r 10.254.0.0/16 -i 10.254.0.10 -d clouster.local > coredns.yaml11
```
[root@elasticsearch01 coredns]# ./deploy.sh -h
usage: ./deploy.sh [ -r REVERSE-CIDR ] [ -i DNS-IP ] [ -d CLUSTER-DOMAIN ] [ -t YAML-TEMPLATE ]
    -r : Define a reverse zone for the given CIDR. You may specifcy this option more
         than once to add multiple reverse zones. If no reverse CIDRs are defined,
         then the default is to handle all reverse zones (i.e. in-addr.arpa and ip6.arpa)
    -i : Specify the cluster DNS IP address. If not specificed, the IP address of
         the existing "kube-dns" service is used, if present.
    -s : Skips the translation of kube-dns configmap to the corresponding CoreDNS Corefile configuration.
[root@elasticsearch01 coredns]#  ./deploy.sh -s -r 10.254.0.0/16 -i 10.254.0.10 -d cluster.local > coredns.yaml
[root@elasticsearch01 coredns]# ls
coredns.yaml    coredns.yaml.sed  deploy.sh
```

修改前后对比
```
[root@elasticsearch01 coredns]# diff coredns.yaml coredns.yaml.sed 
58c58
<         kubernetes cluster.local  10.254.0.0/16 {
---
>         kubernetes CLUSTER_DOMAIN REVERSE_CIDRS {
62c62
<         }
---
>         }FEDERATIONS
64c64
<         proxy . /etc/resolv.conf
---
>         proxy . UPSTREAMNAMESERVER
69c69
<     }
---
>     }STUBDOMAINS
165c165
<   clusterIP: 10.254.0.10
---
>   clusterIP: CLUSTER_DNS_IP
```


### 二、部署coredns
```
[root@elasticsearch01 coredns]# kubectl create -f coredns.yaml
serviceaccount/coredns created
clusterrole.rbac.authorization.k8s.io/system:coredns created
clusterrolebinding.rbac.authorization.k8s.io/system:coredns created
configmap/coredns created
deployment.extensions/coredns created
service/kube-dns created
```


### 三、修改kubelet dns服务参数并重启kubelet服务
```
[root@elasticsearch02 ~]# tail /k8s/kubernetes/cfg/kubelet
--v=4 \
--hostname-override=10.2.8.65 \
--kubeconfig=/k8s/kubernetes/cfg/kubelet.kubeconfig \
--bootstrap-kubeconfig=/k8s/kubernetes/cfg/bootstrap.kubeconfig \
--config=/k8s/kubernetes/cfg/kubelet.config \
--cert-dir=/k8s/kubernetes/ssl \
--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google-containers/pause-amd64:3.0 \
--cluster-dns=10.254.0.10 \
--cluster-domain=cluster.local. \
--resolv-conf=/etc/resolv.conf "
```

```
[root@elasticsearch02 ~]# systemctl restart kubelet.service 
[root@elasticsearch02 ~]# systemctl status kubelet.service 
● kubelet.service - Kubernetes Kubelet
   Loaded: loaded (/usr/lib/systemd/system/kubelet.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2019-01-03 16:00:20 CST; 6s ago
 Main PID: 31924 (kubelet)
   Memory: 80.2M
   CGroup: /system.slice/kubelet.service
           └─31924 /k8s/kubernetes/bin/kubelet --logtostderr=true --v=4 --hostname-override=10.2.8.65 --kubeconfig=/k8s/kubernetes...
```


### 四、使用busybox测试效果
注意：拿SVC服务来测试
```
[root@elasticsearch01 coredns]# kubectl run -it --rm --restart=Never --image=infoblox/dnstools:latest dnstools
If you don't see a command prompt, try pressing enter.
dnstools# nslookup kubernetes
Server:		10.254.0.10
Address:	10.254.0.10#53

Name:	kubernetes.default.svc.cluster.local
Address: 10.254.0.1

dnstools# nslookup nginx
Server:		10.254.0.10
Address:	10.254.0.10#53

Name:	nginx.default.svc.cluster.local
Address: 10.254.224.237
```


