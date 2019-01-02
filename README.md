##Kubernetes1.13.1部署Kuberneted-dashboard v1.10.1版本
### 参考文档
```
https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/#deploying-the-dashboard-ui
https://github.com/kubernetes/kubernetes/tree/7f23a743e8c23ac6489340bbb34fa6f1d392db9d/cluster/addons/dashboard
https://github.com/kubernetes/dashboard
https://blog.csdn.net/nklinsirui/article/details/80581286
https://github.com/kubernetes/dashboard/issues/3472
```


### 一、填坑
按照官网文档一条命令即可，但是国内显然不是这样，首先要填许多坑才行
坑一：Docker镜像
##### 1、注册阿里云账户构建自己的镜像
可以关联github构建，这样就可以把国外镜像生成为阿里云镜像
https://github.com/minminmsn/k8s1.13/tree/master/kubernetes-dashboard-amd64/Dockerfile
##### 2、下载docker镜像
docker pull registry.cn-beijing.aliyuncs.com/minminmsn/kubernetes-dashboard:v1.10.1


### 坑二：SSL证书
证书不对或者用auto创建的证书会报错，报错见https://github.com/kubernetes/dashboard/issues/3472
##### 1、如果购买有的证书的话，把证书文件放在certs/目录下创建secret即可
```
[root@elasticsearch01 /]# ls certs/
minminmsn.crt  minminmsn.csr  minminmsn.key

[root@elasticsearch01 /]# kubectl create secret generic kubernetes-dashboard-certs --from-file=certs -n kube-system
secret/kubernetes-dashboard-certs created
```

##### 2、如果没有购买的话需要自定义生成证书，步骤如下
```
[root@elasticsearch01 /]# mkdir /certs
[root@elasticsearch01 /]# openssl req -nodes -newkey rsa:2048 -keyout certs/dashboard.key -out certs/dashboard.csr -subj "/C=/ST=/L=/O=/OU=/CN=kubernetes-dashboard"
Generating a 2048 bit RSA private key
................+++
..............................................+++
writing new private key to 'certs/dashboard.key'
-----
No value provided for Subject Attribute C, skipped
No value provided for Subject Attribute ST, skipped
No value provided for Subject Attribute L, skipped
No value provided for Subject Attribute O, skipped
No value provided for Subject Attribute OU, skipped
[root@elasticsearch01 /]# ls /certs
dashboard.csr  dashboard.key

[root@elasticsearch01 /]# openssl x509 -req -sha256 -days 365 -in certs/dashboard.csr -signkey certs/dashboard.key -out certs/dashboard.crt
Signature ok
subject=/CN=kubernetes-dashboard
Getting Private key
[root@elasticsearch01 /]# ls certs/
dashboard.crt  dashboard.csr  dashboard.key

[root@elasticsearch01 /]# kubectl create secret generic kubernetes-dashboard-certs --from-file=certs -n kube-system
secret/kubernetes-dashboard-certs created
```

### 坑三：修改service配置，将type: ClusterIP改成NodePort,便于通过Node端口访问
```
[root@elasticsearch01 /]# wget https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml
[root@elasticsearch01 /]# vim /k8s/yaml/kubernetes-dashboard.yaml 
kind: Service
apiVersion: v1
metadata:
  labels:
    k8s-app: kubernetes-dashboard
  name: kubernetes-dashboard
  namespace: kube-system
spec:
  type: NodePort
  ports:
    - port: 443
      targetPort: 8443
  selector:
    k8s-app: kubernetes-dashboard
                                      
```


### 二、部署Kubernetes-dashboard
修改镜像地址为registry.cn-beijing.aliyuncs.com/minminmsn/kubernetes-dashboard:v1.10.1即可部署
```
[root@elasticsearch01 /]# vim /k8s/yaml/kubernetes-dashboard.yaml 
    spec:
      containers:
      - name: kubernetes-dashboard
        image: registry.cn-beijing.aliyuncs.com/minminmsn/kubernetes-dashboard:v1.10.1


[root@elasticsearch01 /]# kubectl create -f /k8s/yaml/kubernetes-dashboard.yaml 
serviceaccount/kubernetes-dashboard created
role.rbac.authorization.k8s.io/kubernetes-dashboard-minimal created
rolebinding.rbac.authorization.k8s.io/kubernetes-dashboard-minimal created
deployment.apps/kubernetes-dashboard created
service/kubernetes-dashboard created
Error from server (AlreadyExists): error when creating "/k8s/yaml/kubernetes-dashboard.yaml": secrets "kubernetes-dashboard-certs" already exists


[root@elasticsearch01 /]# kubectl get pods -n kube-system
NAME                                   READY   STATUS    RESTARTS   AGE
kubernetes-dashboard-cb55bd5bd-4jsh7   1/1     Running   0          21s
[root@elasticsearch01 /]# kubectl get svc -n kube-system
NAME                   TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)         AGE
kubernetes-dashboard   NodePort   10.254.140.115   <none>        443:41579/TCP   31s
[root@elasticsearch01 /]# kubectl get pods -n kube-system -o wide
NAME                                   READY   STATUS    RESTARTS   AGE   IP            NODE        NOMINATED NODE   READINESS GATES
kubernetes-dashboard-cb55bd5bd-4jsh7   1/1     Running   0          40s   10.254.73.2   10.2.8.34   <none>           <none>
```

### 三、访问dashboard
##### 1、注意有证书需要域名访问，如果有DNS可以配置域名解析，没有Host绑定即可

##### 2、选择token访问，token获取方法如下
```
[root@elasticsearch01 ~]# cat /k8s/yaml/admin-token.yaml 
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: admin
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
subjects:
- kind: ServiceAccount
  name: admin
  namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin
  namespace: kube-system
  labels:
    kubernetes.io/cluster-service: "true"
    addonmanager.kubernetes.io/mode: Reconcile
```

```
[root@elasticsearch01 yaml]# kubectl create -f admin-token.yaml 
clusterrolebinding.rbac.authorization.k8s.io/admin created
serviceaccount/admin created

[root@elasticsearch01 yaml]#  kubectl describe secret/$(kubectl get secret -nkube-system |grep admin|awk '{print $1}') -nkube-system
Name:         admin-token-5j2vf
Namespace:    kube-system
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: admin
              kubernetes.io/service-account.uid: 6b0b0c00-0b45-11e9-85fe-52540089b2b6

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1359 bytes
namespace:  11 bytes
token:      eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi10b2tlbi01ajJ2ZiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJhZG1pbiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjZiMGIwYzAwLTBiNDUtMTFlOS04NWZlLTUyNTQwMDg5YjJiNiIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlLXN5c3RlbTphZG1pbiJ9.TkpDjrLRiulxgOjm6AWGeiCIRDHTeCUR87lme6cY4YnLFFyC1MTiw2JWvTYeksYvGcaEIlope97Don-zk5oNn5q1HYgwZeY844KXRyYSQ3vVlC1lg1xMvIZSrfLuK7ek-jHB_pAxE1S2KGfjg1srfdDRHBHgBEaOIMB6DrkJvVMI-hVHxtL5ctwCpZ1iIo1XVyu83SgMUz2HnVE1TST8NL-s0KtR0rnz-Ve4YvJZ1_Jj9hKvMblS_APWetcqT0Trsf-VuZgfKxuRcOmOkFFRKV-ZSwU7i9umQabIWhD6xZ7dTsvogGCx4o0kgBOLwrwj-pUbgAyu7pmbbAbjOJ06cQ
```
3、效果如下
https://k8s.minminmsn.com
输入token
eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi10b2tlbi01ajJ2ZiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJhZG1pbiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjZiMGIwYzAwLTBiNDUtMTFlOS04NWZlLTUyNTQwMDg5YjJiNiIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlLXN5c3RlbTphZG1pbiJ9.TkpDjrLRiulxgOjm6AWGeiCIRDHTeCUR87lme6cY4YnLFFyC1MTiw2JWvTYeksYvGcaEIlope97Don-zk5oNn5q1HYgwZeY844KXRyYSQ3vVlC1lg1xMvIZSrfLuK7ek-jHB_pAxE1S2KGfjg1srfdDRHBHgBEaOIMB6DrkJvVMI-hVHxtL5ctwCpZ1iIo1XVyu83SgMUz2HnVE1TST8NL-s0KtR0rnz-Ve4YvJZ1_Jj9hKvMblS_APWetcqT0Trsf-VuZgfKxuRcOmOkFFRKV-ZSwU7i9umQabIWhD6xZ7dTsvogGCx4o0kgBOLwrwj-pUbgAyu7pmbbAbjOJ06cQ



[![](https://i.loli.net/2019/01/02/5c2c7ce87af87.png)](https://i.loli.net/2019/01/02/5c2c7ce87af87.png)



### 补充
>Apiserver hosts绑定ip错误10.0.0.1应该是10.254.0.1，默认pods网端是10.254.0.0/16，其中10.254.0.1会用来kubenetes的clusterip
[root@elasticsearch01 ~]# kubectl get svc --all-namespaces=true
NAMESPACE     NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)         AGE
default       kubernetes             ClusterIP   10.254.0.1      <none>        443/TCP         6d1h


解决方法
×××文件重启apiserver服务即可（配置前多检查，否则后面会增加很多排错过程）
```
[root@elasticsearch01 yaml]# kubectl logs kubernetes-dashboard-865b64d96f-g5f9t --namespace=kube-system
2018/12/29 07:49:44 Starting overwatch
2018/12/29 07:49:44 Using in-cluster config to connect to apiserver
2018/12/29 07:49:44 Using service account token for csrf signing
2018/12/29 07:49:44 Error while initializing connection to Kubernetes apiserver. This most likely means that the cluster is misconfigured (e.g., it has invalid apiserver certificates or service account's configuration) or the --apiserver-host param points to a server that does not exist. Reason: Get https://10.254.0.1:443/version: x509: certificate is valid for 10.0.0.1, 127.0.0.1, 10.2.8.44, 10.2.8.65, 10.2.8.34, not 10.254.0.1
Refer to our FAQ and wiki pages for more information: https://github.com/kubernetes/dashboard/wiki/FAQ
```

修改Hosts里10.0.0.1为10.254.0.1
```
[root@elasticsearch01 ssl]# cat server-csr.json 
{
    "CN": "kubernetes",
    "hosts": [
      "10.254.0.1",
      "127.0.0.1",
      "10.2.8.44",
      "10.2.8.65",
      "10.2.8.34",
      "kubernetes",
      "kubernetes.default",
      "kubernetes.default.svc",
      "kubernetes.default.svc.cluster",
      "kubernetes.default.svc.cluster.local"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing",
            "O": "k8s",
            "OU": "System"
        }
    ]
}
```

同步证书并重启服务
```
[root@elasticsearch01 ssl]# cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes server-csr.json | cfssljson -bare server
2018/12/29 15:57:02 [INFO] generate received request
2018/12/29 15:57:02 [INFO] received CSR
2018/12/29 15:57:02 [INFO] generating key: rsa-2048
2018/12/29 15:57:03 [INFO] encoded CSR
2018/12/29 15:57:03 [INFO] signed certificate with serial number 57756035754570455349189088480535470836534926573
2018/12/29 15:57:03 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
websites. For more information see the Baseline Requirements for the Issuance and Management
of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
specifically, section 10.2.3 ("Information Requirements").

[root@elasticsearch01 ssl]# scp server-csr.json server.csr server-key.pem server.pem 10.2.8.65:$PWD
[root@elasticsearch01 ssl]# scp server-csr.json server.csr server-key.pem server.pem 10.2.8.34:$PWD
[root@elasticsearch01 ssl]# systemctl restart kube-apiserver
[root@elasticsearch01 ssl]# systemctl restart kube-scheduler
[root@elasticsearch01 ssl]# systemctl restart kube-controller-manager
```


