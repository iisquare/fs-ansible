# note for phoenix

### 常用命令

- 查看表
```
!table
```
- 查看表结构
```
!desc <table-name>
```
- 测试表
```
DROP TABLE TIME_TEST;
CREATE TABLE TIME_TEST (
  A VARCHAR,
  XN BIGINT,
  XD TIMESTAMP,
  XS VARCHAR,
  NN BIGINT,
  ND TIMESTAMP,
  NS VARCHAR
  CONSTRAINT TIME_TEST_PK PRIMARY KEY (A)
) DEFAULT_COLUMN_FAMILY='SVC';
create index if not exists  TIME_TEST_INDEX_XN on TIME_TEST (XN);
create index if not exists  TIME_TEST_INDEX_XD on TIME_TEST (XD);
create index if not exists  TIME_TEST_INDEX_XS on TIME_TEST (XS);
drop index TIME_TEST_INDEX_NN on TIME_TEST;
drop index TIME_TEST_INDEX_ND on TIME_TEST;
drop index TIME_TEST_INDEX_NS on TIME_TEST;
```
- 查询测试
```
select * from TIME_TEST where XN > 1655819280000 and XN < 1655819290000 limit 10;
select * from TIME_TEST where XD > TO_TIMESTAMP('2022-06-21 21:48:00.000') and XD < TO_TIMESTAMP('2022-06-21 21:48:10.000') limit 10;
select * from TIME_TEST where XS > '2022-06-21 21:48:00' and XS < '2022-06-21 21:48:10' limit 10;
```
