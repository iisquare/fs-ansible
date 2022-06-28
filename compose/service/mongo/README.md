# mongo

## 使用说明

### 安装配置

- 创建keyfile认证文件
```
openssl rand -base64 756 > ./compose/service/mongo/etc/keyfile
```
- 手动移除登录认证部分的配置
```
# security:
#  authorization: enabled
#  clusterAuthMode: keyFile
#  keyFile: /etc/mongo/keyfile
```

- 初始化
```
ansible-playbook -i hosts --tags init compose/service/mongo/mongo.yaml
```
- 同步配置
```
ansible-playbook -i hosts --tags config compose/service/mongo/mongo.yaml
```
- 同步镜像
```
./sbin/docker-archive.sh -i mongo -v 4.4.5 -u root -h node101,node102,node103
```

- 初始化配置服务
```
ansible-playbook -i hosts --tags init compose/service/mongo/configsvr.yaml
docker-compose up -d mongo-configsvr
netstat -anltp
# Connect a mongo shell to one of the config server members.
docker-compose exec mongo-configsvr mongo --host 127.0.0.1 --port 27019
rs.initiate(
  {
    _id: "fsConfig",
    configsvr: true,
    members: [
      { _id : 0, host : "node101:27019" },
      { _id : 1, host : "node102:27019" },
      { _id : 2, host : "node103:27019" }
    ]
  }
)
rs.status()
```

- 初始化数据分片服务1
```
ansible-playbook -i hosts --tags init compose/service/mongo/shardsvr1.yaml
docker-compose up -d mongo-shardsvr1
netstat -anltp
# Connect a mongo shell to one of the config server members.
docker-compose exec mongo-shardsvr1 mongo --host 127.0.0.1 --port 27011
rs.initiate(
  {
    _id: "fsShard1",
    members: [
      { _id : 0, host : "node101:27011", priority: 2 },
      { _id : 1, host : "node102:27011", priority: 1 },
      { _id : 2, host : "node103:27011", priority: 1 }
    ]
  }
)
rs.status()
```

- 初始化数据分片服务2
```
ansible-playbook -i hosts --tags init compose/service/mongo/shardsvr2.yaml
docker-compose up -d mongo-shardsvr2
netstat -anltp
# Connect a mongo shell to one of the config server members.
docker-compose exec mongo-shardsvr2 mongo --host 127.0.0.1 --port 27012
rs.initiate(
  {
    _id: "fsShard2",
    members: [
      { _id : 0, host : "node101:27012", priority: 1 },
      { _id : 1, host : "node102:27012", priority: 2 },
      { _id : 2, host : "node103:27012", priority: 1 }
    ]
  }
)
rs.status()
```

- 初始化数据分片服务3
```
ansible-playbook -i hosts --tags init compose/service/mongo/shardsvr3.yaml
docker-compose up -d mongo-shardsvr3
netstat -anltp
# Connect a mongo shell to one of the config server members.
docker-compose exec mongo-shardsvr3 mongo --host 127.0.0.1 --port 27013
rs.initiate(
  {
    _id: "fsShard3",
    members: [
      { _id : 0, host : "node101:27013", priority: 1 },
      { _id : 1, host : "node102:27013", priority: 1 },
      { _id : 2, host : "node103:27013", priority: 2 }
    ]
  }
)
rs.status()
```

- 初始化查询路由服务
```
ansible-playbook -i hosts --tags init compose/service/mongo/mongos.yaml
docker-compose up -d mongo-mongos
netstat -anltp
# Connect a mongo shell to one of the config server members.
docker-compose exec mongo-mongos mongo --host 127.0.0.1 --port 27017
sh.addShard( "fsShard1/node101:27011,node102:27011,node103:27011")
sh.addShard( "fsShard2/node101:27012,node102:27012,node103:27012")
sh.addShard( "fsShard3/node101:27013,node102:27013,node103:27013")
sh.status()
```

- 重置清理
```
docker-compose stop mongo-mongos
docker-compose rm -f mongo-mongos
docker-compose build mongo-mongos

docker-compose stop mongo-configsvr
docker-compose rm -f mongo-configsvr
docker-compose build mongo-configsvr

docker-compose stop mongo-shardsvr1
docker-compose rm -f mongo-shardsvr1
docker-compose build mongo-shardsvr1

docker-compose stop mongo-shardsvr2
docker-compose rm -f mongo-shardsvr2
docker-compose build mongo-shardsvr2

docker-compose stop mongo-shardsvr3
docker-compose rm -f mongo-shardsvr3
docker-compose build mongo-shardsvr3

rm -rf /data/mongo/
```

### 路由测试

- 连接至查询路由mongos服务
```
docker-compose exec mongo-mongos mongo --host 127.0.0.1 --port 27017
```
- 创建数据库
```
use fs_test
```
- 为数据库启用分片
```
sh.enableSharding("fs_test")
```
- 为集合设置分片规则
```
sh.shardCollection("fs_test.tdata", { "_id": "hashed" })
```
- 数据验证
```
use fs_test
for (i = 1; i <= 1000; i++) {
    db.getCollection("tdata").insert({'price': 1})
}
```
- 查询总数
```
db.getCollection("tdata").count()
```
- 查询单个分片的数量（主节点）
```
docker-compose exec mongo-mongos mongo --host node101 --port 27011
use fs_test
db.getCollection("tdata").count()
```

### 登录认证
- 创建管理用户，每个分片副本集的主节点和路由服务的任意节点
```
docker-compose exec mongo-mongos mongo --host node101 --port 27011
docker-compose exec mongo-mongos mongo --host node102 --port 27012
docker-compose exec mongo-mongos mongo --host node103 --port 27013
docker-compose exec mongo-mongos mongo --host 127.0.0.1 --port 27017
use admin
db.createUser({
  user: "root",
  pwd: 'admin888',
  roles: [ { role: "userAdminAnyDatabase", db: "admin" }, "readWriteAnyDatabase" ]
})
db.grantRolesToUser("root", ["clusterAdmin"])
```
- 修改configsvr和shardsvr配置
```
security:
  authorization: enabled
  keyFile: /etc/mongo/keyfile
```
- 修改mongos配置
```
security:
  keyFile: /etc/mongo/keyfile
```
- 重启集群
```
docker-compose restart mongo-mongos
docker-compose restart mongo-configsvr
docker-compose restart mongo-shardsvr1
docker-compose restart mongo-shardsvr2
docker-compose restart mongo-shardsvr3
```
- 登录测试
```
use admin
db.auth("root", "admin888")
```


## 最佳实践

### 切换主节点

- 若各节点的priority优先级一致，则默认执行rs.initiate(...)初始化的节点为主节点
```
rs.initiate(
  {
    _id: "fsShard",
    members: [
      { _id : 0, host : "node101:27018", priority: 2 },
      { _id : 1, host : "node102:27018", priority: 1 },
      { _id : 2, host : "node103:27018", arbiterOnly: true } # 该节点仅用于选举
    ]
  }
)
```
- 配置优先级
```
rs.config()
config = rs.config()
config.members[1].priority = 3
rs.reconfig(config)
rs.status()
```
- 手动降级
```
rs.stepDown()
```

## 常见问题

### 认证文件异常
```
Read security file failed, error opening file bad file
Read security file failed, permissions on are too open
```
使用docker启动mongodb后，使用的用户是systemd-coredump，也就是999
```
RUN chmod 400 /etc/mongo/keyfile
RUN chown 999 /etc/mongo/keyfile
```

## 参考

- [高可用的MongoDB集群](https://www.jianshu.com/p/2825a66d6aed)
- [MongoDB部署分片集群](https://blog.csdn.net/networken/article/details/115409367)
- [MongoDB分片集群搭建及扩容](https://blog.csdn.net/GongMeiyan/article/details/106030112)
- [Deploy a Sharded Cluster](https://www.mongodb.com/docs/v4.4/tutorial/deploy-shard-cluster/)
