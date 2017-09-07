CREATE database database1;
USE database1;
CREATE TABLE example(
id INT NOT NULL AUTO_INCREMENT,
PRIMARY KEY(id),
 name VARCHAR(30),
 age INT);
INSERT INTO example (name,age) VALUES ('flanders',25);
INSERT INTO example (name,age) VALUES ('Esteban Moya',21);
INSERT INTO example (name,age) VALUES ('Ingenieria Telemática',20172);
-- http://www.linuxhomenetworking.com/wiki/index.php/Quick_HOWTO_:_Ch34_:_Basic_MySQL_Configuration
GRANT ALL PRIVILEGES ON *.* to 'icesi'@'192.168.133.10' IDENTIFIED by '12345';
GRANT ALL PRIVILEGES ON *.* to 'icesi'@'192.168.133.11' IDENTIFIED by '12345';
