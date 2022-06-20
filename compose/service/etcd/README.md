# Etcd

## 使用说明

### 生成证书

- 进入证书目录
```
cd compose/service/etcd/ssl/
```
- 生成CA私钥和证书
```
openssl genrsa -out ca.key 2048
openssl req -x509 -new -nodes -key ca.key -subj "/CN=fs-project" -days 365 -out ca.crt
```
- 配置etcd-ca.conf文件
- 生成密钥
```
openssl genrsa -out etcd.key 2048
```
- 生成证书签发请求(certificate signing request)
```
openssl req -new -key etcd.key -out etcd.csr -config etcd-ca.conf
```
- 生成证书
```
openssl x509 -req -in etcd.csr -CA ca.crt -CAkey ca.key \
-CAcreateserial -out etcd.crt -days 365 \
-extensions v3_ext -extfile etcd-ca.conf
```
- 验证证书
```
openssl verify -CAfile ca.crt etcd.crt
```

### 安装配置
- 初始化
```
ansible-playbook -i hosts --tags init compose/service/etcd/etcd.yaml
```
- 同步镜像
```
./sbin/docker-archive.sh -i bitnami/etcd -v 3.5.4 -u root -h node101,node102,node103
```

## 参考
- [搭建高可用Etcd集群 (TLS)](https://www.jianshu.com/p/d7e53895338f)
- [搭建 etcd 集群](https://doczhcn.gitbook.io/etcd/index/index-1/clustering)
- [etcd配置文件详解](https://www.cnblogs.com/linuxws/p/11194403.html)
