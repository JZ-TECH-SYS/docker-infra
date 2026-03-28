#!/usr/bin/env python3
import json
import os
import sqlite3
import time

DB_PATH = "/var/lib/pgadmin/pgadmin4.db"
SERVER_NAME = "postgres_shared"
GROUP_NAME = "Local"
HOST = "postgres"
PORT = 5432
MAINTENANCE_DB = "postgres"
USERNAME = "postgres"
CONNECTION_PARAMS = json.dumps(
    {
        "sslmode": "prefer",
        "connect_timeout": 10,
        "passfile": "/var/lib/pgadmin/.pgpass",
    }
)


def wait_for_db(timeout_seconds: int = 60) -> sqlite3.Connection:
    deadline = time.time() + timeout_seconds
    while True:
        if not os.path.exists(DB_PATH) or os.path.getsize(DB_PATH) == 0:
            if time.time() >= deadline:
                raise SystemExit("Timed out waiting for pgAdmin config database")
            time.sleep(1)
            continue

        try:
            conn = sqlite3.connect(DB_PATH, timeout=5)
            cur = conn.cursor()
            user_table = cur.execute(
                "select 1 from sqlite_master where type='table' and name='user'"
            ).fetchone()
            group_table = cur.execute(
                "select 1 from sqlite_master where type='table' and name='servergroup'"
            ).fetchone()
            server_table = cur.execute(
                "select 1 from sqlite_master where type='table' and name='server'"
            ).fetchone()
            server_columns = {
                row[1] for row in cur.execute("pragma table_info(server)").fetchall()
            }
            if (
                user_table
                and group_table
                and server_table
                and "connection_params" in server_columns
            ):
                return conn
            conn.close()
        except sqlite3.Error:
            pass

        if time.time() >= deadline:
            raise SystemExit("Timed out waiting for pgAdmin config database")
        time.sleep(1)


def main() -> None:
    conn = wait_for_db()
    cur = conn.cursor()

    user_row = cur.execute("select id from user order by id limit 1").fetchone()
    if not user_row:
        raise SystemExit("No pgAdmin user found in config database")
    user_id = user_row[0]

    group_row = cur.execute(
        "select id from servergroup where user_id = ? and name = ?",
        (user_id, GROUP_NAME),
    ).fetchone()
    if group_row:
        group_id = group_row[0]
    else:
        cur.execute(
            "insert into servergroup (user_id, name) values (?, ?)",
            (user_id, GROUP_NAME),
        )
        group_id = cur.lastrowid

    server_row = cur.execute(
        "select id from server where user_id = ? and name = ?",
        (user_id, SERVER_NAME),
    ).fetchone()

    payload = (
        group_id,
        HOST,
        PORT,
        MAINTENANCE_DB,
        USERNAME,
        CONNECTION_PARAMS,
        user_id,
        SERVER_NAME,
    )

    if server_row:
        cur.execute(
            """
            update server
               set servergroup_id = ?,
                   host = ?,
                   port = ?,
                   maintenance_db = ?,
                   username = ?,
                   connection_params = ?
             where user_id = ? and name = ?
            """,
            payload,
        )
    else:
        cur.execute(
            """
            insert into server (
                user_id,
                servergroup_id,
                name,
                host,
                port,
                maintenance_db,
                username,
                connection_params
            ) values (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (user_id, group_id, SERVER_NAME, HOST, PORT, MAINTENANCE_DB, USERNAME, CONNECTION_PARAMS),
        )

    conn.commit()
    conn.close()


if __name__ == "__main__":
    main()
