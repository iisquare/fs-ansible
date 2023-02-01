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
- 清理注册中心
```
sudo docker-compose exec zookeeper zkCli.sh
deleteall /clickhouse/
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
- 在JOIN关联查询时，遵循小表在右的原则，尽量将过滤条件加在JOIN的子查询中，若左表为子查询则分布式规则不生效。
```
select ...
from t_all -- 左表避免使用子查询，否则分布式规则不生效
join ( -- 右表本身直接走本地表
  select ...
  from t_local
  where t_local.filter = xxx -- 尽可能手动将条件放在子查询中
)
where
  t_local.f = xxx -- 当前版本不支持自动下推到JOIN查询中，需要手动修改
  and t_all.f in (
    select ... from xxx -- 若能将子查询作为筛选条件更佳
  )
```


## 参考
- [ClickHouse Docs](https://clickhouse.com/docs/en/intro)
- [ClickHouse-集群部署以及副本和分片](https://blog.csdn.net/clearlxj/article/details/121774940)
