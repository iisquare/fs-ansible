# playbook for hbase

## 使用说明

### 安装配置
- 安装
```
ansible-playbook -i hosts --tags install books/hbase/hbase.yaml
```
- 配置
```
ansible-playbook -i hosts --tags config books/hbase/hbase.yaml
```
- 兼容
```
ansible-playbook -i hosts --tags fixed books/hbase/hbase.yaml
```
- 手动启动
```
$HBASE_HOME/bin/hbase-daemon.sh start master 
$HBASE_HOME/bin/hbase-daemon.sh start regionserver 
$HBASE_HOME/bin/hbase-daemon.sh start master --backup
$HBASE_HOME/bin/hbase-daemon.sh stop master
$HBASE_HOME/bin/hbase-daemon.sh stop regionserver
```
- 管理
```
$HBASE_HOME/bin/start-hbase.sh
$HBASE_HOME/bin/stop-hbase.sh
$HBASE_HOME/bin/hbase shell
```

### 重置
- 强制停止
```
jps|grep "HMaster\|HRegionServer"|awk '{print $1}'|xargs kill -s TERM
```
- 清理HDFS配置
```
$HADOOP_HOME/bin/hdfs dfs -ls /
$HADOOP_HOME/bin/hdfs dfs -rm -r /hbase
```
- 清理Zookeeper配置
```
deleteall /hbase
```
- 清理日志文件
```
rm -f $HBASE_HOME/logs/*
```

### 服务地址
- Web UI hbase.master.info.port:16010

## 常见问题

### Web UI 中没有HRegionServer列表
- Hadoop安全模式
```
$HADOOP_HOME/bin/hdfs dfsadmin -safemode get
$HADOOP_HOME/bin/hdfs dfsadmin -safemode leave
```
- 与Hadoop版本不兼容
```
# vi $HBASE_HOME/logs/hbase-root-master-node101.log
java.lang.IllegalArgumentException: object is not an instance of declaring class
# 替换slf4j-*.jar
# vi hbase-env.sh
export HBASE_CLASSPATH=$HADOOP_HOME/etc/hadoop/
export HBASE_DISABLE_HADOOP_CLASSPATH_LOOKUP="true"
```

## 参考
- [HBase HA （完全分布式）高可用集群的搭建](https://blog.csdn.net/weixin_43311978/article/details/106181687)
