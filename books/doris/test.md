# Doris Test Case

三节点集群，每个节点上各一个BE和FE服务。

## 大表JOIN关联查询测试

### 数据准备

- 环境准备
```
mkdir /data/doris/jdbc_drivers
ls /mnt/c/Users/Ouyang/.m2/repository/mysql/mysql-connector-java/8.0.30/mysql-connector-java-8.0.30.jar
mysql -h 127.0.0.1 -P 9030 -uroot -p
```
- 创建外部数据库
```
CREATE CATALOG fs_mysql PROPERTIES (
    "type"="jdbc",
    "user"="root",
    "password"="admin888",
    "jdbc_url" = "jdbc:mysql://wsl:3306/fs_test",
    "driver_url" = "mysql-connector-java-8.0.30.jar",
    "driver_class" = "com.mysql.cj.jdbc.Driver"
);
```
- 创建本地测试库
```
create database if not exists fs_demo;
use internal.fs_demo;
```
- 创建测试表
```
CREATE TABLE fs_demo.dwd_company_info (
  `base_id` varchar(64) NOT NULL,
  `unicode` varchar(64) NOT NULL,
  `base_name` varchar(255) NOT NULL,
  `state` varchar(128) NOT NULL,
  `type` varchar(255) NOT NULL,
  `legal` varchar(1000) NOT NULL,
  `legal_id` char(32) NOT NULL,
  `address` text NOT NULL,
  `registry_time` varchar(32) NOT NULL,
  `is_delete` boolean NOT NULL
)
UNIQUE KEY(`base_id`)
DISTRIBUTED BY HASH(`base_id`) BUCKETS AUTO;

CREATE TABLE fs_demo.dwd_company_gps_info (
  `base_id` varchar(64) NOT NULL,
  `company_id` varchar(64) NOT NULL,
  `address` varchar(1000) NOT NULL,
  `province_name` varchar(255) NOT NULL,
  `city_name` varchar(255) NOT NULL,
  `county_name` varchar(255) NOT NULL,
  `province` varchar(255) NOT NULL,
  `city` varchar(255) NOT NULL,
  `county` varchar(255) NOT NULL,
  `location_x` varchar(255) NOT NULL,
  `location_y` varchar(255) NOT NULL,
  `registry_authority` varchar(255) NOT NULL,
  `is_delete` boolean NOT NULL
)
UNIQUE KEY(`base_id`)
DISTRIBUTED BY HASH(`base_id`) BUCKETS AUTO;

CREATE TABLE fs_demo.dwd_company_copyright (
  `base_id` varchar(32) NOT NULL,
  `card` varchar(32) NOT NULL,
  `full_name` varchar(255) NOT NULL,
  `short_name` varchar(255) NOT NULL,
  `company_id` varchar(32) NOT NULL,
  `company_name` varchar(255) NOT NULL,
  `is_delete` boolean NOT NULL
)
UNIQUE KEY(`base_id`)
DISTRIBUTED BY HASH(`base_id`) BUCKETS AUTO;
```
- 导入测试数据
```
insert into internal.fs_demo.dwd_company_info select
    base_id, unicode, base_name, state, type, legal, legal_id, address, registry_time, is_delete
    from fs_mysql.fs_test.dwd_company_info;
-- Query OK, 59633966 rows affected (6 min 21.16 sec)
insert into internal.fs_demo.dwd_company_gps_info select
    base_id, company_id, new_address, new_province_name, new_city_name, new_county_name,
    new_province, new_city, new_county, new_location_x, new_location_y, new_registry_authority, is_delete
    from fs_mysql.fs_test.dwd_company_gps_info;
-- Query OK, 58872092 rows affected (6 min 45.31 sec)
insert into internal.fs_demo.dwd_company_copyright select
    base_id, card, full_name, short_name, company_id, company_name, is_delete
    from fs_mysql.fs_test.dwd_company_copyright;
-- Query OK, 6482511 rows affected (31.51 sec)
```

### 测试用例

- 大表JOIN查询
```
select state, count(*) as ct from dwd_company_info group by state order by ct desc
\G; -- Elapsed: 2.80s, 0.34s

select b.province_name, count(c.base_id) as ct
from dwd_company_info as a
left join dwd_company_gps_info as b on a.base_id = b.company_id
right join dwd_company_copyright as c on a.base_id = c.company_id
where a.state in ('在业', '开业', '存续', '在营', '正常', '在营（开业）', '在营（开业）企业', '存续（在营、开业、在册）', '存续(在营、开业、在册)')
group by b.province_name order by ct desc
\G; -- Elapsed: 7.21s
```
