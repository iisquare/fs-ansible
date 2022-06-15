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
/opt/spark-3.2.1-bin-hadoop3.2/sbin/stop-all.sh
# 在其他节点上手动拉起Master服务
/opt/spark-3.2.1-bin-hadoop3.2/sbin/start-master.sh
/opt/spark-3.2.1-bin-hadoop3.2/sbin/stop-master.sh
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

## 开发测试

### 远程调用
- 备份原始Jar包
```
ansible-playbook -i hosts --tags backup books/spark/dev.yaml
```
- 拷贝本地Jar包
```
ansible-playbook -i hosts --tags copy books/spark/dev.yaml
```
- 同步本地Jar包
```
ansible-playbook -i hosts --tags sync books/spark/dev.yaml
```

### 常见问题

- 申请资源死循环

Driver端为本地代码，远程服务端Executor需要反向连接Driver进行通信，域名无法解析或链路不通导致通信失败。

- 类转换异常
```
java.lang.ClassCastException: cannot assign instance of java.lang.invoke.SerializedLambda to field org.apache.spark.rdd.MapPartitionsRDD.f of type scala.Function3 in instance of org.apache.spark.rdd.MapPartitionsRDD
```
将依赖上传至jars目录，仅将当前代码打包为瘦Jar，通过setJars参数作为第三方Jar附加到作业中。
```
SparkConf config = new SparkConf();
config.setAppName("remote-test");
config.setMaster("spark://m1:7077,m2:7077,m3:7077");
config.setJars(new String[]{ "http://path/to/app.jar" });
SparkSession session = SparkSession.builder().config(config).getOrCreate();
```


## 参考
- [Spark HA集群搭建](https://cloud.tencent.com/developer/article/1336634)
- [spark远程调用的几个坑](https://www.cnblogs.com/hanko/p/14086667.html)
