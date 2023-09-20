# playbook for flink

## 使用说明

### 安装配置
- 安装
```
ansible-playbook -i hosts --tags install books/flink/flink.yaml
```
- 配置
```
ansible-playbook -i hosts --tags config books/flink/flink.yaml
```
- 服务管理
```
# 启动Session on Yarn
$FLINK_HOME/bin/yarn-session.sh -d
```
- 历史服务（History Server）
```
$FLINK_HOME/bin/historyserver.sh start
$FLINK_HOME/bin/historyserver.sh stop
```
- 任务管理
```
$FLINK_HOME/bin/flink -h
```

### 服务地址
- historyserver.web.port: 8082

### 常见问题

- 找不到Yarn相关类

[Apache Hadoop YARN Preparation](https://nightlies.apache.org/flink/flink-docs-release-1.14/docs/deployment/resource-providers/yarn/)
```
export HADOOP_CLASSPATH=`hadoop classpath`
```


## 最佳实践

### 内存配置
```
在flink-conf.yaml配置文件中：
在SessionOnYarn模式中，每个Session会启动一个JobManager和多个TaskManager，一个TaskManager对应Yarn中一个Container。
通过taskmanager.memory.process.size可以限制TaskManager/Container申请的内存大小。
一个TaskManager默认包含一个Slot插槽，通过taskmanager.numberOfTaskSlots可以修改Slot数量；
同一个TaskManager下的每个Slot将获得taskmanager.memory.process.size/taskmanager.numberOfTaskSlots的内存分配；
通过taskmanager.memory.flink.size可限制单个Slot中的Flink任务的内存。
在yarn-session.sh命令参数中：
通过-tm/--taskManagerMemory可指定每个TaskManager的内存分配大小。
通过-s/--slots可指定每个TaskManager中的插槽数量。
在flink run命令参数中：
通过-ytm/--yarnsessiontaskmanagermemory指定每个TaskManager的内存大小。
通过-ys/--yarnslot指定每个TaskManager的插槽数量。
```


## 参考
- [Apache Flink Documentation](https://nightlies.apache.org/flink/flink-docs-release-1.14/)
