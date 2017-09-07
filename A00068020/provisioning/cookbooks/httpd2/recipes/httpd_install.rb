yum_package 'httpd'

yum_package 'php' do
    action :install
end

yum_package 'php-mysql' do
    action :install
end


bash 'add repo' do
  user 'root'
  code <<-EOH
  yum -y install http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
  yum -y install mysql-community-server
  setsebool -P httpd_can_network_connect=1
  EOH
end

bash 'restart network' do
code <<-EOH
 systemctl stop firewalld
 systemctl mask firewalld
 yum -y install iptables-services
 systemctl enable iptables
 service network restart

  EOH
end


bash 'open port' do
  code <<-EOH
  iptables -I INPUT  -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
  service iptables save
  EOH
end
