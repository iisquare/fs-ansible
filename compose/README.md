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
