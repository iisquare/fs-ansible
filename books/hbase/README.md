# playbook for hbase

## 使用说明
- 安装
```
ansible-playbook -i hosts --tags install books/hbase/hbase.yaml
```
- 配置
```
ansible-playbook -i hosts --tags config books/hbase/hbase.yaml
```
- 管理
```
cd /opt/hbase-2.4.12
./bin/start-hbase.sh
./bin/stop-hbase.sh
```

### 服务地址
- Web UI hbase.master.info.port:16010

## 参考
- [HBase HA （完全分布式）高可用集群的搭建](https://blog.csdn.net/weixin_43311978/article/details/106181687)
