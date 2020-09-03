**参考文档**
[Helm安装Rancher](https://docs.rancher.cn/rancher2x/installation/helm-ha-install/online/tcp-l4/rancher-install.html#_1-%E6%B7%BB%E5%8A%A0chart%E4%BB%93%E5%BA%93%E5%9C%B0%E5%9D%80 "Helm安装Rancher")


**Rancher简介**
Rancher是一套容器管理平台，它可以帮助组织在生产环境中轻松快捷的部署和管理容器。 Rancher可以轻松地管理各种环境的Kubernetes，满足IT需求并为DevOps团队提供支持。
Kubernetes不仅已经成为的容器编排标准，它也正在迅速成为各类云和虚拟化厂商提供的标准基础架构。Rancher用户可以选择使用Rancher Kubernetes Engine(RKE)创建Kubernetes集群，也可以使用GKE，AKS和EKS等云Kubernetes服务。 Rancher用户还可以导入和管理现有的Kubernetes集群。
Rancher支持各类集中式身份验证系统来管理Kubernetes集群。例如，大型企业的员工可以使用其公司Active Directory凭证访问GKE中的Kubernetes集群。IT管​​理员可以在用户，组，项目，集群和云中设置访问控制和安全策略。 IT管​​理员可以在单个页面对所有Kubernetes集群的健康状况和容量进行监控。
Rancher为DevOps工程师提供了一个直观的用户界面来管理他们的服务容器，用户不需要深入了解Kubernetes概念就可以开始使用Rancher。 Rancher包含应用商店，支持一键式部署Helm和Compose模板。Rancher通过各种云、本地生态系统产品认证，其中包括安全工具，监控系统，容器仓库以及存储和网络驱动程序。下图说明了Rancher在IT和DevOps组织中扮演的角色。每个团队都会在他们选择的公共云或私有云上部署应用程序。

**集群环境**
```
[root@elasticsearch01 ~]# kubectl get nodes
NAME        STATUS   ROLES    AGE    VERSION
10.2.8.34   Ready    <none>   615d   v1.13.1
10.2.8.65   Ready    <none>   615d   v1.13.1
```

**Helm环境**
```
[root@elasticsearch01 yaml]# helm version
Client: &version.Version{SemVer:"v2.12.3", GitCommit:"eecf22f77df5f65c823aacd2dbd30ae6c65f186e", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.12.3", GitCommit:"eecf22f77df5f65c823aacd2dbd30ae6c65f186e", GitTreeState:"clean"}
```

**添加Chart仓库地址**
```
[root@elasticsearch01 yaml]# helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
"rancher-stable" has been added to your repositories 
```

**通过Helm安装Rancher**
注意：这里指定了hostname=rancher.minminmsn.com，必须使用域名访问才行。
注意：rancher默认使用https访问，因此，需要有一个公网的SSL才行，可以使用之前ingress-secret2021。
```
[root@elasticsearch01 yaml]# kubectl get secret|grep 2021
ingress-secret2021                                     kubernetes.io/tls                     2      47d
```

注意：其中有几个参数需要特别注意，如果不注意后续再修改服务配置也可，比如namespace、hostname、ingress等，下面正式helm部署rancher
```
[root@elasticsearch01 yaml]# helm install rancher-stable/rancher   --name rancher     --set hostname=rancher.minminmsn.com   --set ingress.tls.source=ingress-secret2021
NAME:   rancher
LAST DEPLOYED: Mon Aug 31 15:21:33 2020
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/ServiceAccount
NAME     SECRETS  AGE
rancher  1        0s

==> v1/ClusterRoleBinding
NAME     AGE
rancher  0s

==> v1/Service
NAME     TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)  AGE
rancher  ClusterIP  10.254.185.214  <none>       80/TCP   0s

==> v1/Deployment
NAME     DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
rancher  3        3        3           0          0s

==> v1beta1/Ingress
NAME     HOSTS                   ADDRESS  PORTS  AGE
rancher  rancher.minminmsn.com  80, 443  0s

==> v1/Pod(related)
NAME                     READY  STATUS             RESTARTS  AGE
rancher-cf8d8f9dd-2m2pc  0/1    ContainerCreating  0         0s
rancher-cf8d8f9dd-462t6  0/1    ContainerCreating  0         0s
rancher-cf8d8f9dd-twcjf  0/1    ContainerCreating  0         0s


NOTES:
Rancher Server has been installed.

NOTE: Rancher may take several minutes to fully initialize. Please standby while Certificates are being issued and Ingress comes up.

Check out our docs at https://rancher.com/docs/rancher/v2.x/en/

Browse to https://rancher.minminmsn.com

Happy Containering!

[root@elasticsearch01 yaml]# helm ls --all rancher
NAME   	REVISION	UPDATED                 	STATUS  	CHART        	APP VERSION	NAMESPACE
rancher	1       	Mon Aug 31 15:21:33 2020	DEPLOYED	rancher-2.4.6	v2.4.6     	default  
[root@elasticsearch01 yaml]# kubectl get pods |grep rancher
rancher-cf8d8f9dd-2m2pc                        0/1     ContainerCreating   0          69s
rancher-cf8d8f9dd-462t6                        0/1     ContainerCreating   0          69s
rancher-cf8d8f9dd-twcjf                        0/1     ContainerCreating   0          69s
```

发现默认是3节点rancher集群，测试k8s集群只有2个节点，所以有1个pod没有启动，这里需要修改deploy中的replicas为2
```
[root@elasticsearch01 yaml]# kubectl get pods |grep rancher
rancher-cf8d8f9dd-2m2pc                        1/1     Running             0          5m48s
rancher-cf8d8f9dd-462t6                        1/1     Running             0          5m48s
rancher-cf8d8f9dd-twcjf                        0/1     ContainerCreating   0          5m48s

[root@elasticsearch01 yaml]# kubectl get deploy
NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
rancher                       2/3     3            2           5m48s
```

修改其中replicas由2变为2
```
spec:
  progressDeadlineSeconds: 600
  replicas: 3
 
```
 
全部内容如下 
```
[root@elasticsearch01 yaml]# kubectl edit  deploy rancher

# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "1"
  creationTimestamp: "2020-08-31T07:21:34Z"
  generation: 1
  labels:
    app: rancher
    chart: rancher-2.4.6
    heritage: Tiller
    release: rancher
  name: rancher
  namespace: default
  resourceVersion: "99595282"
  selfLink: /apis/extensions/v1beta1/namespaces/default/deployments/rancher
  uid: 995f7aaf-eb5a-11ea-9386-52540089b2b6
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  annotations:
    deployment.kubernetes.io/revision: "1"
  creationTimestamp: "2020-08-31T07:21:34Z"
  generation: 1
  labels:
    app: rancher
    chart: rancher-2.4.6
    heritage: Tiller
    release: rancher
  name: rancher
  namespace: default
  resourceVersion: "99595282"
  selfLink: /apis/extensions/v1beta1/namespaces/default/deployments/rancher
  uid: 995f7aaf-eb5a-11ea-9386-52540089b2b6
spec:
  progressDeadlineSeconds: 600
  replicas: 3
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: rancher
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: rancher
        release: rancher
    spec:
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - rancher
              topologyKey: kubernetes.io/hostname
            weight: 100
      containers:
      - args:
        - --no-cacerts
        - --http-listen-port=80
        - --https-listen-port=443
        - --add-local=auto
        env:
        - name: CATTLE_NAMESPACE
          value: default
        - name: CATTLE_PEER_SERVICE
          value: rancher
        image: rancher/rancher:v2.4.6
        imagePullPolicy: IfNotPresent
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /healthz
            port: 80
            scheme: HTTP
          initialDelaySeconds: 60
          periodSeconds: 30
          successThreshold: 1
          timeoutSeconds: 1
        name: rancher
        ports:
        - containerPort: 80
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /healthz
            port: 80
            scheme: HTTP
          initialDelaySeconds: 5
          periodSeconds: 30
          successThreshold: 1
          timeoutSeconds: 1
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext: {}
      serviceAccount: rancher
      serviceAccountName: rancher
      terminationGracePeriodSeconds: 30
status:
  availableReplicas: 2
  conditions:
  - lastTransitionTime: "2020-08-31T07:26:36Z"
    lastUpdateTime: "2020-08-31T07:26:36Z"
    message: Deployment has minimum availability.
    reason: MinimumReplicasAvailable
    status: "True"
    type: Available
  - lastTransitionTime: "2020-08-31T07:21:34Z"
    lastUpdateTime: "2020-08-31T07:26:36Z"
    message: ReplicaSet "rancher-cf8d8f9dd" is progressing.
    reason: ReplicaSetUpdated
    status: "True"
    type: Progressing
  observedGeneration: 1
  readyReplicas: 2
  replicas: 3
  unavailableReplicas: 1
  updatedReplicas: 3


[root@elasticsearch01 yaml]# kubectl edit  deploy rancher
deployment.extensions/rancher edited
[root@elasticsearch01 yaml]# kubectl get pods|grep rancher
rancher-cf8d8f9dd-2m2pc                        1/1     Running   0          11m
rancher-cf8d8f9dd-462t6                        1/1     Running   0          11m
[root@elasticsearch01 yaml]# kubectl get deploy
NAME                          READY   UP-TO-DATE   AVAILABLE   AGE
rancher                       2/2     2            2           11m
```

修改ingress证书
需要修改rancher默认ingress的secretName由tls-rancher-ingress变更为ingress-secret2021
```
[root@elasticsearch01 yaml]# kubectl edit ingress rancher

# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    certmanager.k8s.io/issuer: rancher
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "30"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "1800"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "1800"
  creationTimestamp: "2020-08-31T07:21:34Z"
  generation: 1
  labels:
    app: rancher
    chart: rancher-2.4.6
    heritage: Tiller
    release: rancher
  name: rancher
  namespace: default
  resourceVersion: "99593839"
  selfLink: /apis/extensions/v1beta1/namespaces/default/ingresses/rancher
  uid: 996153bf-eb5a-11ea-9386-52540089b2b6
spec:
  rules:
  - host: rancher.minminmsn.com
    http:
      paths:
      - backend:
          serviceName: rancher
          servicePort: 80
  tls:
  - hosts:
    - rancher.minminmsn.com
    secretName: tls-rancher-ingress
status:
  loadBalancer: {}
~                                                     
```

**登陆rancher设置环境**
默认密码为admin需要设置复杂密码，默认语言为英文可以改为中文，默认管理本地k8s集群
![](https://upload-images.jianshu.io/upload_images/7535971-023c734b1a040f6a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


**添加TKE集群**
创建ptech集群并导入，需要在ptech集群上执行如下
```
[root@VM_0_65_centos ~]# kubectl apply -f https://rancher.minminmsn.com/v3/import/lvkfcctjfm4w52llbwng5cq7q8wwmzvqt9cm9825w8gzvkkp5748mg.yaml
clusterrole.rbac.authorization.k8s.io/proxy-clusterrole-kubeapiserver unchanged
clusterrolebinding.rbac.authorization.k8s.io/proxy-role-binding-kubernetes-master unchanged
namespace/cattle-system unchanged
serviceaccount/cattle unchanged
clusterrolebinding.rbac.authorization.k8s.io/cattle-admin-binding unchanged
secret/cattle-credentials-943258c created
clusterrole.rbac.authorization.k8s.io/cattle-admin unchanged
deployment.apps/cattle-cluster-agent configured
daemonset.apps/cattle-node-agent configured
You have new mail in /var/spool/mail/root
```


创建enterprise集群并导入，需要在enterprise集群上执行如下
```
[root@VM_8_15_centos ~]# kubectl apply -f https://rancher.minminmsn.com/v3/import/xv4psldq5jsbxrj2h6pfmf22dfrcj5vzpk2tts9xjvlmnnmtbnd9rl.yaml
clusterrole.rbac.authorization.k8s.io/proxy-clusterrole-kubeapiserver unchanged
clusterrolebinding.rbac.authorization.k8s.io/proxy-role-binding-kubernetes-master unchanged
namespace/cattle-system unchanged
serviceaccount/cattle unchanged
clusterrolebinding.rbac.authorization.k8s.io/cattle-admin-binding unchanged
secret/cattle-credentials-edbe822 created
clusterrole.rbac.authorization.k8s.io/cattle-admin unchanged
deployment.apps/cattle-cluster-agent configured
daemonset.apps/cattle-node-agent configured
```

**最终效果如下**
![](https://upload-images.jianshu.io/upload_images/7535971-1abef3314016a471.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)




