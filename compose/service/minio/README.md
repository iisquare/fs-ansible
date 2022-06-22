# MinIO


## 使用说明

### 安装配置
- 初始化
```
ansible-playbook -i hosts --tags init compose/service/minio/minio.yaml
```
- 同步镜像
```
./sbin/docker-archive.sh -i minio/minio -v RELEASE.2022-03-24T00-43-44Z -u root -h node101,node102,node103,node104
```
- 默认认证
```
minioadmin:minioadmin
```
- 启动服务
```
docker-compose up -d minio
docker-compose logs minio
```
- 重置清理
```
docker-compose stop minio
docker-compose rm -f minio
rm -rf /data/minio/
```

### 注意事项

- 默认端口可能与大数据服务冲突


## 参考
- [MinIO Quickstart Guide](https://docs.min.io/docs/minio-quickstart-guide.html)
- [Minio分布式集群搭建部署](https://www.cnblogs.com/lvzhenjiang/p/14943939.html)
