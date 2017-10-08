# sed -i 's/^server-id.*$/server-id = 1/g' /etc/my.cnf
# sed -i 's/^log-bin.*$/log-bin = mysql-bin/g' /etc/my.cnf
# sed -i 's/^innodb_flush_log_at_trx_commit.*$/innodb_flush_log_at_trx_commitl = 1/g' /etc/my.cnf
# sed -i 's/^sync_binlog.*$/sync_binlog = 1/g' /etc/my.cnf
# sed -i 's/^binlog-do-db.*$/binlog-do-db = test/g' /etc/my.cnf
# sed -i 's/^binlog-ingore-db.*$/binlog-ignore-db = mysql/g' /etc/my.cnf
# sed -i 's/^binlog-ingore-db.*$/binlog-ignore-db = information_schema/g' /etc/my.cnf
cat >> /etc/mysql/mysql.conf.d/mysqld.cnf <<EOF
server-id=1
binlog-do-db=test
binlog-ignore-db=information_schema
binlog-ignore-db=mysql

slow_query_log=1
slow_query_log_file=/var/lib/mysql/mysql-slow.log

sync_binlog=1
log-bin=/var/lib/mysql/mysql-bin
EOF

#variables for master
export master_ip="192.168.1.10"
export master_mysql_root_passwd="123"
export replication_user="copydb"
export replication_passwd="123"
export replication_db="test"

#variables for slave
export slave_ssh_login_user="vagrant"
export slave_ssh_login_passwd="vagrant"
export slave_mysql_root_passwd="123"

mysql -uroot -p${master_mysql_root_passwd} -e 'drop database if exists ${replication_db};create database ${replication_db};'

{
mysql -uroot -p${master_mysql_root_passwd} <<EOF
CREATE USER '$replication_user'@'%' IDENTIFIED BY '$replication_passwd';
GRANT REPLICATION SLAVE ON *.* TO '$replication_user'@'%' IDENTIFIED BY '$replication_passwd';
FLUSH TABLES WITH READ LOCK;
SELECT SLEEP(10);
EOF
} &

#export the database sql data.
mysqldump -uroot -p${master_mysql_root_passwd} ${replication_db} > /vagrant/${replication_db}.sql

/etc/init.d/mysql restart
