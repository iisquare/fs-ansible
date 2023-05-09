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

## 参考
- [Apache Flink Documentation](https://nightlies.apache.org/flink/flink-docs-release-1.14/)
