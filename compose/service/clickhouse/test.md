# ClickHouse Test Case

对fs_test三节点两分片进行测试，其中一个分片2个副本，另一个分片1个副本。


## 集群测试

- 集群名称： fs_test
- 本地库名称： fs_local
- 分布式库名称： fs_dist
- 查询视图库名称： fs_view
- 数据表名称： t_data

### 集群配置

- 修改metrika.xml配置文件，更改宏变量
```
<!-- node101 -->
<macros>
    <shard>shard_1</shard>
    <replica>rep_1_1</replica>
</macros>
<!-- node102 -->
<macros>
    <shard>shard_1</shard>
    <replica>rep_1_2</replica>
</macros>
<!-- node103 -->
<macros>
    <shard>shard_2</shard>
    <replica>rep_2_1</replica>
</macros>
```

### 创建测试结构
- 创建数据库
```
create database if not exists fs_local on cluster fs_test;
create database if not exists fs_dist on cluster fs_test;
create database if not exists fs_view on cluster fs_test;
show databases;
```
- 创建本地表
```
CREATE TABLE fs_local.t_data on cluster fs_test (
`id` Int32,
`name` String,
`score` Float32,
`_sign` Int8,
`_version` UInt64
) ENGINE = ReplicatedReplacingMergeTree('/clickhouse/table/{shard}/t_data', '{replica}')
ORDER BY (id);
show tables from fs_local;
show create table fs_local.t_data;
```
- 创建分布式表
```
CREATE TABLE fs_dist.t_data on cluster fs_test as fs_local.t_data ENGINE = Distributed('fs_test', 'fs_local', 't_data', intHash64(id));
show tables from fs_dist;
show create table fs_dist.t_data;
```
- 创建视图
```
CREATE VIEW fs_view.t_data on cluster fs_test as select * from fs_dist.t_data final where _sign = 1;
show tables from fs_view;
show create table fs_view.t_data;
```

### 数据测试
- 通过分布式表写入数据
```
insert into fs_dist.t_data (id, name, score, _sign, _version) values (1, 'a', 3, 1, 0);
insert into fs_dist.t_data (id, name, score, _sign, _version) values (2, 'b', 5, 1, 0);
insert into fs_dist.t_data (id, name, score, _sign, _version) values (3, 'c', 7, 1, 0);
```
- 查看数据分布
```
select * from fs_local.t_data;
select * from fs_dist.t_data;
select * from fs_view.t_data;
```
- 通过分布式表追加更新和删除
```
insert into fs_dist.t_data (id, name, score, _sign, _version) values (1, 'a', 9, 1, 1);
insert into fs_dist.t_data (id, name, score, _sign, _version) values (2, 'b', 5, -1, 1);
```
- 通过视图查询最终结果
```
select * from fs_view.t_data;
```

### 清理测试结构
- 删除数据库
```
drop database if exists fs_local on cluster fs_test;
drop database if exists fs_dist on cluster fs_test;
drop database if exists fs_view on cluster fs_test;
```
- 清理注册中心
```
sudo docker-compose exec zookeeper zkCli.sh
deleteall /clickhouse/table/shard_1/t_data
deleteall /clickhouse/table/shard_2/t_data
```
