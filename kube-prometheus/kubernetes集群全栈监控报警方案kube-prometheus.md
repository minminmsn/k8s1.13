### 参考文档

```
http://www.servicemesher.com/blog/prometheus-operator-manual/
https://github.com/coreos/prometheus-operator
https://github.com/coreos/kube-prometheus
```

### 背景环境

- kubernetes集群1.13版本，纯二进制版本打造，参考[k8s1.13集群部署](https://github.com/minminmsn/k8s1.13/blob/master/kubernetes/kubernetes1.13.1%2Betcd3.3.10%2Bflanneld0.10%E9%9B%86%E7%BE%A4%E9%83%A8%E7%BD%B2.md)

- coreos/kube-prometheus从coreos/prometheus-operator独立出来了，后续entire monitoring stack只能去coreos/kube-prometheus

- 目前在该环境下部署还没有遇到坑


### 监控原理

Prometheus读取Metrcs，读取etcd或者api的都行

查看etcd的metrics输出信息
```
[root@elasticsearch01 yaml]# curl --cacert /k8s/etcd/ssl/ca.pem --cert /k8s/etcd/ssl/server.pem --key /k8s/etcd/ssl/server-key.pem https://10.2.8.34:2379/metrics
```
查看kube-apiserver的metrics信息
```
[root@elasticsearch01 yaml]#  kubectl get --raw /metrics
```

### 实施部署

注意：This will be the last release supporting Kubernetes 1.13 and before. The next release is going to support Kubernetes 1.14+ only.
后续版本只支持k8s1.14+，所以后续要下载release版本，目前只有一个版本所以可以直接git clone

**1.下载原代码**

```
[root@elasticsearch01 yaml]# git clone https://github.com/coreos/kube-prometheus
Cloning into 'kube-prometheus'...
remote: Enumerating objects: 5803, done.
remote: Total 5803 (delta 0), reused 0 (delta 0), pack-reused 5803
Receiving objects: 100% (5803/5803), 3.69 MiB | 536.00 KiB/s, done.
Resolving deltas: 100% (3441/3441), done.
```

**2.查看原配置文件**

```
[root@elasticsearch01 yaml]# cd kube-prometheus/manifests
[root@elasticsearch01 manifests]# ls
00namespace-namespace.yaml
0prometheus-operator-0alertmanagerCustomResourceDefinition.yaml
0prometheus-operator-0prometheusCustomResourceDefinition.yaml
0prometheus-operator-0prometheusruleCustomResourceDefinition.yaml
0prometheus-operator-0servicemonitorCustomResourceDefinition.yaml
0prometheus-operator-clusterRoleBinding.yaml
0prometheus-operator-clusterRole.yaml
0prometheus-operator-deployment.yaml
0prometheus-operator-serviceAccount.yaml
0prometheus-operator-serviceMonitor.yaml
0prometheus-operator-service.yaml
alertmanager-alertmanager.yaml
alertmanager-secret.yaml
alertmanager-serviceAccount.yaml
alertmanager-serviceMonitor.yaml
alertmanager-service.yaml
grafana-dashboardDatasources.yaml
grafana-dashboardDefinitions.yaml
grafana-dashboardSources.yaml
grafana-deployment.yaml
grafana-serviceAccount.yaml
grafana-serviceMonitor.yaml
grafana-service.yaml
kube-state-metrics-clusterRoleBinding.yaml
kube-state-metrics-clusterRole.yaml
kube-state-metrics-deployment.yaml
kube-state-metrics-roleBinding.yaml
kube-state-metrics-role.yaml
kube-state-metrics-serviceAccount.yaml
kube-state-metrics-serviceMonitor.yaml
kube-state-metrics-service.yaml
node-exporter-clusterRoleBinding.yaml
node-exporter-clusterRole.yaml
node-exporter-daemonset.yaml
node-exporter-serviceAccount.yaml
node-exporter-serviceMonitor.yaml
node-exporter-service.yaml
prometheus-adapter-apiService.yaml
prometheus-adapter-clusterRoleAggregatedMetricsReader.yaml
prometheus-adapter-clusterRoleBindingDelegator.yaml
prometheus-adapter-clusterRoleBinding.yaml
prometheus-adapter-clusterRoleServerResources.yaml
prometheus-adapter-clusterRole.yaml
prometheus-adapter-configMap.yaml
prometheus-adapter-deployment.yaml
prometheus-adapter-roleBindingAuthReader.yaml
prometheus-adapter-serviceAccount.yaml
prometheus-adapter-service.yaml
prometheus-clusterRoleBinding.yaml
prometheus-clusterRole.yaml
prometheus-prometheus.yaml
prometheus-roleBindingConfig.yaml
prometheus-roleBindingSpecificNamespaces.yaml
prometheus-roleConfig.yaml
prometheus-roleSpecificNamespaces.yaml
prometheus-rules.yaml
prometheus-serviceAccount.yaml
prometheus-serviceMonitorApiserver.yaml
prometheus-serviceMonitorCoreDNS.yaml
prometheus-serviceMonitorKubeControllerManager.yaml
prometheus-serviceMonitorKubelet.yaml
prometheus-serviceMonitorKubeScheduler.yaml
prometheus-serviceMonitor.yaml
prometheus-service.yaml
```


**3.新建目录重新梳理下**

```
[root@elasticsearch01 manifests]# mkdir -p operator node-exporter alertmanager grafana kube-state-metrics prometheus serviceMonitor adapter
[root@elasticsearch01 manifests]# mv *-serviceMonitor* serviceMonitor/
etheus/[root@elasticsearch01 manifests]# mv 0prometheus-operator* operator/
[root@elasticsearch01 manifests]# mv grafana-* grafana/
[root@elasticsearch01 manifests]# mv kube-state-metrics-* kube-state-metrics/
[root@elasticsearch01 manifests]# mv alertmanager-* alertmanager/
[root@elasticsearch01 manifests]# mv node-exporter-* node-exporter/
[root@elasticsearch01 manifests]# mv prometheus-adapter* adapter/
[root@elasticsearch01 manifests]# mv prometheus-* prometheus/
[root@elasticsearch01 manifests]# ls 
00namespace-namespace.yaml  alertmanager  kube-state-metrics  operator    serviceMonitor
adapter                     grafana       node-exporter       prometheus
[root@elasticsearch01 manifests]# ls -lh
total 36K
-rw-r--r-- 1 root root   60 Jun  3 20:05 00namespace-namespace.yaml
drwxr-xr-x 2 root root 4.0K Jun  4 14:23 adapter
drwxr-xr-x 2 root root 4.0K Jun  4 14:23 alertmanager
drwxr-xr-x 2 root root 4.0K Jun  4 14:23 grafana
drwxr-xr-x 2 root root 4.0K Jun  4 14:23 kube-state-metrics
drwxr-xr-x 2 root root 4.0K Jun  4 14:23 node-exporter
drwxr-xr-x 2 root root 4.0K Jun  4 14:23 operator
drwxr-xr-x 2 root root 4.0K Jun  4 14:23 prometheus
drwxr-xr-x 2 root root 4.0K Jun  4 14:23 serviceMonitor
```

**4.部署前注意问题**
a.镜像问题
其中k8s.gcr.io/addon-resizer:1.8.4镜像下载不了，需要借助阿里云中转下，其他镜像默认都能下载，如遇到不能下载的也需要中转下再tag到自己私有镜像库
```
[root@VM_8_24_centos ~]# docker pull registry.cn-beijing.aliyuncs.com/minminmsn/addon-resizer:1.8.4
1.8.4: Pulling from minminmsn/addon-resizer
90e01955edcd: Pull complete 
ab19a0d489ff: Pull complete 
Digest: sha256:455eb18aa7a658db4f21c1f2b901c6a274afa7db4b73f4402a26fe9b3993c205
Status: Downloaded newer image for registry.cn-beijing.aliyuncs.com/minminmsn/addon-resizer:1.8.4

[root@VM_8_24_centos ~]# docker tag registry.cn-beijing.aliyuncs.com/minminmsn/addon-resizer:1.8.4 core-harbor.minminmsn.com/public/addon-resizer:1.8.4 
[root@VM_8_24_centos ~]# docker push core-harbor.minminmsn.com/public/addon-resizer:1.8.4 
The push refers to repository [core-harbor.minminmsn.com/public/addon-resizer]
cd05ae2f58b4: Pushed 
8a788232037e: Pushed 
1.8.4: digest: sha256:455eb18aa7a658db4f21c1f2b901c6a274afa7db4b73f4402a26fe9b3993c205 size: 738
```


b.访问问题
grafana，prometheus，alermanager等如果不想使用ingres方式访问就需要使用nodeport方式，否则对外不好访问
nodeport方式需在service配置文件，如grafana/grafana-service.yaml 添加type: NodePort,如果要指定node对外端口，需要加配nodePort: 33000，具体可以看配置文件
ingress方式也需要配置文件，ingress配置文件见最后访问配置文件，ingress部署参考[k8s集群部署ingress](https://github.com/minminmsn/k8s1.13/blob/master/ingress-nginx/kubernetes1.13.1%E9%83%A8%E7%BD%B2ingress-nginx%E5%B9%B6%E9%85%8D%E7%BD%AEhttps%E8%BD%AC%E5%8F%91dashboard.md)


**5.应用部署**
```
[root@elasticsearch01 manifests]# kubectl apply -f .
namespace/monitoring created

[root@elasticsearch01 manifests]# kubectl apply -f operator/
customresourcedefinition.apiextensions.k8s.io/alertmanagers.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/prometheuses.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/prometheusrules.monitoring.coreos.com created
customresourcedefinition.apiextensions.k8s.io/servicemonitors.monitoring.coreos.com created
clusterrole.rbac.authorization.k8s.io/prometheus-operator created
clusterrolebinding.rbac.authorization.k8s.io/prometheus-operator created
deployment.apps/prometheus-operator created
service/prometheus-operator created
serviceaccount/prometheus-operator created
[root@elasticsearch01 manifests]# kubectl -n monitoring get pod
NAME                                   READY   STATUS    RESTARTS   AGE
prometheus-operator-7cb68545c6-z2kjn   1/1     Running   0          41s


[root@elasticsearch01 manifests]# kubectl apply -f adapter/
apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created
clusterrole.rbac.authorization.k8s.io/prometheus-adapter created
clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created
clusterrolebinding.rbac.authorization.k8s.io/prometheus-adapter created
clusterrolebinding.rbac.authorization.k8s.io/resource-metrics:system:auth-delegator created
clusterrole.rbac.authorization.k8s.io/resource-metrics-server-resources created
configmap/adapter-config created
deployment.apps/prometheus-adapter created
rolebinding.rbac.authorization.k8s.io/resource-metrics-auth-reader created
service/prometheus-adapter created
serviceaccount/prometheus-adapter created
[root@elasticsearch01 manifests]# kubectl apply -f alertmanager/
alertmanager.monitoring.coreos.com/main created
secret/alertmanager-main created
service/alertmanager-main created
serviceaccount/alertmanager-main created
[root@elasticsearch01 manifests]# kubectl apply -f node-exporter/
clusterrole.rbac.authorization.k8s.io/node-exporter created
clusterrolebinding.rbac.authorization.k8s.io/node-exporter created
daemonset.apps/node-exporter created
service/node-exporter created
serviceaccount/node-exporter created
[root@elasticsearch01 manifests]# kubectl apply -f kube-state-metrics/
clusterrole.rbac.authorization.k8s.io/kube-state-metrics created
clusterrolebinding.rbac.authorization.k8s.io/kube-state-metrics created
deployment.apps/kube-state-metrics created
role.rbac.authorization.k8s.io/kube-state-metrics created
rolebinding.rbac.authorization.k8s.io/kube-state-metrics created
service/kube-state-metrics created
serviceaccount/kube-state-metrics created
[root@elasticsearch01 manifests]# kubectl apply -f grafana/
secret/grafana-datasources created
configmap/grafana-dashboard-k8s-cluster-rsrc-use created
configmap/grafana-dashboard-k8s-node-rsrc-use created
configmap/grafana-dashboard-k8s-resources-cluster created
configmap/grafana-dashboard-k8s-resources-namespace created
configmap/grafana-dashboard-k8s-resources-pod created
configmap/grafana-dashboard-k8s-resources-workload created
configmap/grafana-dashboard-k8s-resources-workloads-namespace created
configmap/grafana-dashboard-nodes created
configmap/grafana-dashboard-persistentvolumesusage created
configmap/grafana-dashboard-pods created
configmap/grafana-dashboard-statefulset created
configmap/grafana-dashboards created
deployment.apps/grafana created
service/grafana created
serviceaccount/grafana created
[root@elasticsearch01 manifests]# kubectl apply -f prometheus/
clusterrole.rbac.authorization.k8s.io/prometheus-k8s created
clusterrolebinding.rbac.authorization.k8s.io/prometheus-k8s created
prometheus.monitoring.coreos.com/k8s created
rolebinding.rbac.authorization.k8s.io/prometheus-k8s-config created
rolebinding.rbac.authorization.k8s.io/prometheus-k8s created
rolebinding.rbac.authorization.k8s.io/prometheus-k8s created
rolebinding.rbac.authorization.k8s.io/prometheus-k8s created
role.rbac.authorization.k8s.io/prometheus-k8s-config created
role.rbac.authorization.k8s.io/prometheus-k8s created
role.rbac.authorization.k8s.io/prometheus-k8s created
role.rbac.authorization.k8s.io/prometheus-k8s created
prometheusrule.monitoring.coreos.com/prometheus-k8s-rules created
service/prometheus-k8s created
serviceaccount/prometheus-k8s created
[root@elasticsearch01 manifests]# kubectl apply -f serviceMonitor/
servicemonitor.monitoring.coreos.com/prometheus-operator created
servicemonitor.monitoring.coreos.com/alertmanager created
servicemonitor.monitoring.coreos.com/grafana created
servicemonitor.monitoring.coreos.com/kube-state-metrics created
servicemonitor.monitoring.coreos.com/node-exporter created
servicemonitor.monitoring.coreos.com/prometheus created
servicemonitor.monitoring.coreos.com/kube-apiserver created
servicemonitor.monitoring.coreos.com/coredns created
servicemonitor.monitoring.coreos.com/kube-controller-manager created
servicemonitor.monitoring.coreos.com/kube-scheduler created
servicemonitor.monitoring.coreos.com/kubelet created
```


**6.检查验证**
```
[root@elasticsearch01 manifests]# kubectl -n monitoring get all
NAME                                       READY   STATUS    RESTARTS   AGE
pod/alertmanager-main-0                    2/2     Running   0          91s
pod/alertmanager-main-1                    2/2     Running   0          74s
pod/alertmanager-main-2                    2/2     Running   0          67s
pod/grafana-fc6fc6f58-22mst                1/1     Running   0          89s
pod/kube-state-metrics-8ffb99887-crhww     4/4     Running   0          82s
pod/node-exporter-925wp                    2/2     Running   0          89s
pod/node-exporter-f45s4                    2/2     Running   0          89s
pod/prometheus-adapter-66fc7797fd-x6l5x    1/1     Running   0          90s
pod/prometheus-k8s-0                       3/3     Running   1          88s
pod/prometheus-k8s-1                       3/3     Running   1          88s
pod/prometheus-operator-7cb68545c6-z2kjn   1/1     Running   0          12m

NAME                            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
service/alertmanager-main       ClusterIP   10.254.83.142    <none>        9093/TCP            91s
service/alertmanager-operated   ClusterIP   None             <none>        9093/TCP,6783/TCP   91s
service/grafana                 NodePort    10.254.162.5     <none>        3000:33000/TCP      89s
service/kube-state-metrics      ClusterIP   None             <none>        8443/TCP,9443/TCP   90s
service/node-exporter           ClusterIP   None             <none>        9100/TCP            90s
service/prometheus-adapter      ClusterIP   10.254.123.201   <none>        443/TCP             91s
service/prometheus-k8s          ClusterIP   10.254.51.81     <none>        9090/TCP            89s
service/prometheus-operated     ClusterIP   None             <none>        9090/TCP            89s
service/prometheus-operator     ClusterIP   None             <none>        8080/TCP            12m

NAME                           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                 AGE
daemonset.apps/node-exporter   2         2         2       2            2           beta.kubernetes.io/os=linux   90s

NAME                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/grafana               1/1     1            1           89s
deployment.apps/kube-state-metrics    1/1     1            1           90s
deployment.apps/prometheus-adapter    1/1     1            1           91s
deployment.apps/prometheus-operator   1/1     1            1           12m

NAME                                             DESIRED   CURRENT   READY   AGE
replicaset.apps/grafana-fc6fc6f58                1         1         1       89s
replicaset.apps/kube-state-metrics-68865c459c    0         0         0       90s
replicaset.apps/kube-state-metrics-8ffb99887     1         1         1       82s
replicaset.apps/prometheus-adapter-66fc7797fd    1         1         1       91s
replicaset.apps/prometheus-operator-7cb68545c6   1         1         1       12m

NAME                                 READY   AGE
statefulset.apps/alertmanager-main   3/3     91s
statefulset.apps/prometheus-k8s      2/2     89s
```


**7.ingress配置**
```
[root@elasticsearch01 manifests]# cat ingress-monitor.yaml 
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: prometheus-ing
  namespace: monitoring
spec:
  rules:
  - host: prometheus-k8s.minminmsn.com
    http:
      paths:
      - backend:
          serviceName: prometheus-k8s
          servicePort: 9090
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: grafana-ing
  namespace: monitoring
spec:
  rules:
  - host: grafana-k8s.minminmsn.com
    http:
      paths:
      - backend:
          serviceName: grafana
          servicePort: 3000
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: alertmanager-ing
  namespace: monitoring
spec:
  rules:
  - host: alertmanager-k8s.minminmsn.com
    http:
      paths:
      - backend:
          serviceName: alertmanager-main
          servicePort: 9093


[root@elasticsearch01 manifests]# kubectl apply -f ingress-monitor.yaml 
ingress.extensions/prometheus-ing created
ingress.extensions/grafana-ing created
ingress.extensions/alertmanager-ing created
```


### 浏览器访问
**1.nodeport方式访问**
http://10.2.8.65:33000

**2.ingress方式访问**
http://grafana-k8s.minminmsn.com
默认账号密码admin admin需要重置密码进入
