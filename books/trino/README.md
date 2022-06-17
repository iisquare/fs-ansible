# playbook for trino

PrestoSQL is now Trino由创始人和社区维护，PrestoDB主要由Facebook员工维护。

## 使用说明

### 安装配置
- 安装
```
ansible-playbook -i hosts --tags install books/trino/trino.yaml
```
- 独立JDK11
```
ansible-playbook -i hosts --tags jdk books/trino/trino.yaml
```
- 配置
```
ansible-playbook -i hosts --tags config books/trino/trino.yaml
```
- 数据源
```
ansible-playbook -i hosts --tags sync books/trino/trino.yaml
```
- 清空
```
ansible-playbook -i hosts --tags clear books/trino/trino.yaml
```
- 客户端
```
ansible-playbook -i hosts --tags cli books/trino/trino.yaml
```
- 管理
```
/opt/trino-server-386/bin/launcher start
# 前台运行
/opt/trino-server-386/bin/launcher run
/opt/trino-server-386/bin/launcher stop
/opt/trino-server-386/bin/launcher restart
/opt/trino-server-386/bin/launcher status
```
- 使用
```
/opt/trino-server-386/trino-cli --help
/opt/trino-server-386/trino-cli --server http://node101:8000
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

### Superset集成
- 驱动
```
pip install sqlalchemy-trino
```
- 连接
```
trino://{username}:{password}@{hostname}:{port}/{catalog}
trino://admin@node101:8000/phoenix
```


## 参考
- [Trino documentation](https://trino.io/docs/current/index.html)
- [Presto安装部署详细说明](https://blog.csdn.net/jsbylibo/article/details/107821214)
