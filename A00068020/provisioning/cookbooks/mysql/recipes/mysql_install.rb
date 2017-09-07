bash 'restart network' do
code <<-EOH
 systemctl stop firewalld
 systemctl mask firewalld
 yum -y install iptables-services
 systemctl enable iptables
 service network restart
  EOH
end



bash 'add repo' do
  user 'root'
  code <<-EOH
  yum -y install http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
  yum -y install mysql-community-server
  EOH
end


service 'mysqld' do
    action [ :enable, :start ]
end

bash 'open port' do
	user 'root'
	code <<-EOH
	iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 3306 -j ACCEPT
	service iptables save
	EOH
end

yum_package 'expect' do
 action :install
end

cookbook_file '/tmp/configure_mysql.sh' do
	source 'configure_mysql.sh'
	mode 0711
	owner 'root'
	group 'wheel'
end

bash 'configure mysql' do
 user 'root'
 group 'wheel'
 cwd '/tmp'
 code <<-EOH
 ./configure_mysql.sh
 EOH
end

cookbook_file '/tmp/create_schema.sql' do
	source 'create_schema.sql'
	mode 0644
	owner 'root'
	group 'wheel'
end

bash 'create schema' do
	user 'root'
	cwd '/tmp'
	code <<-EOH
	cat create_schema.sql | mysql -u root -pdistribuidos
	EOH
end
