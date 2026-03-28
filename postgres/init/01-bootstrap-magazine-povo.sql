DO
$$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'magazine_admin') THEN
        CREATE ROLE magazine_admin LOGIN PASSWORD 'magazine_povo137@';
    ELSE
        ALTER ROLE magazine_admin WITH LOGIN PASSWORD 'magazine_povo137@';
    END IF;
END
$$;

SELECT 'CREATE DATABASE magazine_povo OWNER magazine_admin'
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_database
    WHERE datname = 'magazine_povo'
)\gexec

ALTER DATABASE magazine_povo OWNER TO magazine_admin;

\connect magazine_povo

CREATE SCHEMA IF NOT EXISTS sis AUTHORIZATION magazine_admin;