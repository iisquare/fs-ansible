# note for hbase

### 常用命令

- 查看状态
```
status
```
- 创建表
```
create 'table_name', 'column_famaly', 'column_famaly1', 'column_famaly2'
```
- 表列表
```
list
```
- 表描述
```
describe 'table_name'
```
- 删除列簇
```
alter'table_name', { NAME=>'column_famaly', METHOD=>'delete' }
```
- 删除表
```
exists 'table_name'
is_enabled 'table_name'
disable 'table_name'
drop 'table_name'
```
- 写入数据
```
put 'table_name', 'rowkey', 'column_famaly:column_name', 'value'
```
- 获取数据
```
get 'table_name', 'rowkey'
scan 'table_name', {'LIMIT' => 10}
```
- 删除列
```
delete 'table_name', 'rowkey', 'column_famaly:column_name'
```
- 删除行
```
deleteall 'table_name', 'rowkey'
```
- 统计
```
count 'table_name'
```
- 清空
```
truncate'table_name'
```
- 命名空间
```
help "namespace"
```
