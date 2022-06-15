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
- 手动启动
```
/opt/hbase-2.4.12/bin/hbase-daemon.sh start master 
/opt/hbase-2.4.12/bin/hbase-daemon.sh start regionserver 
/opt/hbase-2.4.12/bin/hbase-daemon.sh start master --backup
/opt/hbase-2.4.12/bin/hbase-daemon.sh stop master
/opt/hbase-2.4.12/bin/hbase-daemon.sh stop regionserver
```
- 管理
```
/opt/hbase-2.4.12/bin/start-hbase.sh
/opt/hbase-2.4.12/bin/stop-hbase.sh
```

### 重置
- 强制停止
```
jps|grep "HMaster\|HRegionServer"|awk '{print $1}'|xargs kill -s TERM
```
- 清理HDFS配置
```
/opt/hadoop-3.3.2/bin/hdfs dfs -ls /
/opt/hadoop-3.3.2/bin/hdfs dfs -rm -r /hbase
```
- 清理Zookeeper配置
```
deleteall /hbase
```


### 服务地址
- Web UI hbase.master.info.port:16010

## 参考
- [HBase HA （完全分布式）高可用集群的搭建](https://blog.csdn.net/weixin_43311978/article/details/106181687)
