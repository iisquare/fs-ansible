# Special Test Case

特殊业务场景测试，不建议在生产环境使用。

## 无明确分区字段

### 数据准备

- 表结构
```
-- 无分区
CREATE TABLE `dwd_demo` (
  `aid` String,
  `bid` String,
  `name` String,
  `time` String,
  `_sign` Int8,
  `_version` UInt64
)
ENGINE = ReplacingMergeTree(_version)
ORDER BY aid;

-- 多分区
CREATE TABLE `dwd_demo_pt` (
  `aid` String,
  `bid` String,
  `name` String,
  `time` String,
  `_sign` Int8,
  `_version` UInt64
)
ENGINE = ReplacingMergeTree(_version)
PARTITION BY sipHash64(bid) % 30
ORDER BY aid;
```
- 数据导入
```
约2千万
```

### 测试用例

- 统计查询
```
-- 平均耗时：0.002s
select count(*) from dwd_demo;
-- 平均耗时：0.002s
select count(*) from dwd_demo_pt;
-- 平均耗时：0.7s
select count(*) from dwd_demo final;
-- 平均耗时：1.4s
select count(*) from dwd_demo_pt final;
```

- 多值查询
```
-- 平均耗时：4s
select * from dwd_demo final where bid in ('x1', 'x2', 'x3', 'x4', 'x5') and _sign = 1 order by time limit 6;
-- 平均耗时：5.7s
select * from dwd_demo_pt final where bid in ('x1', 'x2', 'x3', 'x4', 'x5') and _sign = 1 order by time limit 6;
```

- 等值查询
```
-- 平均耗时：4s
select * from dwd_demo final where bid = 'x1' and _sign = 1 order by time limit 6;
-- 平均耗时：0.15s
select * from dwd_demo_pt final where bid = 'x1' and _sign = 1 order by time limit 6;
```

- 单值IN查询
```
-- 平均耗时：4s
select * from dwd_demo final where bid in ('x1') and _sign = 1 order by time limit 6;
-- 平均耗时：5.7s
select * from dwd_demo_pt final where bid in ('x1') and _sign = 1 order by time limit 6;
```

### 结论

- 对非排序字段进行分区，等值查询速度提升较大，IN查询比单个分区更慢。
- 相较于Doris同类测试，ClickHouse更适合在有明确排序字段查询的场景。
