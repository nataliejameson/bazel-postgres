#!/bin/bash
# initdb a cluster, start it, run queries through psql, shut it down.
#
# Usage: smoke_test.sh <expected-version> <initdb> <pg_ctl> <psql>
# The three binaries are rlocationpaths of pg_wrapper targets.

# --- bazel runfiles bootstrap ---
# Deliberately before `set -e`: the snippet probes several locations and
# relies on the failures falling through the || chain.
# shellcheck disable=SC1090,SC1091
f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo >&2 "ERROR: cannot find $f"; exit 1; }
# --- end runfiles bootstrap ---
set -euo pipefail

EXPECTED_VERSION="$1"
INITDB=$(rlocation "$2")
PG_CTL=$(rlocation "$3")
PSQL=$(rlocation "$4")

PGDATA="${TEST_TMPDIR:-/tmp}/pgdata"

# Not under TEST_TMPDIR: sockaddr_un caps the socket path at 103 bytes and
# bazel's runfiles paths run well past that.
SOCKDIR=$(mktemp -d /tmp/pgsmoke.XXXXXX)
trap '"$PG_CTL" -D "$PGDATA" -m immediate -w stop >/dev/null 2>&1 || true; rm -rf "$SOCKDIR"' EXIT

rm -rf "$PGDATA"
"$INITDB" -D "$PGDATA" -U postgres --no-sync -A trust > "$SOCKDIR/initdb.log" 2>&1 || {
    echo "initdb failed:"; cat "$SOCKDIR/initdb.log"; exit 1;
}

"$PG_CTL" -D "$PGDATA" -l "$SOCKDIR/server.log" \
    -o "-k $SOCKDIR -p 55432 -c listen_addresses=" -w start > /dev/null 2>&1 || {
    echo "pg_ctl start failed:"; cat "$SOCKDIR/server.log"; exit 1;
}

psql() { "$PSQL" -h "$SOCKDIR" -p 55432 -U postgres -d postgres -Atc "$1"; }

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
