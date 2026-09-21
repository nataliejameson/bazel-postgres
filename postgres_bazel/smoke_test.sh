#!/bin/bash
# initdb a cluster, start it, run queries through psql, shut it down.
#
# Usage: smoke_test.sh <rlocationpath-of-pg_dist> <expected-version>

set -euo pipefail

# --- bazel runfiles bootstrap (canonical snippet) ---
# shellcheck disable=SC1090,SC1091
f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo >&2 "ERROR: cannot find $f"; exit 1; }
# --- end runfiles bootstrap ---

DIST=$(rlocation "$1")
EXPECTED_VERSION="$2"
[ -d "$DIST" ] || { echo "no dist tree at $1"; exit 1; }

PGDATA="${TEST_TMPDIR:-/tmp}/pgdata"

# Not under TEST_TMPDIR: sockaddr_un caps the socket path at 103 bytes and
# bazel's runfiles paths run well past that.
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

version=$(psql "select version()")
echo "$version"
case "$version" in
    "PostgreSQL $EXPECTED_VERSION"*) ;;
    *) echo "expected PostgreSQL $EXPECTED_VERSION, got: $version"; exit 1 ;;
esac

psql "create table t(i int)" > /dev/null
psql "insert into t select generate_series(1, 1000)" > /dev/null
got=$(psql "select count(*) || ',' || sum(i) from t")
[ "$got" = "1000,500500" ] || { echo "unexpected query result: $got"; exit 1; }

# plpgsql is created by initdb's bootstrap; make sure it actually loads.
psql "do \$\$ begin raise notice 'ok'; end \$\$;" > /dev/null

echo "PASS"
