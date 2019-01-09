kubernetes1.13.1部署metrics-server0.3.1

### **参考文档**
```
https://kubernetes.io/docs/tasks/debug-application-cluster/core-metrics-pipeline/#metrics-server
https://github.com/kubernetes-incubator/metrics-server/tree/master/deploy/1.8%2B
https://www.cnblogs.com/cuishuai/p/9857120.html
https://juejin.im/post/5b6592ace51d4515b01c11ed
```

### **简介**
**Metrics Server**
heapster 已经被废弃了，后续版本中会使用 metrics-server代替
Metrics Server is a cluster-wide aggregator of resource usage data. Starting from Kubernetes 1.8 it’s deployed by default in clusters created by kube-up.sh script as a Deployment object. If you use a different Kubernetes setup mechanism you can deploy it using the provided deployment yamls. It’s supported in Kubernetes 1.7+ (see details below).
Metric server collects metrics from the Summary API, exposed by Kubelet on each node.
Metrics Server registered in the main API server through Kubernetes aggregator, which was introduced in Kubernetes 1.7.
Learn more about the metrics server in the design doc.


### **官网部署方法**
```
git clone https://github.com/kubernetes-incubator/metrics-server
cd metrics-server
kubectl create -f deploy/1.8+/
kubectl -n kube-system get pods -l k8s-app=metrics-server
```

### **实际部署步骤**

**下载部署文件**
```
[root@elasticsearch01 metrics-server]# ls 
aggregated-metrics-reader.yaml  auth-reader.yaml         metrics-server-deployment.yaml  resource-reader.yaml
auth-delegator.yaml             metrics-apiservice.yaml  metrics-server-service.yaml
```

**构建images**
可以在github上编写Dockerfile，再通过阿里云构建，构建后地址为registry.cn-beijing.aliyuncs.com/minminmsn/metrics-server:v0.3.1
Dockerfile文件地址：https://github.com/minminmsn/k8s1.13/blob/master/metrics-server/Dockerfile

**修改deployment镜像地址**
k8s.gcr.io/metrics-server:v0.3.1改成registry.cn-beijing.aliyuncs.com/minminmsn/metrics-server:v0.3.1
[root@elasticsearch01 metrics-server]# vim metrics-server-deployment.yaml 

**部署metrices-server**
```
[root@elasticsearch01 metrics-server]# kubectl create -f /k8s/yaml/metrics-server/
clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created
clusterrolebinding.rbac.authorization.k8s.io/metrics-server:system:auth-delegator created
rolebinding.rbac.authorization.k8s.io/metrics-server-auth-reader created
apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created
serviceaccount/metrics-server created
deployment.extensions/metrics-server created
service/metrics-server created
clusterrole.rbac.authorization.k8s.io/system:metrics-server created
clusterrolebinding.rbac.authorization.k8s.io/system:metrics-server created
```

**报错**
```
I0109 05:55:43.708300       1 serving.go:273] Generated self-signed cert (apiserver.local.config/certificates/apiserver.crt, apiserver.local.config/certificates/apiserver.key)
Error: cluster doesn't provide requestheader-client-ca-file
```

**排查**
```
https://github.com/kubernetes-incubator/metrics-server/issues/22
https://github.com/kubernetes-incubator/bootkube/issues/994
https://github.com/pires/kubernetes-vagrant-coreos-cluster/pull/319
https://blog.csdn.net/liukuan73/article/details/81352637
https://kubernetes.io/docs/tasks/access-kubernetes-api/configure-aggregation-layer/
```

**解决方法**
开启聚合层，Enable apiserver flags，修改kube-apiserver配置，重启服务
```
[root@elasticsearch01 cfg]# tail /k8s/kubernetes/cfg/kube-apiserver
--etcd-cafile=/k8s/etcd/ssl/ca.pem \
--etcd-certfile=/k8s/etcd/ssl/server.pem \
--etcd-keyfile=/k8s/etcd/ssl/server-key.pem \
--requestheader-client-ca-file=/k8s/kubernetes/ssl/ca.pem \
--requestheader-allowed-names=aggregator \
--requestheader-extra-headers-prefix=X-Remote-Extra- \
--requestheader-group-headers=X-Remote-Group \
--requestheader-username-headers=X-Remote-User \
--proxy-client-cert-file=/k8s/kubernetes/ssl/kube-proxy.pem \
--proxy-client-key-file=/k8s/kubernetes/ssl/kube-proxy-key.pem"
```

```
[root@elasticsearch01 cfg]# systemctl restart kube-apiserver.service 
[root@elasticsearch01 cfg]# systemctl status kube-apiserver.service 
● kube-apiserver.service - Kubernetes API Server
   Loaded: loaded (/usr/lib/systemd/system/kube-apiserver.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2019-01-09 14:56:59 CST; 8s ago
     Docs: https://github.com/kubernetes/kubernetes
 Main PID: 7465 (kube-apiserver)
   CGroup: /system.slice/kube-apiserver.service
           └─7465 /k8s/kubernetes/bin/kube-apiserver --logtostderr=true --v=4 --etcd-servers=https://10.2.8.44:2379,https://10.2.8...
```

### **创建metrics-ingress便于外部访问**
```
[root@elasticsearch01 ~]# cat /k8s/yaml/metrics-server/metrics-server-ingress.yaml 
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: metrics-ingress
  namespace: kube-system
  annotations:
    nginx.ingress.kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/secure-backends: "true"
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
spec:
  tls:
  - hosts:
    - metrics.zhidaoauto.com
    secretName: ingress-secret
  rules:
    - host: metrics.zhidaoauto.com
      http:
        paths:
        - path: /
          backend:
            serviceName: metrics-server
            servicePort: 443
[root@elasticsearch01 metrics-server]# kubectl create -f metrics-server-ingress.yaml 
ingress.extensions/metrics-ingress created
```

### **验证效果**
https://metrics.minminmsn.com:47215/metrics
> [![](https://i.loli.net/2019/01/09/5c35d849d34cc.png)](https://i.loli.net/2019/01/09/5c35d849d34cc.png)




