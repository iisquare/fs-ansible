# MinIO


## 使用说明

### 安装配置
- 初始化
```
ansible-playbook -i hosts --tags init compose/service/minio/minio.yaml
```
- 同步镜像
```
./sbin/docker-archive.sh -i quay.io/minio/minio -v RELEASE.2022-06-20T23-13-45Z -u root -h node101,node102,node103
```
- 默认认证
```
minioadmin:minioadmin
```
- 启动服务
```
docker-compose up -d minio
docker-compose logs -f minio
```
- 重置清理
```
docker-compose stop minio
docker-compose rm -f minio
rm -rf /data/minio/
```

### 注意事项

- 默认端口可能与大数据服务冲突
- 纠删码需要至少4个磁盘，若单个节点磁盘数过少服务可能启动异常
```
Marking http://node103:9000/minio/storage/export1/v43 temporary offline; caused by Post "http://node103:9000/minio/storage/export1/v43/readall?disk-id=&file-path=format.json&volume=.minio.sys": dial tcp 192.168.80.132:9000: connect: connection refused (*fmt.wrapError)
```
- 采用导出端口方式可能会导致访问异常，故调整为节点绑定
```
Unable to read 'format.json' from http://node101:9000/export1: Do not upgrade one server at a time - please follow the recommended guidelines mentioned here https://github.com/minio/minio#upgrading-minio for your environment
```


## 参考
- [MinIO Quickstart Guide](https://docs.min.io/docs/minio-quickstart-guide.html)
- [Minio分布式集群搭建部署](https://www.cnblogs.com/lvzhenjiang/p/14943939.html)
