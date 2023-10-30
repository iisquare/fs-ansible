# playbook for doris


## 使用说明

### BE节点环境
- max_map_count
```
sysctl -a|grep vm.max_map_count
sysctl -w vm.max_map_count=2000000
vi /etc/sysctl.conf
vm.max_map_count=2000000
sysctl -p
```
- ulimit
```
ulimit -a
ulimit -n 65536
vi /etc/security/limits.conf
*　　soft　　nofile　　65536
*　　hard　　nofile　　65536
```
- swap
```
free -h
swapoff -a
# swapon -a
vi /etc/fstab
# 通过注释掉swap分区挂载以永久生效
```
### 创建节点目录
```
mkdir -p /data/doris/log
mkdir -p /data/doris/meta
mkdir -p /data/doris/storage
```

### 安装配置
- 安装
```
ansible-playbook -i hosts --tags install books/doris/doris.yaml
```
- 配置
```
ansible-playbook -i hosts --tags config books/doris/doris.yaml
```
- 清空
```
ansible-playbook -i hosts --tags clear books/doris/doris.yaml
```

### 集群部署扩容
- FE节点
```
# 第一个启动的节点
/opt/apache-doris-2.0.2-bin-x64/fe/bin/start_fe.sh --daemon
# 其他节点第一次启动时，需要通过helper指定第一个启动的节点，之后不再需要
/opt/apache-doris-2.0.2-bin-x64/fe/bin/start_fe.sh --helper 192.168.80.101:9010 --daemon
```
- BE节点
```
/opt/apache-doris-2.0.2-bin-x64/be/bin/start_be.sh --daemon
```
- Broker节点
```
/opt/apache-doris-2.0.2-bin-x64/extensions/apache_hdfs_broker/bin/start_broker.sh --daemon
```
- 加入节点
```
yum install mysql
# 连接至第一个启动的Leader节点
mysql -h 192.168.80.101 -P 9030 -uroot -p
SHOW FRONTENDS\G;
ALTER SYSTEM ADD FOLLOWER "192.168.80.102:9010";
ALTER SYSTEM ADD OBSERVER "192.168.80.103:9010";
SHOW BACKENDS\G;
ALTER SYSTEM ADD BACKEND "192.168.80.101:9050";
ALTER SYSTEM ADD BACKEND "192.168.80.102:9050";
ALTER SYSTEM ADD BACKEND "192.168.80.103:9050";
SHOW BROKER\G;
ALTER SYSTEM ADD BROKER fs_broker "192.168.80.101:8000";
ALTER SYSTEM ADD BROKER fs_broker "192.168.80.102:8000";
ALTER SYSTEM ADD BROKER fs_broker "192.168.80.103:8000";
```
- 管理
```
/opt/apache-doris-2.0.2-bin-x64/fe/bin/start_fe.sh --daemon
/opt/apache-doris-2.0.2-bin-x64/be/bin/start_be.sh --daemon
/opt/apache-doris-2.0.2-bin-x64/extensions/apache_hdfs_broker/bin/start_broker.sh --daemon
/opt/apache-doris-2.0.2-bin-x64/fe/bin/stop_fe.sh
/opt/apache-doris-2.0.2-bin-x64/be/bin/stop_be.sh
/opt/apache-doris-2.0.2-bin-x64/extensions/apache_hdfs_broker/bin/stop_broker.sh
```

### 服务地址
- fe:http_port = 8030
- be:webserver_port = 8040

### 常用命令
- 数据导入
```
# 建库建表
> create database fs_example;
> CREATE TABLE fs_example.t_demo
(
  k1 BOOLEAN,
  k2 TINYINT,
  k3 DECIMAL(10, 2) DEFAULT "10.5",
  v1 CHAR(10) REPLACE,
  v2 INT SUM
)
ENGINE=olap
AGGREGATE KEY(k1, k2, k3)
COMMENT "doris demo table"
DISTRIBUTED BY HASH(k1) BUCKETS 32;

# 在hdfs上创建一个txt文件
cat demo.txt
0,100,9,a
1,200,8,b
0,300,7,c

hdfs dfs -put demo.txt hdfs://node101:8020/examples/

# 使用load broker导入数据
> LOAD LABEL fs_example.label_filter
(
	DATA INFILE("hdfs://node101:8020/examples/demo.txt")
	INTO TABLE `t_demo`
	COLUMNS TERMINATED BY ","
	(k1,k2,v1,v2)
) 
with broker 'fs_broker' (
	"username"="root",
	"password"=""
);

# 查看导入情况
> SHOW LOAD FROM fs_example order by createtime desc limit 1\G;
```

## 参考
- [Apache Doris Docs](https://doris.apache.org/zh-CN/docs/get-starting/)
