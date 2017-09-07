# Sistemas Distribuidos, Taller 1
# Universidad Icesi


## Esteban Moya-A00068020

# Comandos de linux necesarios para el aprovisionamiento de los servicios solicitados.

## Balanceador de carga

Se ha escogido Nginx como balanceador de carga ya que es un servicio web ligero, de alto rendimiento y multi plataforma. Nginx posee la arquitectura para actuar como balanceador de carga, permitiendo que las peticiones puedan ser atendidas en diferentes servidores. Los comandos necesarios para su instalación son los siguientes:

Inicialmente se debe agregar el repositorio en el cual se encuentra Nginx para centos:

Se agregan las siguientes líneas de código en la ruta /etc/yum.repos.d/nginx.repo

```bash
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=0
enabled=1
```

Después de haber agregado los repositorios necesarios se deben ejecutar las siguientes líneas:

```bash
yum update
yum -y install nginx
systemctl stop firewalld
systemctl mask firewalld
yum -y install iptables-services
systemctl enable iptables
service network restart
```
Adicionalmente, es necesario hacer referencia a los servidores web en los cuales se van a distribuir las cargas. Para ello se debe modificar el archivo ubicado en:
`/etc/nginx/nginx.conf`
Quedando de la siguiente manera:

```
worker_processes  1;
events {
   worker_connections 1024;
}

http {
    upstream servers {
         server 192.168.133.10;
         server 192.168.133.11;
    }

    server {
        listen 8080;
        location / {
              proxy_pass http://servers;
        }
    }
}
```
## WEB-SERVER 1 Y 2
Los comandos necesarios para configurar los web-server fueron los siguientes:

```bash
yum -y install httpd
yum -y install php
yum -y install php-mysql
yum -y install http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
yum -y install mysql-community-server
systemctl stop firewalld
systemctl mask firewalld
yum -y install iptables-services
systemctl enable iptables
service network restart
iptables -I INPUT  -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
service iptables save
setsebool -P httpd_can_network_connect=1
```
## DATABASE
Los comandos necesarios para configurar el servidor de base de datos son los siguientes:

```bash

yum -y install http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
yum -y install mysql-community-server
systemctl stop firewalld
systemctl mask firewalld
yum -y install iptables-services
systemctl enable iptables
service network restart
iptables -I INPUT 5 -p tcp -m state --state NEW -m tcp --dport 3306 -j ACCEPT
service iptables save

```
## Creación de la base de datos y tablas

```sql

cat create_schema.sql | mysql -u root -pdistribuidos
mysql -u root -pdistribuidos
CREATE database database1;
USE database1;
CREATE TABLE example(
id INT NOT NULL AUTO_INCREMENT,
PRIMARY KEY(id),
 name VARCHAR(30),
 age INT);
INSERT INTO example (name,age) VALUES ('flanders',25);
-- http://www.linuxhomenetworking.com/wiki/index.php/Quick_HOWTO_:_Ch34_:_Basic_MySQL_Configuration
GRANT ALL PRIVILEGES ON *.* to 'icesi'@'192.168.133.10' IDENTIFIED by '12345';

GRANT ALL PRIVILEGES ON *.* to 'icesi'@'192.168.133.11' IDENTIFIED by '12345';

```

## VAGRANTFILE

```bash
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.ssh.insert_key = false
  config.vbguest.auto_update = false
  config.vm.define :wb_server do |wb| #CONFIGURACION DEL WEB SERVER 1
    wb.vm.box = "centos1706_v0.2.0"
    wb.vm.network "private_network", ip: "192.168.133.10" #LE HE CONFIGURADO SOLAMENTE UNA IP PRIVADA CON EL OBJETIVO DE QUE SOLAMENTE EL BALANCEADOR SEA CAPAZ DE ACCEDER AL WEB SERVER.
    wb.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "1024","--cpus", "1", "--name", "centos_server_web1" ]
    end

    #ADICION DE COOKBOOKS
   wb.vm.provision :chef_solo do |chef|
    chef.install = false
    chef.cookbooks_path = "cookbooks"
    chef.add_recipe "httpd"
  end
end
config.vm.define :wb_server2 do |wb2|  #CONFIGURACIÓN DEL WEB SERVER 2
  wb2.vm.box = "centos1706_v0.2.0"
  wb2.vm.network "private_network", ip: "192.168.133.11" #COMO EN EL ANTERIOR WEB SERVER EL UNICO QUE TENDRA ACCESO SERA EL BALANCEADOR. POR ESO NO LE ASIGNE IP PUBLICA
  wb2.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "1024","--cpus", "1", "--name", "centos_server_web2" ]
  end
 #ADICIÓN DE COOKBOOKS
 wb2.vm.provision :chef_solo do |chef|
  chef.install = false
  chef.cookbooks_path = "cookbooks"
  chef.add_recipe "httpd2"
end
end

  config.vm.define :db_server do |db| #APROVISIONAMIENTO DE LA BD
    db.vm.box = "centos1706_v0.2.0"
    db.vm.network "private_network", ip: "192.168.133.12" #LOS ÚNICOS QUE TIENEN ACCESO A LA BD SON LOS WB_SERVERS
    db.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "1024","--cpus", "1", "--name", "centos_client" ]
    end
    #ADICIÓN DE COOKBOOKS
    db.vm.provision :chef_solo do |chef|
    chef.install = true
    chef.cookbooks_path = "cookbooks"
    chef.add_recipe "mysql"
  end
end
config.vm.define :balanceador do |balanceador| #APROVISIONAMIENTO DEL BALANCEADOR
  balanceador.vm.box = "centos1706_v0.2.0"
  balanceador.vm.network "private_network", ip: "192.168.133.13"
  balanceador.vm.network "public_network", bridge:  "eno1", ip:"192.168.0.28" #ESTA FUE LA ÚNICA MAQUINA A LA QUE LE ASIGNÉ UNA IP PUBLICA, CON EL OBJETIVO DE QUE LOS USUARIOS ACCEDAN SOLO AL BALANCEADOR.
  balanceador.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", "1024","--cpus", "1", "--name", "centos_balanceador" ]
  end
  #ADICIÓN DE COOKBOOKS
  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = "cookbooks"
    chef.add_recipe "balanceador"
  end
end
end

```
## COOKBOOKS

| Directorio     | Descripción     |
| ------------- | ------------- |
| cookbooks/balanceador/| Contiene los archivos y las instrucciones que se desean automatizar para la implementacion del balanceador de carga. Las carpetas principales que contiene este directorio son los recipes y los templates. En el primero se encuentra todas las lineas que se quieren automatizar y las que permiten agregar los archivos de la carpeta templates. |
| cookbooks/httpd/ | Contiene los archivos e instrucciones que se desean automatizar para el buen funcionamiento del servidor web. En la carpeta files de esta ruta, podemos encontrar los archivos .html y .php necesarios para la implementacion del servidor web. |
| cookbooks/httpd2/ | Lo mismo que la descripción anterior pero para el web_server 2 |
| cookbooks/mysql/ | Contiene los archivos e instrucciones que se desean automatizar para una correcta configuración del servidor de base de datos. En la carpteta files de esta ruta se encuentra los archivos necesarios para la creación de los schemas de la bd |

## Evidencia del buen funcionamiento del sistema:

![Evidencia](https://j.gifs.com/y81Jxg.gif)
