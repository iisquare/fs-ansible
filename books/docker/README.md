# playbook for docker

## 使用说明

### 安装配置
- 安装依赖
```
ansible-playbook -i hosts --tags dependencies books/docker/docker.yaml
```
- 安装源
```
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum list docker-ce --showduplicates | sort -r
```
- 安装
```
ansible-playbook -i hosts --tags install books/docker/docker.yaml
```
- 配置
```
ansible-playbook -i hosts --tags config books/docker/docker.yaml
```
- 安装DockerCompose
```
ansible-playbook -i hosts --tags compose books/docker/docker.yaml
```

### Docker Compose
- 配置
```
ansible-playbook -i hosts --tags config books/docker/compose.yaml
```
- 同步
```
ansible-playbook -i hosts --tags sync books/docker/compose.yaml
```
- 全量
```
ansible-playbook -i hosts --tags config,sync books/docker/compose.yaml
```
