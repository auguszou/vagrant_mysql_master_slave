#variables for master
export master_ip="192.168.1.10"
export master_ssh_login_user="vagrant"
export master_ssh_login_user="vagrant"

export master_mysql_root_passwd="123"
export replication_user="copydb"
export replication_passwd="123"
export replication_db="test"

#variables for slave
export slave_ip=`ifconfig enp0s8| grep "inet addr" | awk '{ print $2}' | awk -F: '{print $2}'`
export slave_server_id=${slave_ip##*.}
export slave_mysql_root_passwd="123"
export slave_ssh_login_user="vagrant"
export slave_ssh_login_passwd="vagrant"

cmd_ssh="sshpass -p ${master_ssh_login_passwd} ssh ${master_ssh_login_user}@${master_ip}"
cmd_status="${master_}${mysqlbinpath}/mysql -uroot -p${master_mysql_root_passwd} -e \"show master status\G\""
export status=`${cmd_ssh} -e '${cmd_status}'`

cmd_binlogname="echo \"$status\" | grep \"File\" | awk '{print $2}'"
export binlogname=`${cmd_ssh} -e '${cmd_binlogname}'`

cmd_postion="echo "$status" | grep "Position" | awk '{print $2}'"
export position=`${cmd_ssh} -e '${cmd_postion}'`

mysql -uroot -p${slave_mysql_root_passwd} -e 'drop database if exists ${replication_db};create database ${replication_db};'
mysql -uroot -p${slave_mysql_root_passwd} ${replication_db} < /vagrant/${replication_db}.sql

# sed -i 's/^server-id.*$/server-id = ${slave_server_id}/g' /etc/my.cnf
cat >> /etc/mysql/mysql.conf.d/mysqld.cnf <<EOF
server-id=${slave_server_id}
EOF

/etc/init.d/mysql restart

mysql -uroot -p${slave_mysql_root_passwd} <<EOF
STOP SLAVE;
CHANGE MASTER TO MASTER_HOST=\"${master_ip}\",
MASTER_USER=\"${replication_user}\",
MASTER_PASSWORD=\"${replication_passwd}\",
MASTER_PORT=3306,
MASTER_LOG_FILE=\"${binlogname}\",
MASTER_LOG_POS=${position},
MASTER_CONNECT_RETRY=10;
START SLAVE;
SELECT SLEEP(3);
SHOW SLAVE STATUS\G'"
EOF

