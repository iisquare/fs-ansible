# playbook for presto

## 使用说明

### 安装配置
- 安装
```
ansible-playbook -i hosts --tags install books/presto/presto.yaml
```
- 配置
```
ansible-playbook -i hosts --tags config books/presto/presto.yaml
```
- 数据源
```
ansible-playbook -i hosts --tags sync books/presto/presto.yaml
```
- 清空
```
ansible-playbook -i hosts --tags clear books/presto/presto.yaml
```
- 客户端
```
ansible-playbook -i hosts --tags cli books/presto/presto.yaml
```
- 管理
```
/opt/presto-server-0.273/bin/launcher start
# 前台运行
/opt/presto-server-0.273/bin/launcher run
/opt/presto-server-0.273/bin/launcher stop
/opt/presto-server-0.273/bin/launcher restart
/opt/presto-server-0.273/bin/launcher status
```
- 使用
```
/opt/presto-server-0.273/presto-cli --help
/opt/presto-server-0.273/presto-cli --server http://node101:8000
```

### 服务地址
- http-server.http.port:8000

### 常用命令
- 帮助
```
help;
```
- 数据源
```
show catalogs;
use mysql.default;
show schemas;
show tables;
```

## 参考
- [Presto安装部署详细说明](https://blog.csdn.net/jsbylibo/article/details/107821214)
