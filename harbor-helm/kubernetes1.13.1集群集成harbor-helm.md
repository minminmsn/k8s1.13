### 参考文章

```
https://github.com/goharbor/harbor-helm
https://www.hi-linux.com/posts/14136.html
https://github.com/kubernetes-incubator/external-storage/tree/master/ceph/rbd
https://github.com/kubernetes-incubator/external-storage/tree/master/ceph/rbd/deploy/rbac
https://github.com/helm/helm/issues/3130
https://www.kancloud.cn/huyipow/kubernetes/531999
https://www.hi-linux.com/posts/14136.html
https://li-sen.github.io/2018/10/08/k8s%E9%83%A8%E7%BD%B2%E9%AB%98%E5%8F%AF%E7%94%A8harbor/
```


### 依赖关系
```
Kubernetes cluster 1.10+
kubernetes集群版本1.13.1

Helm 2.8.0+

ingress
用于外部访问集群内部环境

rbd-provisioner
ceph rbd 客户端，可以创建、删除ceph rbd pool、image等

storageclass
用于自动创建pv与pvc

ceph rbd
ceph集群luminous版本
```


### 操作步骤

##### 一、部署rbd-provisioner

**1、下载external-storage**
```
[root@elasticsearch01 yaml]# git clone https://github.com/kubernetes-incubator/external-storage
[root@elasticsearch01 yaml]# cd external-storage/ceph/rbd/deploy/rbac/
[root@elasticsearch01 rbac]# ls
clusterrolebinding.yaml  deployment.yaml          role.yaml                
clusterrole.yaml         rolebinding.yaml         serviceaccount.yaml 
[root@elasticsearch01 rbac]# mkdir /k8s/yaml/volumes/rbd-provisioner
[root@elasticsearch01 rbac]# cp * /k8s/yaml/volumes/rbd-provisioner/
[root@elasticsearch01 rbac]# cd /k8s/yaml/volumes/rbd-provisioner/
```

**2、创建rbd-provisioner角色、pod**
```    
[root@elasticsearch01 rbd-provisioner]# ls
clusterrolebinding.yaml  deployment.yaml          role.yaml                
clusterrole.yaml         rolebinding.yaml         serviceaccount.yaml      
[root@elasticsearch01 rbd-provisioner]# kubectl create -f ./
clusterrole.rbac.authorization.k8s.io/rbd-provisioner created
clusterrolebinding.rbac.authorization.k8s.io/rbd-provisioner created
deployment.extensions/rbd-provisioner created
role.rbac.authorization.k8s.io/rbd-provisioner created
rolebinding.rbac.authorization.k8s.io/rbd-provisioner created
serviceaccount/rbd-provisioner created
```

**3、验证rbd-provisioner**
```
[root@elasticsearch01 rbd-provisioner]# kubectl get pods
NAME                               READY   STATUS    RESTARTS   AGE
busybox                            1/1     Running   600        25d
ceph-rbd-pv-pod1                   1/1     Running   10         6d23h
jenkins-0                          1/1     Running   0          6d1h
rbd-provisioner-67b4857bcd-xxwx5   1/1     Running   0          9s
```

##### 二、部署storageclass
**1、修改storageclass配置**
参考external-storage/gluster/glusterfs/deploy/storageclass.yaml样例根据自己情况修改，其中secretName在kubernetes集群使用ceph rbd块存储时已经创建过
```
[root@elasticsearch01 rbd-provisioner]# cat storageclass.yaml 
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: rbd
provisioner: ceph.com/rbd
parameters:
  monitors: 10.0.4.10:6789
  pool: rbd-k8s
  adminId: admin
  adminSecretNamespace: default
  adminSecretName: ceph-secret
  userSecretName: ceph-secret
  userId: admin
  userSecretNamespace: default
  userSecretName: ceph-secret
  imageFormat: "2"
  imageFeatures: layering
```

**2、创建storageclass rbd**
```
[root@elasticsearch01 harbor-helm]# kubectl create -f storageclass.yaml 
storageclass.storage.k8s.io/rbd created

[root@elasticsearch01 harbor-helm]# kubectl get storageclasses
NAME   PROVISIONER    AGE
rbd    ceph.com/rbd   2m
```

##### 三、部署harbor-helm
**1、下载harbor-helm 1.0.0版本的源码**
```
[root@elasticsearch01 yaml]# git clone https://github.com/goharbor/harbor-helm.git
[root@elasticsearch01 yaml]# cd harbor-helm/
[root@elasticsearch01 harbor-helm]# git checkout 1.0.0
[root@elasticsearch01 harbor-helm]# ls
Chart.yaml  CONTRIBUTING.md  docs  LICENSE  README.md    templates  values.yaml
```

**2、修改values.yaml配置**
需要根据实际情况修改values.yaml配置文件，主要修改如下几个地方
```
admin
登陆密码

storageclass
这里是rbd

ingress
修改自己的域名

secretName
tls的秘钥
```

修改后具体如下
```
[root@elasticsearch01 harbor-helm]# cat values.yaml 
expose:
  # Set the way how to expose the service. Set the type as "ingress", 
  # "clusterIP" or "nodePort" and fill the information in the corresponding 
  # section
  type: ingress
  tls:
    # Enable the tls or not. Note: if the type is "ingress" and the tls 
    # is disabled, the port must be included in the command when pull/push
    # images. Refer to https://github.com/goharbor/harbor/issues/5291 
    # for the detail.
    enabled: true
    # Fill the name of secret if you want to use your own TLS certificate
    # and private key. The secret must contain keys named tls.crt and 
    # tls.key that contain the certificate and private key to use for TLS
    # The certificate and private key will be generated automatically if 
    # it is not set
    secretName: "ingress-secret"
    # By default, the Notary service will use the same cert and key as
    # described above. Fill the name of secret if you want to use a 
    # separated one. Only needed when the type is "ingress".
    notarySecretName: ""
    # The commmon name used to generate the certificate, it's necessary
    # when the type is "clusterIP" or "nodePort" and "secretName" is null
    commonName: ""
  ingress:
    hosts:
      core: core-harbor.minminmsn.com
      notary: notary-harbor.minminmsn.com
    annotations:
      ingress.kubernetes.io/ssl-redirect: "true"
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
      ingress.kubernetes.io/proxy-body-size: "0"
      nginx.ingress.kubernetes.io/proxy-body-size: "0"
  clusterIP:
    # The name of ClusterIP service
    name: harbor
    ports:
      # The service port Harbor listens on when serving with HTTP
      httpPort: 80
      # The service port Harbor listens on when serving with HTTPS
      httpsPort: 443
      # The service port Notary listens on. Only needed when notary.enabled 
      # is set to true
      notaryPort: 4443
  nodePort:
    # The name of NodePort service
    name: harbor
    ports:
      http:
        # The service port Harbor listens on when serving with HTTP
        port: 80
        # The node port Harbor listens on when serving with HTTP
        nodePort: 30002
      https: 
        # The service port Harbor listens on when serving with HTTPS
        port: 443
        # The node port Harbor listens on when serving with HTTPS
        nodePort: 30003
      # Only needed when notary.enabled is set to true
      notary: 
        # The service port Notary listens on
        port: 4443
        # The node port Notary listens on
        nodePort: 30004

# The external URL for Harbor core service. It is used to
# 1) populate the docker/helm commands showed on portal
# 2) populate the token service URL returned to docker/notary client
# 
# Format: protocol://domain[:port]. Usually:
# 1) if "expose.type" is "ingress", the "domain" should be 
# the value of "expose.ingress.hosts.core"
# 2) if "expose.type" is "clusterIP", the "domain" should be
# the value of "expose.clusterIP.name"
# 3) if "expose.type" is "nodePort", the "domain" should be
# the IP address of k8s node 
# 
# If Harbor is deployed behind the proxy, set it as the URL of proxy
externalURL: https://core-harbor.minminmsn.com

# The persistence is enabled by default and a default StorageClass
# is needed in the k8s cluster to provision volumes dynamicly. 
# Specify another StorageClass in the "storageClass" or set "existingClaim"
# if you have already existing persistent volumes to use
#
# For storing images and charts, you can also use "azure", "gcs", "s3", 
# "swift" or "oss". Set it in the "imageChartStorage" section
persistence:
  enabled: true
  # Setting it to "keep" to avoid removing PVCs during a helm delete 
  # operation. Leaving it empty will delete PVCs after the chart deleted
  resourcePolicy: "keep"
  persistentVolumeClaim:
    registry:
      # Use the existing PVC which must be created manually before bound
      existingClaim: ""
      # Specify the "storageClass" used to provision the volume. Or the default
      # StorageClass will be used(the default).
      # Set it to "-" to disable dynamic provisioning
      storageClass: "rbd"
      subPath: ""
      accessMode: ReadWriteOnce
      size: 50Gi
    chartmuseum:
      existingClaim: ""
      storageClass: "rbd"
      subPath: ""
      accessMode: ReadWriteOnce
      size: 5Gi
    jobservice:
      existingClaim: ""
      storageClass: "rbd"
      subPath: ""
      accessMode: ReadWriteOnce
      size: 2Gi
    # If external database is used, the following settings for database will 
    # be ignored
    database:
      existingClaim: ""
      storageClass: "rbd"
      subPath: ""
      accessMode: ReadWriteOnce
      size: 2Gi
    # If external Redis is used, the following settings for Redis will 
    # be ignored
    redis:
      existingClaim: ""
      storageClass: "rbd"
      subPath: ""
      accessMode: ReadWriteOnce
      size: 2Gi
  # Define which storage backend is used for registry and chartmuseum to store
  # images and charts. Refer to 
  # https://github.com/docker/distribution/blob/master/docs/configuration.md#storage 
  # for the detail.
  imageChartStorage:
    # Specify the type of storage: "filesystem", "azure", "gcs", "s3", "swift", 
    # "oss" and fill the information needed in the corresponding section. The type
    # must be "filesystem" if you want to use persistent volumes for registry
    # and chartmuseum
    type: filesystem
    filesystem:
      rootdirectory: /storage
      #maxthreads: 100
    azure:
      accountname: accountname
      accountkey: base64encodedaccountkey
      container: containername
      #realm: core.windows.net
    gcs:
      bucket: bucketname
      # TODO: support the keyfile of gcs
      #keyfile: /path/to/keyfile
      #rootdirectory: /gcs/object/name/prefix
      #chunksize: "5242880"
    s3:
      region: us-west-1
      bucket: bucketname
      #accesskey: awsaccesskey
      #secretkey: awssecretkey
      #regionendpoint: http://myobjects.local
      #encrypt: false
      #keyid: mykeyid
      #secure: true
      #v4auth: true
      #chunksize: "5242880"
      #rootdirectory: /s3/object/name/prefix
      #storageclass: STANDARD
    swift:
      authurl: https://storage.myprovider.com/v3/auth
      username: username
      password: password
      container: containername
      #region: fr
      #tenant: tenantname
      #tenantid: tenantid
      #domain: domainname
      #domainid: domainid
      #trustid: trustid
      #insecureskipverify: false
      #chunksize: 5M
      #prefix:
      #secretkey: secretkey
      #accesskey: accesskey
      #authversion: 3
      #endpointtype: public
      #tempurlcontainerkey: false
      #tempurlmethods:
    oss:
      accesskeyid: accesskeyid
      accesskeysecret: accesskeysecret
      region: regionname
      bucket: bucketname
      #endpoint: endpoint
      #internal: false
      #encrypt: false
      #secure: true
      #chunksize: 10M
      #rootdirectory: rootdirectory

imagePullPolicy: IfNotPresent

logLevel: debug
# The initial password of Harbor admin. Change it from portal after launching Harbor
harborAdminPassword: "newpassword"
# The secret key used for encryption. Must be a string of 16 chars.
secretKey: "not-a-secure-key"

# If expose the service via "ingress", the Nginx will not be used
nginx:
  image:
    repository: goharbor/nginx-photon
    tag: v1.7.0
  replicas: 1
  # resources:
  #  requests:
  #    memory: 256Mi
  #    cpu: 100m
  nodeSelector: {}
  tolerations: []
  affinity: {}
  ## Additional deployment annotations
  podAnnotations: {}

portal:
  image:
    repository: goharbor/harbor-portal
    tag: v1.7.0
  replicas: 1
# resources:
#  requests:
#    memory: 256Mi
#    cpu: 100m
  nodeSelector: {}
  tolerations: []
  affinity: {}
  ## Additional deployment annotations
  podAnnotations: {}

core:
  image:
    repository: goharbor/harbor-core
    tag: v1.7.0
  replicas: 1
# resources:
#  requests:
#    memory: 256Mi
#    cpu: 100m
  nodeSelector: {}
  tolerations: []
  affinity: {}
  ## Additional deployment annotations
  podAnnotations: {}

adminserver:
  image:
    repository: goharbor/harbor-adminserver
    tag: v1.7.0
  replicas: 1
  # resources:
  #  requests:
  #    memory: 256Mi
  #    cpu: 100m
  nodeSelector: {}
  tolerations: []
  affinity: {}
  ## Additional deployment annotations
  podAnnotations: {}

jobservice:
  image:
    repository: goharbor/harbor-jobservice
    tag: v1.7.0
  replicas: 1
  maxJobWorkers: 10
  # The logger for jobs: "file", "database" or "stdout"
  jobLogger: file
# resources:
#   requests:
#     memory: 256Mi
#     cpu: 100m
  nodeSelector: {}
  tolerations: []
  affinity: {}
  ## Additional deployment annotations
  podAnnotations: {}

registry:
  registry:
    image:
      repository: goharbor/registry-photon
      tag: v2.6.2-v1.7.0
  controller:
    image:
      repository: goharbor/harbor-registryctl
      tag: v1.7.0
  replicas: 1
  # resources:
  #  requests:
  #    memory: 256Mi
  #    cpu: 100m
  nodeSelector: {}
  tolerations: []
  affinity: {}
  ## Additional deployment annotations
  podAnnotations: {}

chartmuseum:
  enabled: true
  image:
    repository: goharbor/chartmuseum-photon
    tag: v0.7.1-v1.7.0
  replicas: 1
  # resources:
  #  requests:
  #    memory: 256Mi
  #    cpu: 100m
  nodeSelector: {}
  tolerations: []
  affinity: {}
  ## Additional deployment annotations
  podAnnotations: {}

clair:
  enabled: true
  image:
    repository: goharbor/clair-photon
    tag: v2.0.7-v1.7.0
  replicas: 1
  # The http(s) proxy used to update vulnerabilities database from internet
  httpProxy:
  httpsProxy:
  # The interval of clair updaters, the unit is hour, set to 0 to 
  # disable the updaters
  updatersInterval: 12
  # resources:
  #  requests:
  #    memory: 256Mi
  #    cpu: 100m
  nodeSelector: {}
  tolerations: []
  affinity: {}
  ## Additional deployment annotations
  podAnnotations: {}

notary:
  enabled: true
  server:
    image:
      repository: goharbor/notary-server-photon
      tag: v0.6.1-v1.7.0
    replicas: 1
  signer:
    image:
      repository: goharbor/notary-signer-photon
      tag: v0.6.1-v1.7.0
    replicas: 1
  nodeSelector: {}
  tolerations: []
  affinity: {}
  ## Additional deployment annotations
  podAnnotations: {}

database:
  # if external database is used, set "type" to "external"
  # and fill the connection informations in "external" section
  type: internal
  internal:
    image:
      repository: goharbor/harbor-db
      tag: v1.7.0
    # The initial superuser password for internal database
    password: "changeit"
    # resources:
    #  requests:
    #    memory: 256Mi
    #    cpu: 100m
    nodeSelector: {}
    tolerations: []
    affinity: {}
  external:
    host: "192.168.0.1"
    port: "5432"
    username: "user"
    password: "password"
    coreDatabase: "registry"
    clairDatabase: "clair"
    notaryServerDatabase: "notary_server"
    notarySignerDatabase: "notary_signer"
    sslmode: "disable"
  ## Additional deployment annotations
  podAnnotations: {}

redis:
  # if external Redis is used, set "type" to "external"
  # and fill the connection informations in "external" section
  type: internal
  internal:
    image:
      repository: goharbor/redis-photon
      tag: v1.7.0
    # resources:
    #  requests:
    #    memory: 256Mi
    #    cpu: 100m
    nodeSelector: {}
    tolerations: []
    affinity: {}
  external:
    host: "10.2.8.44"
    port: "6379"
    # The "coreDatabaseIndex" must be "0" as the library Harbor
    # used doesn't support configuring it
    coreDatabaseIndex: "0"
    jobserviceDatabaseIndex: "1"
    registryDatabaseIndex: "2"
    chartmuseumDatabaseIndex: "3"
    password: ""
  ## Additional deployment annotations
  podAnnotations: {}
```

**4、helm 初始化安装harbor**
```
[root@elasticsearch01 harbor-helm]# helm install . --name min
NAME:   min
LAST DEPLOYED: Mon Jan 28 17:01:09 2019
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/PersistentVolumeClaim
NAME                    STATUS   VOLUME  CAPACITY  ACCESS MODES  STORAGECLASS  AGE
min-harbor-chartmuseum  Pending  1s
min-harbor-jobservice   Pending  1s
min-harbor-registry     Pending  1s

==> v1/Service
NAME                      TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)            AGE
min-harbor-adminserver    ClusterIP  10.254.7.52     <none>       80/TCP             1s
min-harbor-chartmuseum    ClusterIP  10.254.80.86    <none>       80/TCP             1s
min-harbor-clair          ClusterIP  10.254.221.71   <none>       6060/TCP           0s
min-harbor-core           ClusterIP  10.254.114.190  <none>       80/TCP             0s
min-harbor-database       ClusterIP  10.254.146.141  <none>       5432/TCP           0s
min-harbor-jobservice     ClusterIP  10.254.21.20    <none>       80/TCP             0s
min-harbor-notary-server  ClusterIP  10.254.255.218  <none>       4443/TCP           0s
min-harbor-notary-signer  ClusterIP  10.254.203.88   <none>       7899/TCP           0s
min-harbor-portal         ClusterIP  10.254.73.42    <none>       80/TCP             0s
min-harbor-redis          ClusterIP  10.254.134.216  <none>       6379/TCP           0s
min-harbor-registry       ClusterIP  10.254.69.96    <none>       5000/TCP,8080/TCP  0s

==> v1/Deployment
NAME                      DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
min-harbor-adminserver    1        1        1           0          0s
min-harbor-chartmuseum    1        1        1           0          0s
min-harbor-clair          1        1        1           0          0s
min-harbor-core           1        0        0           0          0s
min-harbor-jobservice     1        0        0           0          0s
min-harbor-notary-server  1        0        0           0          0s
min-harbor-notary-signer  1        0        0           0          0s
min-harbor-portal         1        0        0           0          0s
min-harbor-registry       1        0        0           0          0s

==> v1/StatefulSet
NAME                 DESIRED  CURRENT  AGE
min-harbor-database  1        1        0s
min-harbor-redis     1        1        0s

==> v1beta1/Ingress
NAME                HOSTS                                                    ADDRESS  PORTS  AGE
min-harbor-ingress  core-harbor.minminmsn.com,notary-harbor.minminmsn.com  80, 443  0s

==> v1/Pod(related)
NAME                                       READY  STATUS             RESTARTS  AGE
min-harbor-adminserver-54877f95bd-45vq2    0/1    ContainerCreating  0         0s
min-harbor-chartmuseum-7d59b659df-jkt9f    0/1    Pending            0         0s
min-harbor-clair-69f89c644-hg6qp           0/1    ContainerCreating  0         0s
min-harbor-core-5cdff64cc8-9vw2w           0/1    ContainerCreating  0         0s
min-harbor-jobservice-bbdf5bbcd-qsz9h      0/1    Pending            0         0s
min-harbor-notary-server-dcbccf89b-9gpsp   0/1    Pending            0         0s
min-harbor-notary-signer-5d45d46d64-d4sjg  0/1    ContainerCreating  0         0s
min-harbor-database-0                      0/1    Pending            0         0s
min-harbor-redis-0                         0/1    Pending            0         0s

==> v1/Secret
NAME                    TYPE               DATA  AGE
min-harbor-adminserver  Opaque             4     1s
min-harbor-chartmuseum  Opaque             1     1s
min-harbor-core         Opaque             4     1s
min-harbor-database     Opaque             1     1s
min-harbor-ingress      kubernetes.io/tls  3     1s
min-harbor-jobservice   Opaque             1     1s
min-harbor-registry     Opaque             1     1s

==> v1/ConfigMap
NAME                      DATA  AGE
min-harbor-adminserver    39    1s
min-harbor-chartmuseum    24    1s
min-harbor-clair          1     1s
min-harbor-core           1     1s
min-harbor-jobservice     1     1s
min-harbor-notary-server  5     1s
min-harbor-registry       2     1s


NOTES:
Please wait for several minutes for Harbor deployment to complete.
Then you should be able to visit the Harbor portal at https://core-harbor.minminmsn.com. 
For more details, please visit https://github.com/goharbor/harbor.
```

**5、验证pv与pvc**
主要是pv与pvc如果没有自动创建存储的条件需要提前手动创建好pv几pvc，然后value.yaml文件里选择existingClaim，填写各自pvc的名字即可
```
[root@elasticsearch01 harbor-helm]# kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                                         STORAGECLASS   REASON   AGE
ceph-rbd-pv                                20Gi       RWO            Recycle          Bound    default/ceph-rbd-pv-claim                                             7d1h
jenkins-home-pv                            40Gi       RWO            Recycle          Bound    default/jenkins-home-pvc                                              6d2h
pvc-84079273-22de-11e9-a09d-52540089b2b6   5Gi        RWO            Delete           Bound    default/min-harbor-chartmuseum                rbd                     43s
pvc-84085284-22de-11e9-a09d-52540089b2b6   2Gi        RWO            Delete           Bound    default/min-harbor-jobservice                 rbd                     56s
pvc-840a9404-22de-11e9-a09d-52540089b2b6   50Gi       RWO            Delete           Bound    default/min-harbor-registry                   rbd                     56s
pvc-844d2f2d-22de-11e9-a09d-52540089b2b6   2Gi        RWO            Delete           Bound    default/database-data-min-harbor-database-0   rbd                     43s
pvc-8455d703-22de-11e9-a09d-52540089b2b6   2Gi        RWO            Delete           Bound    default/data-min-harbor-redis-0               rbd                     43s


[root@elasticsearch01 harbor-helm]# kubectl get pvc
NAME                                  STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
ceph-rbd-pv-claim                     Bound    ceph-rbd-pv                                20Gi       RWO                           7d1h
data-min-harbor-redis-0               Bound    pvc-8455d703-22de-11e9-a09d-52540089b2b6   2Gi        RWO            rbd            46s
database-data-min-harbor-database-0   Bound    pvc-844d2f2d-22de-11e9-a09d-52540089b2b6   2Gi        RWO            rbd            46s
jenkins-home-pvc                      Bound    jenkins-home-pv                            40Gi       RWO                           6d2h
min-harbor-chartmuseum                Bound    pvc-84079273-22de-11e9-a09d-52540089b2b6   5Gi        RWO            rbd            46s
min-harbor-jobservice                 Bound    pvc-84085284-22de-11e9-a09d-52540089b2b6   2Gi        RWO            rbd            46s
min-harbor-registry                   Bound    pvc-840a9404-22de-11e9-a09d-52540089b2b6   50Gi       RWO            rbd            46s
```

**6、验证ceph rbd**
```
[root@ceph01 ~]# rbd list rbd-k8s
cephimage1
cephimage2
cephimage3
kubernetes-dynamic-pvc-8420311c-22de-11e9-b7ec-02420afe4907
kubernetes-dynamic-pvc-84203268-22de-11e9-b7ec-02420afe4907
kubernetes-dynamic-pvc-8bfd862e-22de-11e9-b7ec-02420afe4907
kubernetes-dynamic-pvc-8bfe7a4f-22de-11e9-b7ec-02420afe4907
kubernetes-dynamic-pvc-8bfe9445-22de-11e9-b7ec-02420afe4907
```

**7、验证pods**
```
[root@elasticsearch01 harbor-helm]# kubectl get pods
NAME                                        READY   STATUS    RESTARTS   AGE
busybox                                     1/1     Running   600        25d
ceph-rbd-pv-pod1                            1/1     Running   10         6d23h
jenkins-0                                   1/1     Running   0          6d2h
min-harbor-adminserver-685ccf67d7-k6z4p     1/1     Running   1          5m10s
min-harbor-chartmuseum-7d59b659df-nglbx     1/1     Running   0          5m10s
min-harbor-clair-69f89c644-62428            1/1     Running   1          5m10s
min-harbor-core-5cdd9c7bc9-z2lnd            1/1     Running   1          5m10s
min-harbor-database-0                       1/1     Running   0          5m10s
min-harbor-jobservice-9889c95b9-s656x       1/1     Running   0          5m10s
min-harbor-notary-server-588bc8bf45-t7mkz   1/1     Running   0          5m10s
min-harbor-notary-signer-6d967d4c-jhvfs     1/1     Running   0          5m10s
min-harbor-portal-798ff99d56-vxnnx          1/1     Running   0          5m9s
min-harbor-redis-0                          1/1     Running   0          5m10s
min-harbor-registry-54b5cd848d-4nr95        2/2     Running   0          5m9s
rbd-provisioner-67b4857bcd-xxwx5            1/1     Running   0          42m
```

**期间遇到各种报错可以重置helm环境**
```
[root@elasticsearch01 harbor-helm]# helm delete --purge min
These resources were kept due to the resource policy:
[PersistentVolumeClaim] min-harbor-chartmuseum
[PersistentVolumeClaim] min-harbor-jobservice
[PersistentVolumeClaim] min-harbor-registry

release "min" deleted

```

### 四、访问harobr

**1、获取harbor ingress 服务**
```
[root@elasticsearch01 harbor-helm]# kubectl get ingress
NAME                 HOSTS                                                     ADDRESS   PORTS     AGE
jenkins              jenkins.minminmsn.com                                              80, 443   6d2h
min-harbor-ingress   core-harbor.minminmsn.com,notary-harbor.minminmsn.com             80, 443   6m43s
```

**2、docker login登陆验证**
注意这里docker login默认是走https协议，需要ingress的node节点443对外开放，之前部署的ingress没有启动hostNetwork为true，这里需要启动，可以通过kubectl edit deployment/nginx-ingress-controller -n ingress-nginx修改，然后docker login就没问题了
登陆测试
```
[root@elasticsearch02 ~]# docker login core-harbor.minminmsn.com
Username: admin
Password: 
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded

```

上传下载测试

```
[root@elasticsearch02 ~]# docker tag registry.cn-beijing.aliyuncs.com/minminmsn/kubernetes-dashboard:v1.10.1 core-harbor.minminmsn.com/public/kubernetes-dashboard:v1.10.1
[root@elasticsearch02 ~]# docker push core-harbor.minminmsn.com/public/kubernetes-dashboard:v1.10.1
The push refers to repository [core-harbor.minminmsn.com/public/kubernetes-dashboard]
fbdfe08b001c: Pushed 
v1.10.1: digest: sha256:54cc02a35d33a5ff9f8aa1a1b43f375728bcd85034cb311bdaf5c14f48340733 size: 529

[root@elasticsearch03 ~]# docker pull core-harbor.minminmsn.com/public/kubernetes-dashboard:v1.10.1
v1.10.1: Pulling from public/kubernetes-dashboard
Digest: sha256:54cc02a35d33a5ff9f8aa1a1b43f375728bcd85034cb311bdaf5c14f48340733
Status: Downloaded newer image for core-harbor.minminmsn.com/public/kubernetes-dashboard:v1.10.1


```


**3、配置解析浏览器访问**
>  https://core-harbor.minminmsn.com
>  ![](https://upload-images.jianshu.io/upload_images/7535971-cbb76f4ee5e2b146.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![](https://upload-images.jianshu.io/upload_images/7535971-6de5ab146734be63.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)




