#!/bin/bash
# initdb a cluster, start it, run a query through psql, shut it down.

set -euo pipefail

DIST=$(cd "$(dirname "${BASH_SOURCE[0]}")/dist" && pwd)
PGDATA="${TEST_TMPDIR:-/tmp}/pgdata"

# Not $TEST_TMPDIR: sockaddr_un caps the path at 103 bytes and bazel's
# runfiles paths blow straight past that.
SOCKDIR=$(mktemp -d /tmp/pgsmoke.XXXXXX)
trap '"$DIST/bin/pg_ctl" -D "$PGDATA" -m immediate -w stop >/dev/null 2>&1 || true; rm -rf "$SOCKDIR"' EXIT

rm -rf "$PGDATA"
"$DIST/bin/initdb" -D "$PGDATA" -U postgres --no-sync -A trust > "$SOCKDIR/initdb.log" 2>&1 || {
    echo "initdb failed:"; cat "$SOCKDIR/initdb.log"; exit 1;
}

"$DIST/bin/pg_ctl" -D "$PGDATA" -l "$SOCKDIR/server.log" \
    -o "-k $SOCKDIR -p 55432 -c listen_addresses=" -w start > /dev/null 2>&1 || {
    echo "pg_ctl start failed:"; cat "$SOCKDIR/server.log"; exit 1;
}

psql() { "$DIST/bin/psql" -h "$SOCKDIR" -p 55432 -U postgres -d postgres -Atc "$1"; }

version=$(psql "select version();")
echo "$version"
case "$version" in
    "PostgreSQL 18.4"*) ;;
    *) echo "unexpected version: $version"; exit 1 ;;
esac

psql "create table t(i int)" > /dev/null
psql "insert into t select generate_series(1, 1000)" > /dev/null
got=$(psql "select count(*) || ',' || sum(i) from t")
[ "$got" = "1000,500500" ] || { echo "unexpected query result: $got"; exit 1; }

# plpgsql is created by initdb's bootstrap; make sure it actually loads.
psql "do \$\$ begin raise notice 'ok'; end \$\$;" > /dev/null

echo "PASS"
