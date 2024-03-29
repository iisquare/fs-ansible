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
./sbin/docker-archive.sh -i clickhouse/clickhouse-server -v 23.8.4.69 -u root -h node101,node102,node103
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
- 清理注册中心
```
sudo docker-compose exec zookeeper zkCli.sh
deleteall /clickhouse
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
- 查询
```
select * from fs_test;
select id, name, score, time, _version from fs_test final where _sign=1;
select id, name, score, time, max(_version) from fs_test group by id, name, score, time having _sign=1;
```

### 优化调试

- 查看表数据量大小
```
select
    database,
    table,
    formatReadableSize(size) as size,
    formatReadableSize(bytes_on_disk) as bytes_on_disk,
    formatReadableSize(data_uncompressed_bytes) as data_uncompressed_bytes,
    formatReadableSize(data_compressed_bytes) as data_compressed_bytes,
    compress_rate,
    rows,
    days,
    formatReadableSize(avgDaySize) as avgDaySize
from (
    select
        database,
        table,
        sum(bytes) as size,
        sum(rows) as rows,
        min(min_date) as min_date,
        max(max_date) as max_date,
        sum(bytes_on_disk) as bytes_on_disk,
        sum(data_uncompressed_bytes) as data_uncompressed_bytes,
        sum(data_compressed_bytes) as data_compressed_bytes,
        (data_compressed_bytes / data_uncompressed_bytes) * 100 as compress_rate,
        max_date - min_date as days,
        size / (max_date - min_date) as avgDaySize
    from system.parts
    where active  and database = 'database' and table = 'tablename'
    group by database, table
)
```
- 查看参数配置
```
show settings ilike 'max_%';
-- max_memory_usage: 单个查询的最大内存，可以与所有查询的最大内存一致
-- max_memory_usage_for_all_queries： 单个服务器上所有查询的最大内存，要给系统预留一些
-- max_bytes_before_external_group_by: 可以为查询内存的一半，达到限制后写磁盘进行分组计算
-- max_server_memory_usage: 服务使用的最大内存，默认为（memory_amount * max_server_memory_usage_to_ram_ratio）
```
- 查看当前连接数
```
SELECT * FROM system.metrics WHERE metric LIKE '%Connection';
```
- 正在执行的查询
```
SELECT query_id, user, address, query  FROM system.processes ORDER BY query_id;
KILL QUERY WHERE query_id='ff695827-dbf5-45ad-9858-a853946ea140';
SELECT database, table, mutation_id, command, create_time, is_done FROM system.mutations;
KILL MUTATION WHERE mutation_id = ‘mutation_id’;
```
- 查询耗时及资源占用
```
SELECT 
    user as user, 
    client_hostname AS client_hostname, 
    client_name AS client_name, 
    query_start_time AS query_start_time, 
    query_duration_ms / 1000 AS query_duration, 
    round(memory_usage / 1048576) AS memory_usage, 
    result_rows AS result_rows, 
    result_bytes / 1048576 AS result_bytes, 
    read_rows AS read_rows, 
    round(read_bytes / 1048576) AS read_bytes, 
    written_rows AS written_rows, 
    round(written_bytes / 1048576) AS written_bytes, 
    query
FROM system.query_log
WHERE type = 2
ORDER BY query_start_time DESC
LIMIT 3\G;
```


## 常见问题

### 查询异常
- 异常信息
```
Received exception from server (version 22.7.1):
Code: 74. DB::Exception: Received from localhost:9000. DB::ErrnoException. DB::ErrnoException: Cannot read from file 34, errno: 1, strerror: Operation not permitted: (while reading column id): While executing MergeTreeInOrder. (CANNOT_READ_FROM_FILE_DESCRIPTOR)
```
- 问题原因[issue: #13726](https://github.com/ClickHouse/ClickHouse/issues/13726)
```
Docker cannot run any binaries with filesystem capabilities in unprivileged mode.
```
- 解决方法
```
privileged: true
```

### 分布式表查询异常
- 异常信息
```
Code: 516. DB::Exception: Received from localhost:9000. DB::Exception: Received from node102:9000. DB::Exception: default: Authentication failed: password is incorrect or there is no user with such name. (AUTHENTICATION_FAILED)
```
- 问题原因：集群开启了用户验证，但在集群分片的配置中没有配置用户名和密码
- 解决方法
```
<cluster_name>
    <shard>
        <replica>
            <host>xxxxxx</host>
            <port>9000</port>
            <user>root</user>
            <password>admin888</password>
        </replica>
    </shard>
</cluster_name>
```

### 执行脚本异常
- 使用Docker环境执行上万行建表语句脚本
```
clickhouse-client --user 登录名 --password 密码 -d 数据库 --multiquery < ddl.sql
```
- 异常信息
```
Unmatched parentheses: (. (SYNTAX_ERROR)
```
- [解决方案](https://github.com/ClickHouse/ClickHouse/issues/19950)
```
clickhouse-client --user 登录名 --password 密码 -d 数据库 -mn < ddl.sql
```

### 注意事项

- 连表Join查询，当关联记录不存在时，其字段的默认值非NULL。
- 采用Final用以查询最新记录，但在set insert_deduplicate = 1默认启用时，重复记录会被过滤。
```
insert into t_test (id, name, _sign, _version) values (1, 'a', 1, 0);
insert into t_test (id, name, _sign, _version) values (1, 'b', 1, 0);
select * from t_test; -- 同时返回a和b两条记录
select * from t_test final; -- 仅返回b记录
insert into t_test (id, name, _sign, _version) values (1, 'a', 1, 0); -- 该记录会被过滤掉
select * from t_test; -- 同时返回ab两条记录
select * from t_test final; -- 因为最后写入的a记录被过滤掉，仍然返回b记录
-- 建议在每次写入时，通过更新版本号字段强制修改记录内容，以保证返回最新结果
insert into t_test (id, name, _sign, _version) values (1, 'a', 1, 1);
```
- 采用Delete删除记录后Final查询会返回记录中最新的结果，若对应OrderKey存在旧记录会导致业务逻辑错误。
```
insert into t_test (id, name, _sign, _version) values (1, 'c', 1, 0);
insert into t_test (id, name, _sign, _version) values (1, 'c', -1, 1);
select * from t_test; -- 同时返回_sign=1和_sign=-1的记录
select * from t_test final; -- 仅返回_sign=-1的记录
alter table t_test delete where _sign = -1; -- 清理标记删除的数据
select * from t_test final; -- 业务错误，返回_sign=1的记录
insert into t_test (id, name, _sign, _version) values (1, 'd', 1, 0);
select * from t_test; -- 同时返回c和d的记录
select * from t_test final; -- 仅返回d的记录
-- 推荐在清理数据前，在保障业务正常运转的情况下，先手动触发一次合并
optimize table t_test final;
```
- 在关联查询时，Where条件仅下推到左表，应尽量将过滤条件加在JOIN的子查询中，具体以EXPLAIN执行计划为准。
```
// 在大小表Join关联查询时，EXPLAIN JOIN FillRightFirst，应尽量将小表或子查询后的小表放在右侧
enum class JoinPipelineType
{
    /*
     * Right stream processed first, then when join data structures are ready, the left stream is processed using it.
     * The pipeline is not sorted.
     */
    FillRightFirst,

    /*
     * Only the left stream is processed. Right is already filled.
     */
    FilledRight,

    /*
     * The pipeline is created from the left and right streams processed with merging transform.
     * Left and right streams have the same priority and are processed simultaneously.
     * The pipelines are sorted.
     */
    YShaped,
};
```


## 参考
- [ClickHouse Docs](https://clickhouse.com/docs/en/intro)
- [ClickHouse-集群部署以及副本和分片](https://blog.csdn.net/clearlxj/article/details/121774940)
