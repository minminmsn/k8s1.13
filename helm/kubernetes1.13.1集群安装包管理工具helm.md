kubernetes1.13.1集群安装包管理工具helm

参考文档
https://github.com/goharbor/harbor-helm
https://docs.helm.sh/using_helm/#installing-helm
https://github.com/goharbor/harbor/blob/master/docs/kubernetes_deployment.md
https://github.com/goharbor/harbor-helm/blob/master/docs/High%20Availability.md
https://li-sen.github.io/2018/10/08/k8s%E9%83%A8%E7%BD%B2%E9%AB%98%E5%8F%AF%E7%94%A8harbor/
https://www.cnblogs.com/ericnie/p/8463127.html



helm

一、安装helm客户端
[root@elasticsearch01 ~] wget https://storage.googleapis.com/kubernetes-helm/helm-v2.12.3-linux-amd64.tar.gz
[root@elasticsearch01 ~] tar zxvf helm-v2.12.3-linux-amd64.tar.gz 
[root@elasticsearch01 ~] cd linux-amd64/
[root@elasticsearch01 linux-amd64]mv helm tiller /usr/local/bin/
[root@elasticsearch01 linux-amd64]# helm version
Client: &version.Version{SemVer:"v2.12.3", GitCommit:"eecf22f77df5f65c823aacd2dbd30ae6c65f186e", GitTreeState:"clean"}
Error: could not find tiller



二、安装tiller
依赖关系
socat 
需要在各个节点上安装socat
yum install socat

1、创建rbac角色
[root@elasticsearch01 helm]# vim helm-rbac.yaml
[root@elasticsearch01 helm]# kubectl create -f helm-rbac.yaml 
serviceaccount/tiller created
clusterrolebinding.rbac.authorization.k8s.io/tiller created




