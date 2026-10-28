-- Bootstrap do DeltaSense no PostgreSQL compartilhado (postgres_shared).
--
-- OPT-IN. O dev padrao do DeltaSense sobe um Postgres PROPRIO (DeltaSense/infra/docker-compose.yml),
-- porque o dev dele guarda estado que doi perder a cada troca: a CA interna que assina os agentes,
-- os agentes ja cadastrados, o admin e as empresas de teste. Este arquivo existe para quem prefere
-- o modelo da frota — um unico Postgres de dev para todos os apps. Com ele aplicado, basta a
-- connection string de dev do DeltaSense apontar para a porta 5433 (host do postgres_shared);
-- usuario, senha e database seguem iguais ao compose local (deltasense / deltasense_dev / deltasense).
--
-- Roda automaticamente APENAS na primeira subida do postgres_shared (o docker-entrypoint-initdb.d e
-- ignorado quando o volume ja tem dados). Numa instancia que ja existe, aplique a mao:
--   docker exec -i postgres_shared psql -U postgres < postgres/init/03-bootstrap-deltasense.sql

DO
$$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'deltasense') THEN
        CREATE ROLE deltasense LOGIN CREATEDB PASSWORD 'deltasense_dev';
    ELSE
        ALTER ROLE deltasense WITH LOGIN CREATEDB PASSWORD 'deltasense_dev';
    END IF;
END
$$;

SELECT 'CREATE DATABASE deltasense OWNER deltasense'
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_database
    WHERE datname = 'deltasense'
)\gexec

ALTER DATABASE deltasense OWNER TO deltasense;

\connect deltasense

-- A partir do Postgres 15 o schema public deixou de ser gravavel por padrao: o dono precisa
-- poder criar as tabelas das migrations do app.
GRANT ALL ON SCHEMA public TO deltasense;
ALTER SCHEMA public OWNER TO deltasense;
