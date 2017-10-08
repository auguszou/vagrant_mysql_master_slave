mysql 主从备份
=========================

### test
1. vagrant up
2. login master, 执行sql
```
use test;
create table Person(id integer auto-increment, name varchar(256), primary key(id));
insert into Person(name) values("jack“),("tom");
```
3. login slave1, 执行sql
```
use test;
show tables;
select * from Person;
```

steps
=========================

### master
0. login master server

1. 修改mysqld.conf, 添加如下内容
```
server-id=1
binlog-do-db=test
binlog-ignore-db=information_schema
binlog-ignore-db=mysql

slow_query_log=1
sync_binlog=1
log-bin=mysql-bin
```

2. 创建数据库和复制用户
```sql
DROP DATABASE IF EXISTS ${replication_db};
CREATE DATABASE ${replication_db};

CREATE USER '$replication_user'@'%' IDENTIFIED BY '$replication_passwd';
GRANT REPLICATION SLAVE ON *.* TO '$replication_user'@'%' IDENTIFIED BY '$replication_passwd';
FLUSH PRIVILEGES;
FLUSH TABLES WITH READ LOCK;
SELECT SLEEP(10);
```

3. restart mysql `/etc/init.d/mysql restart`

4. 导出数据库 `mysqldump -uroot -p${master_mysql_root_passwd} ${replication_db} > /vagrant/${replication_db}.sql`

5. 获得master当前的binlogname(设为$binlogname)和position(设为$position)
```bash
mysql -uroot -p${master_mysql_root_passwd} -e 'show master status\G
```

### slave1
0. login slave1 server

1. 修改mysqld.conf, 添加如下内容
```
server-id=${slave_server_id}
replicate-do-db=test
replicate-ignore-db=mysql
replicate-ignore-db=information_schema
relay-log=mysqld-relay-bin
log-slave-updates
slave-skip-errors=all
slave-net-timeout=60

log-bin=mysql-bin
slow_query_log=1
```

2. 导入master的数据库
```bash
mysql -uroot -p${slave_mysql_root_passwd} -e "drop database if exists ${replication_db};create database ${replication_db};"
mysql -uroot -p${slave_mysql_root_passwd} ${replication_db} < /vagrant/${replication_db}.sql
```

3. restart mysql `/etc/init.d/mysql restart`

4. 设置主从关系
```sql
STOP SLAVE;
CHANGE MASTER TO MASTER_HOST="${master_ip}",
MASTER_PORT=3306,
MASTER_USER="${replication_user}",
MASTER_PASSWORD="${replication_passwd}",
MASTER_LOG_FILE="${binlogname}",
MASTER_LOG_POS=${position},
MASTER_CONNECT_RETRY=10;
START SLAVE;
```

5. 查看状态
```sql
show slave status\G;
```

### slave2
步骤同slave1
