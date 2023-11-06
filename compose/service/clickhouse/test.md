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

## 大表JOIN关联查询测试

### 数据准备

- 创建外部数据库
```
CREATE DATABASE fs_test_mysql ENGINE = MySQL('wsl:3306', 'fs_test', 'root', 'admin888');
```
- 创建本地测试库
```
create database if not exists fs_test_local;
```
- 创建测试表
```
CREATE TABLE fs_test_local.dwd_company_info (
`base_id` String,
`unicode` String,
`base_name` String,
`state` String,
`type` String,
`legal` String,
`legal_id` String,
`address` String,
`registry_time` String,
`is_delete` UInt64,
`_sign` Int8,
`_version` UInt64
) ENGINE = ReplacingMergeTree(_version)
ORDER BY (base_id);

CREATE TABLE fs_test_local.dwd_company_gps_info (
`base_id` String,
`company_id` String,
`address` String,
`province_name` String,
`city_name` String,
`county_name` String,
`province` String,
`city` String,
`county` String,
`location_x` String,
`location_y` String,
`registry_authority` String,
`is_delete` UInt64,
`_sign` Int8,
`_version` UInt64
) ENGINE = ReplacingMergeTree(_version)
ORDER BY (base_id);

CREATE TABLE fs_test_local.dwd_company_copyright (
`base_id` String,
`card` String,
`full_name` String,
`short_name` String,
`company_id` String,
`company_name` String,
`is_delete` UInt64,
`_sign` Int8,
`_version` UInt64
) ENGINE = ReplacingMergeTree(_version)
ORDER BY (base_id);
```
- 导入测试数据
```
insert into fs_test_local.dwd_company_info select
    base_id, unicode, base_name, state, type, legal, legal_id, address, registry_time, is_delete,
    1 as _sign, toUnixTimestamp(now()) as _version from fs_test_mysql.dwd_company_info;
-- 0 rows in set. Elapsed: 211.496 sec. Processed 59.63 million rows, 17.74 GB (281.96 thousand rows/s., 83.87 MB/s.)
-- Peak memory usage: 1021.73 MiB.
insert into fs_test_local.dwd_company_gps_info select
    base_id, company_id, new_address, new_province_name, new_city_name, new_county_name,
    new_province, new_city, new_county, new_location_x, new_location_y, new_registry_authority, is_delete,
    1 as _sign, toUnixTimestamp(now()) as _version from fs_test_mysql.dwd_company_gps_info;
-- 0 rows in set. Elapsed: 186.468 sec. Processed 58.87 million rows, 18.63 GB (315.72 thousand rows/s., 99.90 MB/s.)
-- Peak memory usage: 1.06 GiB.
insert into fs_test_local.dwd_company_copyright select
    base_id, card, full_name, short_name, company_id, company_name, is_delete,
    1 as _sign, toUnixTimestamp(now()) as _version from fs_test_mysql.dwd_company_copyright;
-- 0 rows in set. Elapsed: 19.837 sec. Processed 6.48 million rows, 1.21 GB (326.78 thousand rows/s., 61.18 MB/s.)
-- Peak memory usage: 568.41 MiB.
```

### 测试用例

- 大表JOIN查询
```
use fs_test_local;

select state, count(*) as ct from dwd_company_info group by state order by ct desc
\G; -- Elapsed: 0.427s, Peak memory usage: 1.41M

select b.province_name, count(c.base_id) as ct
from dwd_company_info as a
left join dwd_company_gps_info as b on a.base_id = b.company_id
right join dwd_company_copyright as c on a.base_id = c.company_id
where a.state in ('在业', '开业', '存续', '在营', '正常', '在营（开业）', '在营（开业）企业', '存续（在营、开业、在册）', '存续(在营、开业、在册)')
group by b.province_name order by ct desc
\G; -- Elapsed: 17.324s, Peak memory usage: 12.79G
```
