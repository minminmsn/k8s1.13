**1.添加LDAP认证**

全局--安全--认证--编辑--启用OpenLDAP认证

设置仅允许授权的用户和组织，方便账号管理及安全使用

> ![](https://upload-images.jianshu.io/upload_images/7535971-6b4a4ed77c78c93e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


**2.添加通知**

Local--工具--通知

默认支持Slack、Mail、PagerDuty、Webhook、企业微信、钉钉、Microfoft Teams，这里选择邮件

> ![](https://upload-images.jianshu.io/upload_images/7535971-2741cc650d84097d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![](https://upload-images.jianshu.io/upload_images/7535971-846c1b773b9786c0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)




**3.添加日志**

Local--工具--日志

有Elasticsearch、Splunk、Kafka、Syslog、Fluentd，这里使用的是Elasticsearch

> ![](https://upload-images.jianshu.io/upload_images/7535971-c6936d64e3afcf53.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![](https://upload-images.jianshu.io/upload_images/7535971-4c493bd1157b3417.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)




**4.集成Gitlab**

Local--Defalt--工具--流水线

需要先在Gitlab对应项目账号中新建Application，然后在流水线中配置Gitlab应用，设置好id和secret后验证确认授权

> ![](https://upload-images.jianshu.io/upload_images/7535971-0034aa0b24ed5812.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![](https://upload-images.jianshu.io/upload_images/7535971-c9d0189bcdf86fe2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![](https://upload-images.jianshu.io/upload_images/7535971-5163c228931794c5.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![](https://upload-images.jianshu.io/upload_images/7535971-00a80ee8e16d223b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


**5.配置镜像库凭证**

Local--Default--资源--密文--镜像库凭证列表--添加凭证

> ![](https://upload-images.jianshu.io/upload_images/7535971-44a6fe71d1ef52b2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![](https://upload-images.jianshu.io/upload_images/7535971-93f25e25f29484ce.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![](https://upload-images.jianshu.io/upload_images/7535971-5be1e241c8333a2e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)




**6.配置流水线**

Local--Default--资源--流水线--设置代码库--启用项目--编辑流水线

> ![](https://upload-images.jianshu.io/upload_images/7535971-eb9f3043016ef83a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![](https://upload-images.jianshu.io/upload_images/7535971-ba1f46af4f7d774f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![](https://upload-images.jianshu.io/upload_images/7535971-2d2932e64a84c235.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![](https://upload-images.jianshu.io/upload_images/7535971-55da5aee3fc4d77e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)





查看YAML如下


```
stages:
- name: Build
  steps:
  - runScriptConfig:
      image: core-harbor.minminmsn.com/public/centos-jdk8-maven
      shellScript: bash ./build.sh
- name: Publish
  steps:
  - publishImageConfig:
      dockerfilePath: ./Dockerfile
      buildContext: .
      tag: core-harbor.minminmsn.com/public/${CICD_GIT_REPO_NAME}:${CICD_GIT_COMMIT}
      pushRemote: true
      registry: core-harbor.minminmsn.com
- name: Deploy
  steps:
  - applyYamlConfig:
      path: ./deployment.yaml
notification:
  recipients:
  - recipient: op@minminmsn.com
    notifier: local:n-chlz9
  condition:
  - Success
  
```  

**7.运行流水线**

> ![](https://upload-images.jianshu.io/upload_images/7535971-cffe463751b55870.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![](https://upload-images.jianshu.io/upload_images/7535971-3b7aa0f8620e3d52.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


部署成功可以发邮件

> ![](https://upload-images.jianshu.io/upload_images/7535971-b13b003f780e454d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


**8.最后架构图如下**

> ![](https://upload-images.jianshu.io/upload_images/7535971-230d6eb34f02d5bc.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
