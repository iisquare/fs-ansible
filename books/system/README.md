# playbook for system

## 使用说明

### 环境准备
- 批量授权
```
ansible-playbook -i hosts --tags ssh books/system/centos.yaml --ask-pass -c paramiko
```
- 修改主机名
```
ansible-playbook -i hosts --tags hostname books/system/centos.yaml
```
