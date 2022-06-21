# playbook for phoenix

## 使用说明
### 安装配置
- 安装
```
ansible-playbook -i hosts --tags install books/phoenix/phoenix.yaml
```
- 连接
```
ansible-playbook -i hosts --tags link books/phoenix/phoenix.yaml
```
- 测试
```
/opt/phoenix-hbase-2.4-5.1.2-bin/bin/sqlline.py wsl:2181
```
### 客户端
- 引用
```
phoenix-client-hbase-2.4-5.1.2.jar
compile fileTree(dir:'libs', include:['*.jar'])
```
- 连接
```
jdbc:phoenix:zk1,zk2,zk3:2181?user=&password=
```

## 最佳实践

### 索引类型
- 覆盖索引（Covered Indexes）：索引表中包含全部字段数据。
```
create index my_index on test (v1) include(v2);
```
- 全局索引（Global Indexes）：适用于读多写少的场景，所有对数据的增删改操作都会更新索引表。
```
create index my_index on test (v1);
```
- 局部索引（Local Indexes）：适用于写多读少场景，索引表数据和主表数据会放在同一RegionServer上。
```
create local index my_index on test (v1);
```

### 分区管理
- 预分区数量
```
CREATE TABLE SALT_TEST (a_key VARCHAR PRIMARY KEY, a_col VARCHAR) SALT_BUCKETS = 20;
```
- 分区原理

Phoenix Salted Table的实现原理是在将一个散列取余后的byte值插入到 rowkey的第一个字节里，并通过定义每个region的start key 和 end key 将数据分割到不同的region，以此来防止自增序列引入的热点问题，从而达到平衡HBase集群的读写性能的目的。
Salted Byte的计算方式大致如下：
```
hash(rowkey) % SALT_BUCKETS
```

### 存储格式
- 关闭列映射
```
# hbase-site.xml
<property>
  <name>phoenix.default.column.encode .bytes.attrib</name>
  <value>0</value>
</property>
# DDL
COLUMN_ENCODED_BYTES = 0
```
- 默认列簇名称
```
CREATE VIEW "my_hbase_table" ( k VARCHAR primary key, "v" UNSIGNED_LONG) default_column_family='a';
```

## 常见问题

### phoenix进不去sqlline.py,一直卡住(不报错)

可能是hbase在zookeeper中的meta信息不一致导致的。


## 参考
- [HBase 4、Phoenix安装和Squirrel安装](https://www.cnblogs.com/raphael5200/p/5260198.html)
- [Phoenix 原理 以及 Phoenix在HBase中的应用](https://blog.csdn.net/zhangshenghang/article/details/98183514)
- [Phoenix使用SALT_BUCKETS创建预分区](https://blog.csdn.net/sinat_36121406/article/details/82985880)
- [Apache Phoenix(五)新特性之存储格式](https://www.jianshu.com/p/20ba9c7ab977)
