# playbook for hive

## 使用说明

### 安装配置
- 安装
```
ansible-playbook -i hosts --tags install books/hive/hive.yaml
scp /path/to/mysql-connector-java-8.0.30.jar user@ip:/opt/apache-hive-3.1.3-bin/lib
```
- 配置
```
# config proxyuser at core-site.xml
ansible-playbook -i hosts --tags config books/hive/hive.yaml
```
- 兼容
```
ansible-playbook -i hosts --tags fixed books/hive/hive.yaml
```
- 初始化元数据
```
$HIVE_HOME/bin/schematool -dbType mysql -initSchema -verbose
```
- 启动
```
mkdir -pv $HIVE_HOME/logs
nohup $HIVE_HOME/bin/hive --service metastore > $HIVE_HOME/logs/metastore.log 2>&1 &
nohup $HIVE_HOME/bin/hive --service hiveserver2 > $HIVE_HOME/logs/hiveserver2.log 2>&1 &
```
- 停止
```
ps aux|grep hive|grep apache|awk '{print $2}'|xargs kill -s TERM
```
- 管理
```
# CliDriver
$HIVE_HOME/bin/hive
# BeeLine
$HIVE_HOME/bin/beeline -u jdbc:hive2://127.0.0.1:10000 -n root
# BeeLine通过ZK进行HA访问
$HIVE_HOME/bin/beeline -u 'jdbc:hive2://wsl:2181/;serviceDiscoveryMode=zooKeeper;zooKeeperNamespace=hiveserver2'
```

### 服务地址
- hive.metastore.port: 9083
- hive.server2.thrift.port: 10000
- hive.server2.webui.port: 10002

## 常见问题

### 名词释义
- MetaData：元数据包含用Hive创建的database、table等的信息，存储在关系型数据库中，如Derby、MySQL等。
- MetaStore：客户端通过thrift协议访问MetaStore服务，访问存储在关系型数据库中的元数据信息。
- HiveServer2（HS2）：一个服务端接口，远程客户端可使用jdbc、odbc、thrift方式连接Hive，执行查询并返回结果，支持多客户端并发和身份验证。
- HiveServer2用来提交查询访问数据，MetaStore用来访问元数据，本质上都是Thrift Service，虽然可以启动在同一个进程内，但更建议拆成不同的服务进程来启动。
- CliDriver（bin/hive）是SQL本地直接编译，然后访问MetaStore，提交作业，是重客户端，编写数据量大的业务脚本建议采用CliDriver方式。
- BeeLine（bin/beeline）是把SQL提交给HiveServer2，由HiveServer2编译，然后访问MetaStore，提交作业，是轻客户端。
- 通过hive.server2.enable.doAs参数启用Hiveserver2用户模拟功能（默认开启），否则使用启动用户访问Hadoop集群数据，依赖Hadoop提供的proxyuser功能。

## 参考
- [HIve安装配置（超详细）](https://blog.csdn.net/W_chuanqi/article/details/130242723)
- [Hive3.X高可用部署](https://blog.csdn.net/wangshui898/article/details/120608564)
- [Hive高可用部署 HiveServer2高可用（HA）Metastore高可用（HA）基于Apache hive 3.1.2](https://www.cnblogs.com/54along/p/14682271.html)
