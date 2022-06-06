# playbook for hadoop

## 使用说明

### 环境准备
- 免密互信
```
ansible-playbook -i hosts --tags ssh-keygen books/hadoop/env.yaml
ansible-playbook -i hosts --tags ssh-copy-id books/hadoop/env.yaml
```
