# Special Test Case

特殊业务场景测试，不建议在生产环境使用。

## 无明确分区字段

### 数据准备

- 表结构
```
-- 自动分桶
CREATE TABLE `dwd_demo` (
  `aid` varchar(1000) NOT NULL,
  `bid` varchar(1000) NOT NULL,
  `name` varchar(1000) NOT NULL,
  `time` varchar(1000) NOT NULL
)
UNIQUE KEY(`aid`, `bid`)
DISTRIBUTED BY HASH(`bid`) BUCKETS AUTO;

-- 单个桶
CREATE TABLE `dwd_demo_b1` (
  `aid` varchar(1000) NOT NULL,
  `bid` varchar(1000) NOT NULL,
  `name` varchar(1000) NOT NULL
)
UNIQUE KEY(`aid`, `bid`)
DISTRIBUTED BY HASH(`bid`) BUCKETS 1;
```
- 数据导入
```
约2千万
```

### 测试用例

- 统计查询
```
-- 平均耗时：0.4s
select count(*) from dwd_demo;
-- 平均耗时：0.2s
select count(*) from dwd_demo_b1;
```

- 多值查询
```
-- 平均耗时：0.2s
select * from dwd_demo where bid in ('x1', 'x2', 'x3', 'x4', 'x5') order by time limit 6;
-- 平均耗时：1.5s
select * from dwd_demo_b1 where bid in ('x1', 'x2', 'x3', 'x4', 'x5') order by time limit 6;
```

- 等值查询
```
-- 平均耗时：0.03s
select * from dwd_demo where bid = 'x1' order by time limit 6;
-- 平均耗时：0.15s
select * from dwd_demo_b1 where bid = 'x1' order by time limit 6;
```

- 单值IN查询
```
-- 平均耗时：0.03s
select * from dwd_demo where bid in ('x1') order by time limit 6;
-- 平均耗时：0.15s
select * from dwd_demo_b1 where bid in ('x1') order by time limit 6;
```

### 结论

- 非UNIQUE字段进行分桶，统计查询效率降低，等值或IN查询效率明显提升。
