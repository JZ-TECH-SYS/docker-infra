CREATE DATABASE IF NOT EXISTS clickexpress;
CREATE DATABASE IF NOT EXISTS projeto2;
CREATE DATABASE IF NOT EXISTS projeto3;

-- Adicione outros databases conforme necessário

-- Garantir que o root possa conectar de qualquer host com mysql_native_password
ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'root';
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root';
FLUSH PRIVILEGES;
