eapster 已经被废弃了，后续版本中会使用 metrics-server 代替。
https://kubernetes.io/docs/tasks/debug-application-cluster/core-metrics-pipeline/#metrics-server

https://github.com/kubernetes-incubator/metrics-server/tree/master/deploy/1.8%2B

Metrics Server
Metrics Server is a cluster-wide aggregator of resource usage data. Starting from Kubernetes 1.8 it’s deployed by default in clusters created by kube-up.sh script as a Deployment object. If you use a different Kubernetes setup mechanism you can deploy it using the provided deployment yamls. It’s supported in Kubernetes 1.7+ (see details below).
Metric server collects metrics from the Summary API, exposed by Kubelet on each node.
Metrics Server registered in the main API server through Kubernetes aggregator, which was introduced in Kubernetes 1.7.
Learn more about the metrics server in the design doc.

git clone https://github.com/kubernetes-incubator/metrics-server
cd metrics-server
kubectl create -f deploy/1.8+/


kubectl -n kube-system get pods -l k8s-app=metrics-server

