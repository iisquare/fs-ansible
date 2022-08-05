# ClickHouse


## 使用说明

### 安装配置
- 初始化
```
ansible-playbook -i hosts --tags init compose/service/clickhouse/clickhouse.yaml
```
- 同步配置
```
ansible-playbook -i hosts --tags config compose/service/clickhouse/clickhouse.yaml
```
- 同步镜像
```
./sbin/docker-archive.sh -i clickhouse/clickhouse-server -v 22.7.1.2484 -u root -h node101,node102,node103
```
- 默认认证
```
root:admin888
```
- 启动服务
```
docker-compose up -d clickhouse
docker-compose logs -f clickhouse
docker-compose restart clickhouse
```
- 重置清理
```
docker-compose stop clickhouse
docker-compose rm -f clickhouse
rm -rf /data/clickhouse/
```

### 命令参考
- CLI客户端
```
docker-compose exec clickhouse clickhouse-client --user root --password admin888 -m
```
- 通过集群创建单分片多副本

```
create table <table-name> on cluster <cluster-name> (
  _sign Int8,
  _version UInt64
) engine = ReplicatedMergeTree('/clickhouse/table/{shard}/<table-name>', '{replica}');
其中：
  <table-name> - 表名称
  <cluster-name> - 集群名称
  {shard} - 节点定义的宏变量名称
  {replica} - 节点定义的宏变量名称
  '/clickhouse/table/{shard}/<table-name>' - 在ZK中的存储路径，同一个表的不同副本路径需要一致
  '{replica}' - 副本名称，同一个表的副本名称不能重复
  _sign - 在物化表中，`1`未删除，`-1`已删除
  _version - 在物化表中，表示事务版本计数，通过final查询最新记录
通过on cluster方式创建表，可自动在集群所有节点上自动创建所有副本。
若不通过on cluster方式创建表，可在期望的节点上手动一个个的创建不同表的不同副本。
若集群内存在多个分片，则需要单独创建engine = Distributed表实现数据分片和路由功能。
```
- 查看集群
```
show clusters;
```

### 测试用例
- 创建表
```
create table fs_test on cluster fs_project (
    id UInt32,
    name String,
    score Decimal(16,2),
    time Datetime,
    _sign Int8,
    _version UInt64
) engine = ReplicatedReplacingMergeTree('/clickhouse/tables/{shard}/fs_test','{replica}')
partition by toYYYYMM(time)
primary key (id)
order by (id, name);
```
- 删除表
```
drop table fs_test on cluster fs_project;
sudo docker-compose exec zookeeper zkCli.sh
deleteall /clickhouse/tables/single/fs_test
```
- 数据写入
```
insert into fs_test values
  (1, 'a', 2.1, '2022-08-01 20:30:05', 1, toUnixTimestamp(now())),
  (2, 'b', 3.1, '2022-08-01 20:30:05', 1, toUnixTimestamp(now())),
  (1, 'a', 5.7, '2022-08-01 20:30:06', -1, toUnixTimestamp(now())),
  (2, 'b', 8.9, '2022-08-01 20:30:15', 1, toUnixTimestamp(now())),
  (3, 'c', 1.2, '2022-08-01 20:30:05', 1, toUnixTimestamp(now())),
  (4, 'd', 2.1, '2022-08-01 20:30:05', 1, toUnixTimestamp(now())),
  (5, 'e', 2.1, '2022-08-01 20:30:05', 1, toUnixTimestamp(now()));
```
- 删除数据
```
ALTER TABLE fs_test DELETE WHERE 1=1;
```
- 修改数据
```
ALTER TABLE fs_test UPDATE score = score * 10 WHERE 1=1;
```
- 段合并
```
OPTIMIZE TABLE fs_test FINAL;
```

## 参考
- [ClickHouse Docs](https://clickhouse.com/docs/en/intro)
- [ClickHouse-集群部署以及副本和分片](https://blog.csdn.net/clearlxj/article/details/121774940)
