# ansible
ansible shell

## 使用说明

### 授权
- SSH密钥
```
ssh-keygen -t rsa -b 2048 -N '' -f ~/.ssh/id_rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub <user>@<ip-host>
```
- 修改配置
```
vi /etc/ansible/ansible.cfg 
host_key_checking = False
```
- 批量授权
```
ansible <host-pattern> -m authorized_key -a "user=root key='{{ lookup('file','/root/.ssh/id_rsa.pub')}}' path='/root/.ssh/authorized_keys' manage_dir=no exclusive=no state=<present,absent>" --ask-pass -c paramiko
```

### 基础
- 常用模块
```
ansible 127.0.0.1 -m debug -a "msg='{{ a }}'" --extra-vars "a=1 b=2" # KV
ansible 127.0.0.1 -m debug -a "msg='{{ a }}'" --extra-vars '{a: 1}' # JSON
ansible -i hosts clickhouse -m debug -a "msg='{{ fs_cluster }}'"
ansible -i <inventory> --connection=<local,ssh> <host-pattern> -m ping
ansible <host-pattern> -m ping
ansible -i hosts all -m command -a "xxx"
ansible -i hosts all -m shell -a "xxx.sh >> xxx.log" chdir=<work_dir>
ansible <ip> -m raw -a 'hostname' # 不需要python环境
ansible <host-pattern> -m copy -a 'src=<file_path> dest=<file_path> owner=<user> group=<group> backup=yes'
ansible <host-pattern> -m fetch -a "src=<file_path> dest=<file_path> flat=yes" # 参数flat根据/后缀确定目录
ansible <host-pattern> -m file -a "path=<file_path> owner=<user> group=<group> state=<directory,link> mode=0644 recurse=yes"
ansible <host-pattern> -m service -a "name=<name> enabled=<yes,no> state=<stared,stoped,restarted,reloaded>"
```
- 检查测试
```
ansible-playbook --syntax-check xxx.yaml # 检测语法
ansible-playbook -C xxx.yaml # 测试运行
```
- 帮助文档
```
ansible-doc blockinfile
```

### 标签

特殊标签：always、never（2.5版本新加入）、tagged、untagged、all。
当tags的值为always时，那么这个任务就总是被执行，除非使用--skip-tags选项明确指定不执行对应的任务。

- 列举标签
```
ansible-playbook --list-tags xxx.yaml
```
- 只执行有标签的任务，没有任何标签的任务不会执行
```
ansible-playbook --tags tagged xxx.yaml
```
- 跳过包含标签的任务，即使拥有always标签也会跳过
```
ansible-playbook --skip-tags tagged xxx.yaml
```
- 只执行没有标签的任务，但拥有always标签的任务仍然会被执行
```
ansible-playbook --tags untagged xxx.yaml
```
- 跳过没有标签的任务
```
ansible-playbook --skip-tags untagged xxx.yaml
```

### 注意事项

- 分组下的变量，会相互覆盖，相同名称的值需保持一致

## 参考链接
- [Ansible中文权威指南](http://ansible.com.cn/)
- [Jinja2 中文手册](https://docs.pythontab.com/jinja/jinja2/)
