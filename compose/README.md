# Docker Compose

## 使用说明

### 安装配置

- 安装
```
ansible-playbook -i hosts --tags install compose/compose.yaml
```
- 配置
```
ansible-playbook -i hosts --tags init compose/compose.yaml
```
- 移除
```
ansible-playbook -i hosts --tags remove compose/compose.yaml
```

### 配置约定

- 环境变量.env文件独立配置，不受托管
- 编译脚本Dockerfile独立配置，不受托管
- 所需服务docker-compose.yml由各service下的剧本生成
