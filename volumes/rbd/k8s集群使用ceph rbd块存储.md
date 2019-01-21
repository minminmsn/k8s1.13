### **参考文档**
```
https://github.com/kubernetes/examples/tree/master/staging/volumes/rbd
http://docs.ceph.com/docs/mimic/rados/operations/pools/
https://blog.csdn.net/aixiaoyang168/article/details/78999851 
https://www.cnblogs.com/keithtt/p/6410302.html
https://kubernetes.io/docs/concepts/storage/volumes/
https://kubernetes.io/docs/concepts/storage/persistent-volumes/
https://blog.csdn.net/wenwenxiong/article/details/78406136
http://www.mamicode.com/info-detail-1701743.html
```

### **简介**
ceph支持对象存储，文件系统及块存储，是三合一存储类型，kubernetes的样例中有cephfs与rbd两种使用方式的介绍，cephfs需要node节点安装ceph才能支持，rbd需要node节点安装ceph-common才支持。
使用上的区别如下：
```
Volume Plugin	ReadWriteOnce	ReadOnlyMany	ReadWriteMany
CephFS				✓				✓				✓
RBD					✓				✓				-
```

### **基本环境**
k81集群1.13.1版本
```
[root@elasticsearch01 ~]# kubectl get nodes
NAME        STATUS   ROLES    AGE   VERSION
10.2.8.34   Ready    <none>   24d   v1.13.1
10.2.8.65   Ready    <none>   24d   v1.13.1
```

ceph集群 luminous版本
```
[root@ceph01 ~]# ceph -s
  services:
    mon: 3 daemons, quorum ceph01,ceph02,ceph03
    mgr: ceph03(active), standbys: ceph02, ceph01
    osd: 24 osds: 24 up, 24 in
    rgw: 3 daemons active
```

### **操作步骤**
#### **一、ceph集群创建ceph池及镜像**
```
[root@ceph01 ~]# ceph osd pool create rbd-k8s 1024 1024 
For better initial performance on pools expected to store a large number of objects, consider supplying the expected_num_objects parameter when creating the pool.

[root@ceph01 ~]# ceph osd lspools 
1 rbd-es,2 .rgw.root,3 default.rgw.control,4 default.rgw.meta,5 default.rgw.log,6 default.rgw.buckets.index,7 default.rgw.buckets.data,8 default.rgw.buckets.non-ec,9 rbd-k8s,

[root@ceph01 ~]# rbd create rbd-k8s/cephimage1 --size 10240
[root@ceph01 ~]# rbd create rbd-k8s/cephimage2 --size 20480
[root@ceph01 ~]# rbd create rbd-k8s/cephimage3 --size 40960
[root@ceph01 ~]# rbd list rbd-k8s
cephimage1
cephimage2
cephimage3
```


#### **二、k8s集群使用ceph rbd块存储**
**1、下载样例**
```
[root@elasticsearch01 ~]# git clone https://github.com/kubernetes/examples.git
Cloning into 'examples'...
remote: Enumerating objects: 11475, done.
remote: Total 11475 (delta 0), reused 0 (delta 0), pack-reused 11475
Receiving objects: 100% (11475/11475), 16.94 MiB | 6.00 MiB/s, done.
Resolving deltas: 100% (6122/6122), done.

[root@elasticsearch01 ~]# cd examples/staging/volumes/rbd
[root@elasticsearch01 rbd]# ls
rbd-with-secret.yaml  rbd.yaml  README.md  secret
[root@elasticsearch01 rbd]# cp -a ./rbd /k8s/yaml/volumes/
```

**2、k8s集群节点安装ceph客户端**
```
[root@elasticsearch01 ceph]# yum  install ceph-common
```

**3、修改rbd-with-secret.yaml配置文件**
修改后配置如下：
```
[root@elasticsearch01 rbd]# cat rbd-with-secret.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: rbd2
spec:
  containers:
    - image: kubernetes/pause
      name: rbd-rw
      volumeMounts:
      - name: rbdpd
        mountPath: /mnt/rbd
  volumes:
    - name: rbdpd
      rbd:
        monitors:
        - '10.0.4.10:6789'
        - '10.0.4.13:6789'
        - '10.0.4.15:6789'
        pool: rbd-k8s
        image: cephimage1
        fsType: ext4
        readOnly: true
        user: admin
        secretRef:
          name: ceph-secret
```

如下参数根据实际情况修改：
monitors：这是 Ceph集群的monitor 监视器，Ceph 集群可以配置多个 monitor，本配置3个mon
pool：这是Ceph集群中存储数据进行归类区分使用，这里用的pool为rbd-ceph
image：这是Ceph 块设备中的磁盘映像文件，这里用的是cephimage1
fsType：文件系统类型，默认使用 ext4 即可
readOnly：是否为只读，这里测试使用只读即可
user：这是Ceph Client访问Ceph存储集群所使用的用户名，这里我们使用admin 即可
keyring：这是Ceph集群认证需要的密钥环，搭建Ceph存储集群时生成的ceph.client.admin.keyring
imageformat：这是磁盘映像文件格式，可以使用 2，或者老一些的1，内核版本比较低的使用1
imagefeatures： 这是磁盘映像文件的特征，需要uname -r查看集群系统内核所支持的特性，这里Ceontos7.4内核版本为3.10.0-693.el7.x86_64只支持layering


**4、使用ceph认证秘钥**
在集群中使用secret更方便易于扩展且安全
```
[root@ceph01 ~]# cat /etc/ceph/ceph.client.admin.keyring 
[client.admin]
	key = AQBHVp9bPirBCRAAUt6Mjw5PUjiy/RDHyHZrUw==

[root@ceph01 ~]# grep key /etc/ceph/ceph.client.admin.keyring |awk '{printf "%s", $NF}'|base64
QVFCSFZwOWJQaXJCQ1JBQVV0Nk1qdzVQVWppeS9SREh5SFpyVXc9PQ==
```


**5、创建ceph-secret**
```
[root@elasticsearch01 rbd]# cat secret/ceph-secret.yaml 
apiVersion: v1
kind: Secret
metadata:
  name: ceph-secret
type: "kubernetes.io/rbd"
data:
  key: QVFCSFZwOWJQaXJCQ1JBQVV0Nk1qdzVQVWppeS9SREh5SFpyVXc9PQ==

[root@elasticsearch01 rbd]# kubectl create -f secret/ceph-secret.yaml 
secret/ceph-secret created
```

**6、创建pod测试rbd**
按照官网的案例直接创建即可
```
[root@elasticsearch01 rbd]# kubectl create -frbd-with-secret.yaml 
```
但是生产环境中不直接使用volumes，他会随着pods的创建儿创建，删除而删除，数据得不到保存，如果需要数据不丢失，需要借助pv和pvc实现

**7、创建ceph-pv**
注意rbd是读写一次，只读多次，目前还不支持读写多次，我们日常使用rbd映射磁盘时也是一个image只挂载一个客户端上；cephfs可以支持读写多次
```
[root@elasticsearch01 rbd]# cat rbd-pv.yaml 
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ceph-rbd-pv
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  rbd:
    monitors:
      - '10.0.4.10:6789'
      - '10.0.4.13:6789'
      - '10.0.4.15:6789'
    pool: rbd-k8s
    image: cephimage2
    user: admin
    secretRef:
      name: ceph-secret
    fsType: ext4
    readOnly: false
  persistentVolumeReclaimPolicy: Recycle

[root@elasticsearch01 rbd]# kubectl create -f rbd-pv.yaml 
persistentvolume/ceph-rbd-pv created

[root@elasticsearch01 rbd]# kubectl get pv
NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
ceph-rbd-pv   20Gi       RWO            Recycle          Available  
```

**8、创建ceph-pvc**
```
[root@elasticsearch01 rbd]# cat rbd-pv-claim.yaml 
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ceph-rbd-pv-claim
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi

[root@elasticsearch01 rbd]# kubectl create -f rbd-pv-claim.yaml 
persistentvolumeclaim/ceph-rbd-pv-claim created

[root@elasticsearch01 rbd]# kubectl get pvc
NAME                STATUS   VOLUME        CAPACITY   ACCESS MODES   STORAGECLASS   AGE
ceph-rbd-pv-claim   Bound    ceph-rbd-pv   20Gi       RWO                           6s

[root@elasticsearch01 rbd]# kubectl get pv
NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                       STORAGECLASS   REASON   AGE
ceph-rbd-pv   20Gi       RWO            Recycle          Bound    default/ceph-rbd-pv-claim                           5m28s
```

**9、创建pod通过pv、pvc方式测试rbd**
由于需要格式化挂载rbd，rbd空间比较大10G，需要时间比较久，大概需要几分钟
```
[root@elasticsearch01 rbd]# cat rbd-pv-pod.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: ceph-rbd-pv-pod1
spec:
  containers:
  - name: ceph-rbd-pv-busybox
    image: busybox
    command: ["sleep", "60000"]
    volumeMounts:
    - name: ceph-rbd-vol1
      mountPath: /mnt/ceph-rbd-pvc/busybox
      readOnly: false
  volumes:
  - name: ceph-rbd-vol1
    persistentVolumeClaim:
      claimName: ceph-rbd-pv-claim

[root@elasticsearch01 rbd]# kubectl create -f rbd-pv-pod.yaml 
pod/ceph-rbd-pv-pod1 created

[root@elasticsearch01 rbd]# kubectl get pods
NAME               READY   STATUS              RESTARTS   AGE
busybox            1/1     Running             432        18d
ceph-rbd-pv-pod1   0/1     ContainerCreating   0          19s
```

报错如下
MountVolume.WaitForAttach failed for volume "ceph-rbd-pv" : rbd: map failed exit status 6, rbd output: rbd: sysfs write failed RBD image feature set mismatch. Try disabling features unsupported by the kernel with "rbd feature disable". In some cases useful info is found in syslog - try "dmesg | tail". rbd: map failed: (6) No such device or address
解决方法
禁用一些特性，这些特性在centos7.4内核上不支持，所以生产环境中k8s及相关ceph最好使用内核版本高的系统做为底层操作系统
rbd feature disable rbd-k8s/cephimage2 exclusive-lock object-map fast-diff deep-flatten
```
[root@ceph01 ~]# rbd feature disable rbd-k8s/cephimage2 exclusive-lock object-map fast-diff deep-flatten
```


#### **三、验证效果**
**1、k8s集群端验证**
```
[root@elasticsearch01 rbd]# kubectl get pods -o wide
NAME               READY   STATUS    RESTARTS   AGE     IP            NODE        NOMINATED NODE   READINESS GATES
busybox            1/1     Running   432        18d     10.254.35.3   10.2.8.65   <none>           <none>
ceph-rbd-pv-pod1   1/1     Running   0          3m39s   10.254.35.8   10.2.8.65   <none>           <none>

[root@elasticsearch02 ceph]# df -h |grep rbd
/dev/rbd0                  493G  162G  306G  35% /data
/dev/rbd1                   20G   45M   20G   1% /var/lib/kubelet/plugins/kubernetes.io/rbd/mounts/rbd-k8s-image-cephimage2

[root@elasticsearch01 rbd]# kubectl exec -ti ceph-rbd-pv-pod1 sh
/ # df -h
Filesystem                Size      Used Available Use% Mounted on
overlay                  49.1G      7.4G     39.1G  16% /
tmpfs                    64.0M         0     64.0M   0% /dev
tmpfs                     7.8G         0      7.8G   0% /sys/fs/cgroup
/dev/vda1                49.1G      7.4G     39.1G  16% /dev/termination-log
/dev/vda1                49.1G      7.4G     39.1G  16% /etc/resolv.conf
/dev/vda1                49.1G      7.4G     39.1G  16% /etc/hostname
/dev/vda1                49.1G      7.4G     39.1G  16% /etc/hosts
shm                      64.0M         0     64.0M   0% /dev/shm
/dev/rbd1                19.6G     44.0M     19.5G   0% /mnt/ceph-rbd-pvc/busybox
tmpfs                     7.8G     12.0K      7.8G   0% /var/run/secrets/kubernetes.io/serviceaccount
tmpfs                     7.8G         0      7.8G   0% /proc/acpi
tmpfs                    64.0M         0     64.0M   0% /proc/kcore
tmpfs                    64.0M         0     64.0M   0% /proc/keys
tmpfs                    64.0M         0     64.0M   0% /proc/timer_list
tmpfs                    64.0M         0     64.0M   0% /proc/timer_stats
tmpfs                    64.0M         0     64.0M   0% /proc/sched_debug
tmpfs                     7.8G         0      7.8G   0% /proc/scsi
tmpfs                     7.8G         0      7.8G   0% /sys/firmware
/ # cd /mnt/ceph-rbd-pvc/busybox/
/mnt/ceph-rbd-pvc/busybox # ls
lost+found
/mnt/ceph-rbd-pvc/busybox # touch ceph-rbd-pods
/mnt/ceph-rbd-pvc/busybox # ls
ceph-rbd-pods  lost+found
/mnt/ceph-rbd-pvc/busybox # echo busbox>ceph-rbd-pods 
/mnt/ceph-rbd-pvc/busybox # cat ceph-rbd-pods 
busbox
```

**2、ceph集群端验证**
```
[root@ceph01 ~]# ceph df
GLOBAL:
    SIZE        AVAIL       RAW USED     %RAW USED 
    65.9TiB     58.3TiB      7.53TiB         11.43 
POOLS:
    NAME                           ID     USED        %USED     MAX AVAIL     OBJECTS 
    rbd-es                         1      1.38TiB      7.08       18.1TiB      362911 
    .rgw.root                      2      1.14KiB         0       18.1TiB           4 
    default.rgw.control            3           0B         0       18.1TiB           8 
    default.rgw.meta               4      46.9KiB         0        104GiB         157 
    default.rgw.log                5           0B         0       18.1TiB         345 
    default.rgw.buckets.index      6           0B         0        104GiB        2012 
    default.rgw.buckets.data       7      1.01TiB      5.30       18.1TiB     2090721 
    default.rgw.buckets.non-ec     8           0B         0       18.1TiB           0 
    rbd-k8s                        9       137MiB         0       18.1TiB          67 
```
