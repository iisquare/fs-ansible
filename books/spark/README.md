# playbook for spark

## 使用说明

### 安装配置
- 安装
```
ansible-playbook -i hosts --tags install books/spark/spark.yaml
```
- 配置
```
ansible-playbook -i hosts --tags config books/spark/spark.yaml
```
- 管理
```
# 只能启动执行节点的Master服务
/opt/spark-3.2.1-bin-hadoop3.2/sbin/start-all.sh
# 在其他节点上手动拉起Master服务
/opt/spark-3.2.1-bin-hadoop3.2/sbin/start-master.sh
/opt/spark-3.2.1-bin-hadoop3.2/sbin/stop-all.sh
```
- 历史服务（History Server）
```
# 创建目录
/opt/hadoop-3.3.2/bin/hdfs dfs -mkdir /spark-events
/opt/spark-3.2.1-bin-hadoop3.2/sbin/start-history-server.sh
/opt/spark-3.2.1-bin-hadoop3.2/sbin/stop-history-server.sh
```

### 服务地址
- SPARK_MASTER_WEBUI_PORT:8080
- spark.history.ui.port:18080


## 参考
- [Spark HA集群搭建](https://cloud.tencent.com/developer/article/1336634)
