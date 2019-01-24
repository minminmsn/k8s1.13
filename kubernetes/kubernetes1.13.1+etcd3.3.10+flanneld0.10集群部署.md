### Kubernetes1.13新特性
+ ##### 使用kubeadm（GA）简化Kubernetes集群管理
> 大多数与Kubernetes的工程师，都应该会使用kubeadm。它是管理集群生命周期的重要工具，从创建到配置再到升级; 现在kubeadm正式成为GA。kubeadm处理现有硬件上的生产集群的引导，并以最佳实践方式配置核心Kubernetes组件，以便为新节点提供安全而简单的连接流程并支持轻松升级。这个GA版本值得注意的是现在已经毕业的高级功能，特别是可插拔性和可配置性。kubeadm的范围是管理员和自动化，更高级别系统的工具箱，这个版本是朝这个方向迈出的重要一步。
+ ##### 容器存储接口（CSI）进入GA
> 容器存储接口（CSI）现在已经GA，在v1.9中作为alpha引入，在v1.10中作为beta引入。通过CSI，Kubernetes卷层变得真正可扩展。这为第三方存储提供商提供了编写与Kubernetes互操作而无需触及核心代码的插件的机会。该规范本身也达到了1.0状态。
+ ##### CoreDNS现在是Kubernetes的默认DNS服务器
> 在1.11中，我们宣布CoreDNS已达到基于DNS的服务发现的一般可用性。在1.13中，CoreDNS现在将kube-dns替换为Kubernetes的默认DNS服务器。CoreDNS是一个通用的，权威的DNS服务器，提供与Kubernetes向后兼容但可扩展的集成。CoreDNS比以前的DNS服务器具有更少的移动部件，因为它是单个可执行文件和单个进程，并通过创建自定义DNS条目来支持灵活的用例。它也用Go编写，使其具有内存安全性。

### 一、官方文档
```
https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.13.md#downloads-for-v1131
https://kubernetes.io/docs/home/?path=users&persona=app-developer&level=foundational
https://github.com/etcd-io/etcd
https://shengbao.org/348.html
https://github.com/coreos/flannel
http://www.cnblogs.com/blogscc/p/10105134.html
https://blog.csdn.net/xiegh2014/article/details/84830880
https://blog.csdn.net/tiger435/article/details/85002337
https://www.cnblogs.com/wjoyxt/p/9968491.html
https://blog.csdn.net/zhaihaifei/article/details/79098564
http://blog.51cto.com/jerrymin/1898243
http://www.cnblogs.com/xuxinkun/p/5696031.html
```

### 二、下载链接
```
Client Binaries
https://dl.k8s.io/v1.13.1/kubernetes-client-linux-amd64.tar.gz
Server Binaries
https://dl.k8s.io/v1.13.1/kubernetes-server-linux-amd64.tar.gz
Node Binaries
https://dl.k8s.io/v1.13.1/kubernetes-node-linux-amd64.tar.gz
etcd
https://github.com/etcd-io/etcd/releases/download/v3.3.10/etcd-v3.3.10-linux-amd64.tar.gz
flannel
https://github.com/coreos/flannel/releases/download/v0.10.0/flannel-v0.10.0-linux-amd64.tar.gz
```

### 三、角色划分
```
k8s-master1	10.2.8.44	k8s-master	etcd、kube-apiserver、kube-controller-manager、kube-scheduler
k8s-node1	10.2.8.65	k8s-node	etcd、kubelet、docker、kube_proxy
k8s-node2	10.2.8.34	k8s-node	etcd、kubelet、docker、kube_proxy
```


### 四、Master部署
##### 4.1 下载软件
```
wget https://dl.k8s.io/v1.13.1/kubernetes-server-linux-amd64.tar.gz
wget https://dl.k8s.io/v1.13.1/kubernetes-client-linux-amd64.tar.gz
wget https://github.com/etcd-io/etcd/releases/download/v3.3.10/etcd-v3.3.10-linux-amd64.tar.gz
wget https://github.com/coreos/flannel/releases/download/v0.10.0/flannel-v0.10.0-linux-amd64.tar.gz
```
##### 4.2 cfssl安装
```
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64
chmod +x cfssl_linux-amd64 cfssljson_linux-amd64 cfssl-certinfo_linux-amd64
mv cfssl_linux-amd64 /usr/local/bin/cfssl
mv cfssljson_linux-amd64 /usr/local/bin/cfssljson
mv cfssl-certinfo_linux-amd64 /usr/bin/cfssl-certinfo
```
##### 4.3 创建etcd证书
```
mkdir /k8s/etcd/{bin,cfg,ssl} -p
mkdir /k8s/kubernetes/{bin,cfg,ssl} -p
cd /k8s/etcd/ssl/
```
1）etcd ca配置
```
cat << EOF | tee ca-config.json
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "etcd": {
         "expiry": "87600h",
         "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ]
      }
    }
  }
}
EOF
```

2）etcd ca证书
```
cat << EOF | tee ca-csr.json
{
    "CN": "etcd CA",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing"
        }
    ]
}
EOF
```
3）etcd server证书
```
cat << EOF | tee server-csr.json
{
    "CN": "etcd",
    "hosts": [
    "10.2.8.44",
    "10.2.8.65",
    "10.2.8.34"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Beijing",
            "ST": "Beijing"
        }
    ]
}
EOF
```
4）生成etcd ca证书和私钥
初始化ca
```
cfssl gencert -initca ca-csr.json | cfssljson -bare ca 
[root@elasticsearch01 ssl]# ls
ca-config.json  ca-csr.json  server-csr.json
[root@elasticsearch01 ssl]# cfssl gencert -initca ca-csr.json | cfssljson -bare ca 
2018/12/26 16:13:54 [INFO] generating a new CA key and certificate from CSR
2018/12/26 16:13:54 [INFO] generate received request
2018/12/26 16:13:54 [INFO] received CSR
2018/12/26 16:13:54 [INFO] generating key: rsa-2048
2018/12/26 16:13:54 [INFO] encoded CSR
2018/12/26 16:13:54 [INFO] signed certificate with serial number 144752911121073185391033754516204538929473929443
[root@elasticsearch01 ssl]# ls
ca-config.json  ca.csr  ca-csr.json  ca-key.pem  ca.pem  server-csr.json
```
生成server证书
```
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=etcd server-csr.json | cfssljson -bare server
[root@elasticsearch01 ssl]# cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=etcd server-csr.json | cfssljson -bare server
2018/12/26 16:18:53 [INFO] generate received request
2018/12/26 16:18:53 [INFO] received CSR
2018/12/26 16:18:53 [INFO] generating key: rsa-2048
2018/12/26 16:18:54 [INFO] encoded CSR
2018/12/26 16:18:54 [INFO] signed certificate with serial number 388122587040599986639159163167557684970159030057
2018/12/26 16:18:54 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for websites. 
For more information see the Baseline Requirements for the Issuance and Management of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
specifically, section 10.2.3 ("Information Requirements").
[root@elasticsearch01 ssl]# ls
ca-config.json  ca.csr  ca-csr.json  ca-key.pem  ca.pem  server.csr  server-csr.json  server-key.pem  server.pem
```

##### 4.4 etcd安装
1）解压缩
```
tar -xvf etcd-v3.3.10-linux-amd64.tar.gz
cd etcd-v3.3.10-linux-amd64/
cp etcd etcdctl /k8s/etcd/bin/
```
2）配置etcd主文件
```
vim /k8s/etcd/cfg/etcd.conf   
#[Member]
ETCD_NAME="etcd01"
ETCD_DATA_DIR="/data1/etcd"
ETCD_LISTEN_PEER_URLS="https://10.2.8.44:2380"
ETCD_LISTEN_CLIENT_URLS="https://10.2.8.44:2379"
 
#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://10.2.8.44:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://10.2.8.44:2379"
ETCD_INITIAL_CLUSTER="etcd01=https://10.2.8.44:2380,etcd02=https://10.2.8.65:2380,etcd03=https://10.2.8.34:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"

#[Security]
ETCD_CERT_FILE="/k8s/etcd/ssl/server.pem"
ETCD_KEY_FILE="/k8s/etcd/ssl/server-key.pem"
ETCD_TRUSTED_CA_FILE="/k8s/etcd/ssl/ca.pem"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_PEER_CERT_FILE="/k8s/etcd/ssl/server.pem"
ETCD_PEER_KEY_FILE="/k8s/etcd/ssl/server-key.pem"
ETCD_PEER_TRUSTED_CA_FILE="/k8s/etcd/ssl/ca.pem"
ETCD_PEER_CLIENT_CERT_AUTH="true"
```

3）配置etcd启动文件
```
mkdir /data1/etcd
vim /usr/lib/systemd/system/etcd.service
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/data1/etcd/
EnvironmentFile=-/k8s/etcd/cfg/etcd.conf
# set GOMAXPROCS to number of processors
ExecStart=/bin/bash -c "GOMAXPROCS=$(nproc) /k8s/etcd/bin/etcd --name=\"${ETCD_NAME}\" --data-dir=\"${ETCD_DATA_DIR}\" --listen-client-urls=\"${ETCD_LISTEN_CLIENT_URLS}\" --listen-peer-urls=\"${ETCD_LISTEN_PEER_URLS}\" --advertise-client-urls=\"${ETCD_ADVERTISE_CLIENT_URLS}\" --initial-cluster-token=\"${ETCD_INITIAL_CLUSTER_TOKEN}\" --initial-cluster=\"${ETCD_INITIAL_CLUSTER}\" --initial-cluster-state=\"${ETCD_INITIAL_CLUSTER_STATE}\" --cert-file=\"${ETCD_CERT_FILE}\" --key-file=\"${ETCD_KEY_FILE}\" --trusted-ca-file=\"${ETCD_TRUSTED_CA_FILE}\" --client-cert-auth=\"${ETCD_CLIENT_CERT_AUTH}\" --peer-cert-file=\"${ETCD_PEER_CERT_FILE}\" --peer-key-file=\"${ETCD_PEER_KEY_FILE}\" --peer-trusted-ca-file=\"${ETCD_PEER_TRUSTED_CA_FILE}\" --peer-client-cert-auth=\"${ETCD_PEER_CLIENT_CERT_AUTH}\""
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

4）启动
注意启动前etcd02、etcd03同样配置下
```
systemctl daemon-reload
systemctl enable etcd
systemctl start etcd
```

5）服务检查
```
/k8s/etcd/bin/etcdctl --ca-file=/k8s/etcd/ssl/ca.pem --cert-file=/k8s/etcd/ssl/server.pem --key-file=/k8s/etcd/ssl/server-key.pem --endpoints="https://10.2.8.44:2379,https://10.2.8.65:2379,https://10.2.8.34:2379" cluster-health
member c21df2258ce015e6 is healthy: got healthy result from https://10.2.8.34:2379
member d427109ed3caf9c3 is healthy: got healthy result from https://10.2.8.44:2379
member ec8c40660d3c1192 is healthy: got healthy result from https://10.2.8.65:2379
cluster is healthy
```

##### 4.5 生成kubernets证书与私钥
1）制作kubernetes ca证书
```
cd /k8s/kubernetes/ssl
cat << EOF | tee ca-config.json
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
         "expiry": "87600h",
         "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ]
      }
    }
  }
}
EOF
```
```
cat << EOF | tee ca-csr.json
{
    "CN": "kubernetes",
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
EOF
 ```
```
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
[root@elasticsearch01 ssl]# cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
2018/12/27 09:47:08 [INFO] generating a new CA key and certificate from CSR
2018/12/27 09:47:08 [INFO] generate received request
2018/12/27 09:47:08 [INFO] received CSR
2018/12/27 09:47:08 [INFO] generating key: rsa-2048
2018/12/27 09:47:08 [INFO] encoded CSR
2018/12/27 09:47:08 [INFO] signed certificate with serial number 156611735285008649323551446985295933852737436614
[root@elasticsearch01 ssl]# ls
ca-config.json  ca.csr  ca-csr.json  ca-key.pem  ca.pem
```

2）制作apiserver证书
```
cat << EOF | tee server-csr.json
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
EOF
 ```
```
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes server-csr.json | cfssljson -bare server
[root@elasticsearch01 ssl]# cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes server-csr.json | cfssljson -bare server
2018/12/27 09:51:56 [INFO] generate received request
2018/12/27 09:51:56 [INFO] received CSR
2018/12/27 09:51:56 [INFO] generating key: rsa-2048
2018/12/27 09:51:56 [INFO] encoded CSR
2018/12/27 09:51:56 [INFO] signed certificate with serial number 399376216731194654868387199081648887334508501005
2018/12/27 09:51:56 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
websites. For more information see the Baseline Requirements for the Issuance and Management
of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
specifically, section 10.2.3 ("Information Requirements").
[root@elasticsearch01 ssl]# ls
ca-config.json  ca.csr  ca-csr.json  ca-key.pem  ca.pem  server.csr  server-csr.json  server-key.pem  server.pem
```


3）制作kube-proxy证书
```
cat << EOF | tee kube-proxy-csr.json
{
  "CN": "system:kube-proxy",
  "hosts": [],
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
EOF
```
``` 
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy
[root@elasticsearch01 ssl]# cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy
2018/12/27 09:52:40 [INFO] generate received request
2018/12/27 09:52:40 [INFO] received CSR
2018/12/27 09:52:40 [INFO] generating key: rsa-2048
2018/12/27 09:52:40 [INFO] encoded CSR
2018/12/27 09:52:40 [INFO] signed certificate with serial number 633932731787505365511506755558794469389165123417
2018/12/27 09:52:40 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
websites. For more information see the Baseline Requirements for the Issuance and Management
of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
specifically, section 10.2.3 ("Information Requirements").
[root@elasticsearch01 ssl]# ls
ca-config.json  ca-csr.json  ca.pem          kube-proxy-csr.json  kube-proxy.pem  server-csr.json  server.pem
ca.csr          ca-key.pem   kube-proxy.csr  kube-proxy-key.pem   server.csr      server-key.pem
```

##### 4.6部署kubernetes server
> kubernetes master 节点运行如下组件：
kube-apiserver
kube-scheduler
kube-controller-manager
kube-scheduler 和 kube-controller-manager 可以以集群模式运行，通过 leader 选举产生一个工作进程，其它进程处于阻塞模式，master三节点高可用模式下可用

1）解压缩文件
```
tar -zxvf kubernetes-server-linux-amd64.tar.gz 
cd kubernetes/server/bin/
cp kube-scheduler kube-apiserver kube-controller-manager kubectl /k8s/kubernetes/bin/
```
2）部署kube-apiserver组件
创建TLS Bootstrapping Token
```
[root@elasticsearch01 bin]# head -c 16 /dev/urandom | od -An -t x | tr -d ' '
f2c50331f07be89278acdaf341ff1ecc
 
vim /k8s/kubernetes/cfg/token.csv
f2c50331f07be89278acdaf341ff1ecc,kubelet-bootstrap,10001,"system:kubelet-bootstrap"
```
创建Apiserver配置文件
```
vim /k8s/kubernetes/cfg/kube-apiserver 
KUBE_APISERVER_OPTS="--logtostderr=true \
--v=4 \
--etcd-servers=https://10.2.8.44:2379,https://10.2.8.65:2379,https://10.2.8.34:2379 \
--bind-address=10.2.8.44 \
--secure-port=6443 \
--advertise-address=10.2.8.44 \
--allow-privileged=true \
--service-cluster-ip-range=10.254.0.0/16 \
--enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota,NodeRestriction \
--authorization-mode=RBAC,Node \
--enable-bootstrap-token-auth \
--token-auth-file=/k8s/kubernetes/cfg/token.csv \
--service-node-port-range=30000-50000 \
--tls-cert-file=/k8s/kubernetes/ssl/server.pem  \
--tls-private-key-file=/k8s/kubernetes/ssl/server-key.pem \
--client-ca-file=/k8s/kubernetes/ssl/ca.pem \
--service-account-key-file=/k8s/kubernetes/ssl/ca-key.pem \
--etcd-cafile=/k8s/etcd/ssl/ca.pem \
--etcd-certfile=/k8s/etcd/ssl/server.pem \
--etcd-keyfile=/k8s/etcd/ssl/server-key.pem"
```

创建apiserver systemd文件
```
vim /usr/lib/systemd/system/kube-apiserver.service 

[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes
 
[Service]
EnvironmentFile=-/k8s/kubernetes/cfg/kube-apiserver
ExecStart=/k8s/kubernetes/bin/kube-apiserver $KUBE_APISERVER_OPTS
Restart=on-failure
 
[Install]
WantedBy=multi-user.target
```

启动服务
```
systemctl daemon-reload
systemctl enable kube-apiserver
systemctl start kube-apiserver
[root@elasticsearch01 bin]# systemctl status kube-apiserver
● kube-apiserver.service - Kubernetes API Server
   Loaded: loaded (/usr/lib/systemd/system/kube-apiserver.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2018-12-27 14:41:22 CST; 20s ago
     Docs: https://github.com/kubernetes/kubernetes
 Main PID: 22060 (kube-apiserver)
   CGroup: /system.slice/kube-apiserver.service
           └─22060 /k8s/kubernetes/bin/kube-apiserver --logtostderr=true --v=4 --etcd-servers=https://10.2.8.44:2379,https://10.2....

[root@elasticsearch01 bin]# ps -ef |grep kube-apiserver
root     22060     1  5 14:41 ?        00:00:14 /k8s/kubernetes/bin/kube-apiserver --logtostderr=true --v=4 --etcd-servers=https://10.2.8.44:2379,https://10.2.8.65:2379,https://10.2.8.34:2379 --bind-address=10.2.8.44 --secure-port=6443 --advertise-address=10.2.8.44 --allow-privileged=true --service-cluster-ip-range=10.254.0.0/16 --enable-admission-plugins=NamespaceLifecycle,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota,NodeRestriction --authorization-mode=RBAC,Node --enable-bootstrap-token-auth --token-auth-file=/k8s/kubernetes/cfg/token.csv --service-node-port-range=30000-50000 --tls-cert-file=/k8s/kubernetes/ssl/server.pem --tls-private-key-file=/k8s/kubernetes/ssl/server-key.pem --client-ca-file=/k8s/kubernetes/ssl/ca.pem --service-account-key-file=/k8s/kubernetes/ssl/ca-key.pem --etcd-cafile=/k8s/etcd/ssl/ca.pem --etcd-certfile=/k8s/etcd/ssl/server.pem --etcd-keyfile=/k8s/etcd/ssl/server-key.pem
[root@elasticsearch01 bin]# netstat -tulpn |grep kube-apiserve
tcp        0      0 10.2.8.44:6443          0.0.0.0:*               LISTEN      22060/kube-apiserve 
tcp        0      0 127.0.0.1:8080          0.0.0.0:*               LISTEN      22060/kube-apiserve 
```
3）部署kube-scheduler组件
创建kube-scheduler配置文件
```
vim  /k8s/kubernetes/cfg/kube-scheduler 
KUBE_SCHEDULER_OPTS="--logtostderr=true --v=4 --master=127.0.0.1:8080 --leader-elect"
```
参数备注：
--address：在 127.0.0.1:10251 端口接收 http /metrics 请求；kube-scheduler 目前还不支持接收 https 请求；
--kubeconfig：指定 kubeconfig 文件路径，kube-scheduler 使用它连接和验证 kube-apiserver；
--leader-elect=true：集群运行模式，启用选举功能；被选为 leader 的节点负责处理工作，其它节点为阻塞状态；

创建kube-scheduler systemd文件
```
vim /usr/lib/systemd/system/kube-scheduler.service 
 
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes
 
[Service]
EnvironmentFile=-/k8s/kubernetes/cfg/kube-scheduler
ExecStart=/k8s/kubernetes/bin/kube-scheduler $KUBE_SCHEDULER_OPTS
Restart=on-failure
 
[Install]
WantedBy=multi-user.target
```
启动服务
```
systemctl daemon-reload
systemctl enable kube-scheduler.service 
systemctl start kube-scheduler.service
[root@elasticsearch01 bin]# systemctl status kube-scheduler.service
● kube-scheduler.service - Kubernetes Scheduler
   Loaded: loaded (/usr/lib/systemd/system/kube-scheduler.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2018-12-27 15:16:51 CST; 17s ago
     Docs: https://github.com/kubernetes/kubernetes
 Main PID: 29026 (kube-scheduler)
   CGroup: /system.slice/kube-scheduler.service
           └─29026 /k8s/kubernetes/bin/kube-scheduler --logtostderr=true --v=4 --master=127.0.0.1:8080 --leader-elect
```


4）部署kube-controller-manager组件
创建kube-controller-manager配置文件
```
vim /k8s/kubernetes/cfg/kube-controller-manager
KUBE_CONTROLLER_MANAGER_OPTS="--logtostderr=true \
--v=4 \
--master=127.0.0.1:8080 \
--leader-elect=true \
--address=127.0.0.1 \
--service-cluster-ip-range=10.254.0.0/16 \
--cluster-name=kubernetes \
--cluster-signing-cert-file=/k8s/kubernetes/ssl/ca.pem \
--cluster-signing-key-file=/k8s/kubernetes/ssl/ca-key.pem  \
--root-ca-file=/k8s/kubernetes/ssl/ca.pem \
--service-account-private-key-file=/k8s/kubernetes/ssl/ca-key.pem"
```
创建kube-controller-manager systemd文件
```
vim /usr/lib/systemd/system/kube-controller-manager.service 
 
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes
 
[Service]
EnvironmentFile=-/k8s/kubernetes/cfg/kube-controller-manager
ExecStart=/k8s/kubernetes/bin/kube-controller-manager $KUBE_CONTROLLER_MANAGER_OPTS
Restart=on-failure
 
[Install]
WantedBy=multi-user.target
```

启动服务
```
systemctl daemon-reload
systemctl enable kube-controller-manager
systemctl start kube-controller-manager
[root@elasticsearch01 bin]# systemctl status kube-controller-manager
● kube-controller-manager.service - Kubernetes Controller Manager
   Loaded: loaded (/usr/lib/systemd/system/kube-controller-manager.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2018-12-27 15:19:19 CST; 11s ago
     Docs: https://github.com/kubernetes/kubernetes
 Main PID: 29510 (kube-controller)
   CGroup: /system.slice/kube-controller-manager.service
           └─29510 /k8s/kubernetes/bin/kube-controller-manager --logtostderr=true --v=4 --master=127.0.0.1:8080 --leader-elect=tru..
```

##### 4.7 验证kubeserver服务
设置环境变量
```
vim /etc/profile
PATH=/k8s/kubernetes/bin:$PATH
source /etc/profile
```

查看master服务状态
```
kubectl get cs,nodes
[root@elasticsearch01 bin]# kubectl get cs,nodes
NAME                                 STATUS    MESSAGE             ERROR
componentstatus/controller-manager   Healthy   ok                  
componentstatus/scheduler            Healthy   ok                  
componentstatus/etcd-0               Healthy   {"health":"true"}   
componentstatus/etcd-1               Healthy   {"health":"true"}   
componentstatus/etcd-2               Healthy   {"health":"true"}   
```

### 五、Node部署
> kubernetes work 节点运行如下组件：
docker 
kubelet
kube-proxy
flannel
系统环境
CentOS Linux release 7.4.1708 (Core) 
Docker版本
Server Version: 18.09.0
Cgroup Driver: cgroupfs


##### 5.1 Docker环境安装
```
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum list docker-ce --showduplicates | sort -r
yum install docker-ce -y
systemctl start docker && systemctl enable docker
```

##### 5.2 部署kubelet组件
>kublet 运行在每个 worker 节点上，接收 kube-apiserver 发送的请求，管理 Pod 容器，执行交互式命令，如exec、run、logs 等;
kublet 启动时自动向 kube-apiserver 注册节点信息，内置的 cadvisor 统计和监控节点的资源使用情况;
为确保安全，只开启接收 https 请求的安全端口，对请求进行认证和授权，拒绝未授权的访问(如apiserver、heapster)

1）安装二进制文件
```
wget https://dl.k8s.io/v1.13.1/kubernetes-node-linux-amd64.tar.gz
tar zxvf kubernetes-node-linux-amd64.tar.gz
cd kubernetes/node/bin/
cp kube-proxy kubelet kubectl /k8s/kubernetes/bin/
```
2）复制相关证书到node节点
```
[root@elasticsearch01 ssl]# scp *.pem 10.2.8.65:$PWD
root@10.2.8.65's password: 
ca-key.pem                                                                                         100% 1679   914.6KB/s   00:00    
ca.pem                                                                                             100% 1359     1.0MB/s   00:00    
kube-proxy-key.pem                                                                                 100% 1675     1.2MB/s   00:00    
kube-proxy.pem                                                                                     100% 1403     1.1MB/s   00:00    
server-key.pem                                                                                     100% 1679   809.1KB/s   00:00    
server.pem     
```
3）创建kubelet bootstrap kubeconfig文件
通过脚本实现
```
vim /k8s/kubernetes/cfg/environment.sh
#!/bin/bash
#创建kubelet bootstrapping kubeconfig 
BOOTSTRAP_TOKEN=f2c50331f07be89278acdaf341ff1ecc
KUBE_APISERVER="https://10.2.8.44:6443"
#设置集群参数
kubectl config set-cluster kubernetes \
  --certificate-authority=/k8s/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=bootstrap.kubeconfig
 
#设置客户端认证参数
kubectl config set-credentials kubelet-bootstrap \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=bootstrap.kubeconfig
 
# 设置上下文参数
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet-bootstrap \
  --kubeconfig=bootstrap.kubeconfig
 
# 设置默认上下文
kubectl config use-context default --kubeconfig=bootstrap.kubeconfig
 
#----------------------
 
# 创建kube-proxy kubeconfig文件
 
kubectl config set-cluster kubernetes \
  --certificate-authority=/k8s/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-proxy.kubeconfig
 
kubectl config set-credentials kube-proxy \
  --client-certificate=/k8s/kubernetes/ssl/kube-proxy.pem \
  --client-key=/k8s/kubernetes/ssl/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig
 
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig
 
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
```
执行脚本
```
[root@elasticsearch02 cfg]# sh environment.sh 
Cluster "kubernetes" set.
User "kubelet-bootstrap" set.
Context "default" created.
Switched to context "default".
Cluster "kubernetes" set.
User "kube-proxy" set.
Context "default" created.
Switched to context "default".
[root@elasticsearch02 cfg]# ls
bootstrap.kubeconfig  environment.sh  kube-proxy.kubeconfig
```
4）创建kubelet参数配置模板文件
```
vim /k8s/kubernetes/cfg/kubelet.config
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: 10.2.8.65
port: 10250
readOnlyPort: 10255
cgroupDriver: cgroupfs
clusterDNS: ["10.254.0.10"]
clusterDomain: cluster.local.
failSwapOn: false
authentication:
  anonymous:
    enabled: true
```
5）创建kubelet配置文件
```
vim /k8s/kubernetes/cfg/kubelet
 
KUBELET_OPTS="--logtostderr=true \
--v=4 \
--hostname-override=10.2.8.65 \
--kubeconfig=/k8s/kubernetes/cfg/kubelet.kubeconfig \
--bootstrap-kubeconfig=/k8s/kubernetes/cfg/bootstrap.kubeconfig \
--config=/k8s/kubernetes/cfg/kubelet.config \
--cert-dir=/k8s/kubernetes/ssl \
--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google-containers/pause-amd64:3.0"
```

6）创建kubelet systemd文件
```
vim /usr/lib/systemd/system/kubelet.service 
 
[Unit]
Description=Kubernetes Kubelet
After=docker.service
Requires=docker.service
 
[Service]
EnvironmentFile=/k8s/kubernetes/cfg/kubelet
ExecStart=/k8s/kubernetes/bin/kubelet $KUBELET_OPTS
Restart=on-failure
KillMode=process
 
[Install]
WantedBy=multi-user.target
```

7）将kubelet-bootstrap用户绑定到系统集群角色
```
kubectl create clusterrolebinding kubelet-bootstrap \
  --clusterrole=system:node-bootstrapper \
  --user=kubelet-bootstrap
```
注意这个默认连接localhost:8080端口，可以在master上操作  
```
[root@elasticsearch01 ssl]# kubectl create clusterrolebinding kubelet-bootstrap \
>   --clusterrole=system:node-bootstrapper \
>   --user=kubelet-bootstrap
clusterrolebinding.rbac.authorization.k8s.io/kubelet-bootstrap created
```

8）启动服务
systemctl daemon-reload
systemctl enable kubelet
systemctl start kubelet
```
[root@elasticsearch02 cfg]# systemctl status kubelet
● kubelet.service - Kubernetes Kubelet
   Loaded: loaded (/usr/lib/systemd/system/kubelet.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2018-12-27 17:34:30 CST; 18s ago
 Main PID: 24676 (kubelet)
   Memory: 88.6M
   CGroup: /system.slice/kubelet.service
           └─24676 /k8s/kubernetes/bin/kubelet --logtostderr=true --v=4 --hostname-override=10.2.8.44 --kubeconfig=/k8s/kubernetes...
```		  

9）Master接受kubelet CSR请求
可以手动或自动 approve CSR 请求。推荐使用自动的方式，因为从 v1.8 版本开始，可以自动轮转approve csr 后生成的证书，如下是手动 approve CSR请求操作方法
查看CSR列表
```
[root@elasticsearch01 ssl]# kubectl get csr
NAME                                                   AGE    REQUESTOR           CONDITION
node-csr-ij3py9j-yi-eoa8sOHMDs7VeTQtMv0N3Efj3ByZLMdc   102s   kubelet-bootstrap   Pending
```
接受node
```
[root@elasticsearch01 ssl]# kubectl certificate approve node-csr-ij3py9j-yi-eoa8sOHMDs7VeTQtMv0N3Efj3ByZLMdc
certificatesigningrequest.certificates.k8s.io/node-csr-ij3py9j-yi-eoa8sOHMDs7VeTQtMv0N3Efj3ByZLMdc approved
```
再查看CSR
```
[root@elasticsearch01 ssl]# kubectl get csr
NAME                                                   AGE     REQUESTOR           CONDITION
node-csr-ij3py9j-yi-eoa8sOHMDs7VeTQtMv0N3Efj3ByZLMdc   5m13s   kubelet-bootstrap   Approved,Issued
```


##### 5.3部署kube-proxy组件
kube-proxy 运行在所有 node节点上，它监听 apiserver 中 service 和 Endpoint 的变化情况，创建路由规则来进行服务负载均衡
1）创建 kube-proxy 配置文件
```
vim /k8s/kubernetes/cfg/kube-proxy
KUBE_PROXY_OPTS="--logtostderr=true \
--v=4 \
--hostname-override=10.2.8.65 \
--cluster-cidr=10.254.0.0/16 \
--kubeconfig=/k8s/kubernetes/cfg/kube-proxy.kubeconfig"
```
2）创建kube-proxy systemd文件
```
vim /usr/lib/systemd/system/kube-proxy.service 
 
[Unit]
Description=Kubernetes Proxy
After=network.target
 
[Service]
EnvironmentFile=-/k8s/kubernetes/cfg/kube-proxy
ExecStart=/k8s/kubernetes/bin/kube-proxy $KUBE_PROXY_OPTS
Restart=on-failure
 
[Install]
WantedBy=multi-user.target
```

3）启动服务
systemctl daemon-reload
systemctl enable kube-proxy
systemctl start kube-proxy
```
[root@elasticsearch02 cfg]# systemctl status  kube-proxy
● kube-proxy.service - Kubernetes Proxy
   Loaded: loaded (/usr/lib/systemd/system/kube-proxy.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2018-12-27 18:31:42 CST; 11s ago
 Main PID: 5376 (kube-proxy)
   Memory: 40.9M
   CGroup: /system.slice/kube-proxy.service
           ‣ 5376 /k8s/kubernetes/bin/kube-proxy --logtostderr=true --v=4 --hostname-override=10.2.8.44 --cluster-cidr=10.254.0.0/...
```

		 
4）查看集群状态	
```	 
[root@elasticsearch01 cfg]# kubectl get nodes
NAME        STATUS   ROLES    AGE     VERSION
10.2.8.65   Ready    <none>   9m15s   v1.13.1
```

5）同样操作部署node 10.2.8.34并认证csr，认证后会生成kubelet-client证书
>注意期间要是kubelet，kube-proxy配置错误，比如监听IP或者hostname错误导致node not found，需要删除kubelet-client证书，重启kubelet服务，重启认证csr即可
```
[root@elasticsearch03 kubernetes]# ls ssl
ca-key.pem  kubelet-client-2018-12-27-20-13-52.pem  kubelet.crt  kube-proxy-key.pem  server-key.pem
ca.pem      kubelet-client-current.pem              kubelet.key  kube-proxy.pem      server.pem

[root@elasticsearch01 ~]# kubectl get nodes
NAME        STATUS   ROLES    AGE   VERSION
10.2.8.34   Ready    <none>   13h   v1.13.1
10.2.8.65   Ready    <none>   14h   v1.13.1
```

### 六 Flanneld网络部署
>默认没有flanneld网络，Node节点间的pod不能通信，只能Node内通信，为了部署步骤简洁明了，故flanneld放在后面安装
flannel服务需要先于docker启动。flannel服务启动时主要做了以下几步的工作：
从etcd中获取network的配置信息
划分subnet，并在etcd中进行注册
将子网信息记录到/run/flannel/subnet.env中

##### 6.1 etcd注册网段
```
[root@elasticsearch02 cfg]# /k8s/etcd/bin/etcdctl --ca-file=/k8s/etcd/ssl/ca.pem --cert-file=/k8s/etcd/ssl/server.pem --key-file=/k8s/etcd/ssl/server-key.pem --endpoints="https://10.2.8.44:2379,https://10.2.8.65:2379,https://10.2.8.34:2379"  set /k8s/network/config  '{ "Network": "10.254.0.0/16", "Backend": {"Type": "vxlan"}}'
{ "Network": "10.254.0.0/16", "Backend": {"Type": "vxlan"}}
```
flanneld 当前版本 (v0.10.0) 不支持 etcd v3，故使用 etcd v2 API 写入配置 key 和网段数据；
写入的 Pod 网段 ${CLUSTER_CIDR} 必须是 /16 段地址，必须与 kube-controller-manager 的 --cluster-cidr 参数值一致；


#### 6.2 flannel安装
1）解压安装
```
tar -xvf flannel-v0.10.0-linux-amd64.tar.gz
mv flanneld mk-docker-opts.sh /k8s/kubernetes/bin/
```
2）配置flanneld
```
vim /k8s/kubernetes/cfg/flanneld
FLANNEL_OPTIONS="--etcd-endpoints=https://10.2.8.44:2379,https://10.2.8.65:2379,https://10.2.8.34:2379 -etcd-cafile=/k8s/etcd/ssl/ca.pem -etcd-certfile=/k8s/etcd/ssl/server.pem -etcd-keyfile=/k8s/etcd/ssl/server-key.pem -etcd-prefix=/k8s/network"
```
创建flanneld systemd文件
```
vim /usr/lib/systemd/system/flanneld.service
[Unit]
Description=Flanneld overlay address etcd agent
After=network-online.target network.target
Before=docker.service
 
[Service]
Type=notify
EnvironmentFile=/k8s/kubernetes/cfg/flanneld
ExecStart=/k8s/kubernetes/bin/flanneld --ip-masq $FLANNEL_OPTIONS
ExecStartPost=/k8s/kubernetes/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/subnet.env
Restart=on-failure
 
[Install]
WantedBy=multi-user.target
```
注意
>mk-docker-opts.sh 脚本将分配给 flanneld 的 Pod 子网网段信息写入 /run/flannel/docker 文件，后续 docker 启动时 使用这个文件中的环境变量配置 docker0 网桥；
flanneld 使用系统缺省路由所在的接口与其它节点通信，对于有多个网络接口（如内网和公网）的节点，可以用 -iface 参数指定通信接口;
flanneld 运行时需要 root 权限；

3）配置Docker启动指定子网
修改EnvironmentFile=/run/flannel/subnet.env，ExecStart=/usr/bin/dockerd $DOCKER_NETWORK_OPTIONS即可
```
vim /usr/lib/systemd/system/docker.service 
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service
Wants=network-online.target
 
[Service]
Type=notify
EnvironmentFile=/run/flannel/subnet.env
ExecStart=/usr/bin/dockerd $DOCKER_NETWORK_OPTIONS
ExecReload=/bin/kill -s HUP $MAINPID
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TimeoutStartSec=0
Delegate=yes
KillMode=process
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s
 
[Install]
WantedBy=multi-user.target
```
 
4）启动服务
注意启动flannel前要关闭docker及相关的kubelet这样flannel才会覆盖docker0网桥
```
systemctl daemon-reload
systemctl stop docker
systemctl start flanneld
systemctl enable flanneld
systemctl start docker
systemctl restart kubelet
systemctl restart kube-proxy
```

5）验证服务
```
[root@elasticsearch02 bin]# cat /run/flannel/subnet.env 
DOCKER_OPT_BIP="--bip=10.254.35.1/24"
DOCKER_OPT_IPMASQ="--ip-masq=false"
DOCKER_OPT_MTU="--mtu=1450"
DOCKER_NETWORK_OPTIONS=" --bip=10.254.35.1/24 --ip-masq=false --mtu=1450"
```
```
[root@elasticsearch02 bin]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP qlen 1000
    link/ether 52:54:00:a4:ca:ff brd ff:ff:ff:ff:ff:ff
    inet 10.2.8.65/24 brd 10.2.8.255 scope global eth0
       valid_lft forever preferred_lft forever
3: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN 
    link/ether 02:42:06:0a:ab:32 brd ff:ff:ff:ff:ff:ff
    inet 10.254.35.1/24 brd 10.254.35.255 scope global docker0
       valid_lft forever preferred_lft forever
4: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN 
    link/ether 72:59:dc:2b:0a:21 brd ff:ff:ff:ff:ff:ff
    inet 10.254.35.0/32 scope global flannel.1
       valid_lft forever preferred_lft forever
```
```
[root@elasticsearch01 k8s]# kubectl get nodes
NAME        STATUS   ROLES    AGE    VERSION
10.2.8.34   Ready    <none>   16h    v1.13.1
10.2.8.65   Ready    <none>   18h    v1.13.1
```