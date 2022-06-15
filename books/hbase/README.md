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

### 服务地址
- hbase.master:60000

## 参考
- [HBase HA （完全分布式）高可用集群的搭建](https://blog.csdn.net/weixin_43311978/article/details/106181687)
