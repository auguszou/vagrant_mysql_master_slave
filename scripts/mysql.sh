debconf-set-selections <<< 'mysql-server-5.7 mysql-server/root_password password 123'
debconf-set-selections <<< 'mysql-server-5.7 mysql-server/root_password_again password 123'
apt-get install -yy mysql-server-5.7
