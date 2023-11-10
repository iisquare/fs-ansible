# playbook for hadoop

## 使用说明

### 环境准备
- 免密互信
```
ansible-playbook -i hosts --tags ssh-keygen books/hadoop/env.yaml
ansible-playbook -i hosts --tags ssh-copy-id books/hadoop/env.yaml
```

### 安装配置
- 安装
```
ansible-playbook -i hosts --tags install books/hadoop/hadoop.yaml
```
- 配置
```
ansible-playbook -i hosts --tags config books/hadoop/hadoop.yaml
```
- 初始化
```
# 所有节点启动journalnode
$HADOOP_HOME/bin/hdfs --daemon start journalnode

# 在nn1上格式化
$HADOOP_HOME/bin/hdfs namenode -format
$HADOOP_HOME/bin/hdfs zkfc -formatZK

# 在nn1上启动namenode
$HADOOP_HOME/bin/hdfs --daemon start namenode

# 在nn2和nn3上同步nn1的元数据信息
$HADOOP_HOME/bin/hdfs namenode -bootstrapStandby

# 在nn2和nn3上启动namenode
$HADOOP_HOME/bin/hdfs --daemon start namenode

# 所有节点启动数据节点
$HADOOP_HOME/bin/hdfs --daemon start datanode

# 检查状态
$HADOOP_HOME/bin/hdfs haadmin -getServiceState nn1
$HADOOP_HOME/bin/yarn rmadmin -getServiceState rm1

# 切换状态
$HADOOP_HOME/bin/hdfs haadmin -transitionToActive nn1
```
- 服务管理
```
$HADOOP_HOME/sbin/start-all.sh
$HADOOP_HOME/sbin/stop-all.sh
```
- 任务管理
```
$HADOOP_HOME/bin/hadoop job -h
$HADOOP_HOME/bin/yarn application -help
```
- 清理
```
rm -rf /data/hadoop/*
rm -rf /$HADOOP_HOME/logs/*
sudo docker-compose exec zookeeper zkCli.sh
deleteall /hadoop-ha
deleteall /yarn-leader-election
```

### 服务地址
- dfs.namenode.http-address:9870
- yarn.resourcemanager.webapp.address:8088

## 最佳实践

### 资源配置
```
在yarn-site.xml中：
通过yarn.nodemanager.resource.cpu-vcores配置单个节点可使用的虚拟CPU个数。
通过yarn.scheduler.minimum-allocation-vcores配置单个任务可申请的最小虚拟CPU个数。
通过yarn.scheduler.maximum-allocation-vcores配置单个任务可申请的最多虚拟CPU个数。
通过yarn.scheduler.minimum-allocation-mb配置单个任务/容器可申请的最小内存大小。
通过yarn.scheduler.maximum-allocation-mb配置单个任务/容器可申请的最大内存大小。
```

## 参考
- [Apache Hadoop Documentation](https://hadoop.apache.org/docs/r3.3.5/)
- [大数据hadoop3.1.3——Hadoop HA高可用学习笔记（安装与配置）](https://blog.csdn.net/qq_42502354/article/details/105980277)
