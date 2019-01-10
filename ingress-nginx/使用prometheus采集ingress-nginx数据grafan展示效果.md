## 使用prometheus采集ingress-nginx数据grafan展示效果
### 参考文档
```
https://akomljen.com/get-kubernetes-cluster-metrics-with-prometheus-in-5-minutes/
https://github.com/kubernetes/ingress-nginx/tree/f56e839134fd4a1d020c3e95d4fe89496225041c/deploy/grafana/dashboards
https://github.com/kubernetes/ingress-nginx/tree/f56e839134fd4a1d020c3e95d4fe89496225041c/deploy/monitoring
```

### 部署monitoring
在ingress-nginx官网deploy/monitoring目录下载相关yaml文件

```
[root@elasticsearch01 monitoring]# pwd
/k8s/yaml/ingress-nginx/monitoring
[root@elasticsearch01 monitoring]# ls
configuration.yaml  grafana.yaml  prometheus.yaml
```

使用kubectl部署prometheus和grafana容器pod
```
[root@elasticsearch01 monitoring]# kubectl create -f ./
configmap/prometheus-configuration created
deployment.extensions/grafana created
service/grafana created
role.rbac.authorization.k8s.io/prometheus-server created
serviceaccount/prometheus-server created
rolebinding.rbac.authorization.k8s.io/prometheus-server created
deployment.apps/prometheus-server created
service/prometheus-server created
```

查看对外暴露端口，服务以NoderPort方式对外提供服务
prometheus访问地址为：http://10.2.8.65:37941
grafana访问地址为：http://10.2.8.34:32358
以上服务也可以部署ingress服务，通过域名访问
```
[root@elasticsearch01 monitoring]# kubectl get pods,svc -n ingress-nginx -o wide|egrep "grafana|prome"
pod/grafana-69549786b6-69sqm                    1/1     Running   0          14m     10.254.73.6   10.2.8.34   <none>           <none>
pod/prometheus-server-8658d8cdbb-8kf2g          1/1     Running   0          14m     10.254.35.7   10.2.8.65   <none>           <none>
service/grafana             NodePort       10.254.108.105   <none>        3000:32358/TCP               14m     app.kubernetes.io/name=grafana,app.kubernetes.io/part-of=ingress-nginx
service/prometheus-server   NodePort       10.254.155.29    <none>        9090:37941/TCP               14m     app.kubernetes.io/name=prometheus,app.kubernetes.io/part-of=ingress-nginx
```


### 配置grafana
在ingress-nginx官网deploy/grafana/dashboards目录下载相关nginx.json文件

配置prometheus数据源

导入dashboard

最终展示效果如下



