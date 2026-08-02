-- Bootstrap do Conecta ERP no PostgreSQL compartilhado.
--
-- Roda automaticamente APENAS na primeira subida do postgres_shared (o
-- docker-entrypoint-initdb.d é ignorado quando o volume já tem dados). Em uma
-- instância que já existe, aplique à mão:
--   docker exec -i postgres_shared psql -U postgres < postgres/init/02-bootstrap-conecta.sql
--
-- A API não roda como superusuário: o dono do banco é o role do próprio projeto.

DO
$$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'conecta_admin') THEN
        CREATE ROLE conecta_admin LOGIN CREATEDB PASSWORD 'conecta_dev';
    ELSE
        ALTER ROLE conecta_admin WITH LOGIN CREATEDB PASSWORD 'conecta_dev';
    END IF;
END
$$;

SELECT 'CREATE DATABASE conecta OWNER conecta_admin'
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_database
    WHERE datname = 'conecta'
)\gexec

ALTER DATABASE conecta OWNER TO conecta_admin;

\connect conecta

-- O dono precisa poder criar as tabelas do núcleo e do domínio no schema public
-- (a partir do Postgres 15 o public deixou de ser gravável por padrão).
GRANT ALL ON SCHEMA public TO conecta_admin;
ALTER SCHEMA public OWNER TO conecta_admin;
