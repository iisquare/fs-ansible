# 本地测试

## VMware

### 创建虚拟机

- 通过CentOS-7-x86_64-Minimal-2009.iso安装最小化系统。
- 网络连接方式为NAT桥接，默认禁用网卡自启动。
- 通过完整拷贝复制出多个测试节点，修改网卡信息并设置为自启动。
```
cat /etc/sysconfig/network-scripts/ifcfg-ens<number>
NAME=ens<number>
UUID=xxxxxxxx-xxxx-xxxx-a<number>-xxxxxxxxxxxx
DEVICE=ens<number>
ONBOOT=yes
```
- 修改宿主机hosts文件，节点会共享宿主机DNS解析。
```
C:\Windows\System32\drivers\etc\hosts
<ip> node<number>
```
