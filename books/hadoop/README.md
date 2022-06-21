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
/opt/hadoop-3.3.2/bin/hdfs --daemon start journalnode

# 在nn1上格式化
/opt/hadoop-3.3.2/bin/hdfs namenode -format
/opt/hadoop-3.3.2/bin/hdfs zkfc -formatZK

# 在nn1上启动namenode
/opt/hadoop-3.3.2/bin/hdfs --daemon start namenode

# 在nn2和nn3上同步nn1的元数据信息
/opt/hadoop-3.3.2/bin/hdfs namenode -bootstrapStandby

# 在nn2和nn3上启动namenode
/opt/hadoop-3.3.2/bin/hdfs --daemon start namenode

# 所有节点启动数据节点
/opt/hadoop-3.3.2/bin/hdfs --daemon start datanode

# 检查状态
/opt/hadoop-3.3.2/bin/hdfs haadmin -getServiceState nn1
/opt/hadoop-3.3.2/bin/yarn rmadmin -getServiceState rm1

# 切换状态
/opt/hadoop-3.3.2/bin/hdfs haadmin -transitionToActive nn1
```
- 管理
```
/opt/hadoop-3.3.2/sbin/start-all.sh
/opt/hadoop-3.3.2/sbin/stop-all.sh
```

### 服务地址
- dfs.namenode.http-address:9870
- yarn.resourcemanager.webapp.address:8088

## 参考
-[大数据hadoop3.1.3——Hadoop HA高可用学习笔记（安装与配置）](https://blog.csdn.net/qq_42502354/article/details/105980277)
