#!/bin/bash
# Run the PostgreSQL code generators against an extracted source tree.
#
# PG18 dropped `make distprep`, so the release tarball no longer ships the
# perl/bison/flex outputs that 16.x did. This reproduces them in-tree, at the
# paths the build expects, and writes the list of produced files to
# generated.manifest at the tree root.
#
# Usage: distprep.sh <path-to-extracted-postgresql-source>

set -euo pipefail

SRC=${1:?usage: distprep.sh <postgres-source-dir>}
cd "$SRC"

PG_MAJOR=$(sed -n 's/^AC_INIT(\[PostgreSQL\], \[\([0-9]*\)\..*/\1/p' configure.ac)
: "${PG_MAJOR:?could not determine major version from configure.ac}"

MANIFEST="${SRC}/generated.manifest"
: > "$MANIFEST"
record() { for f in "$@"; do [ -e "$f" ] && echo "$f" >> "$MANIFEST"; done; }

# Ordered header lists. Order is significant: genbki relies on bootstrap
# catalogs coming first, and gen_node_support warns that reordering node
# headers risks ABI breakage. Both lists are read from upstream's own build
# files so they stay correct across version bumps.
catalog_headers=$(sed -n '/^catalog_headers = \[/,/^\]/p' src/include/catalog/meson.build \
    | grep -oE "pg_[a-z_0-9]+\.h" | sed 's|^|src/include/catalog/|')
node_headers=$(sed -n '/^node_headers = /,/^$/p' src/backend/nodes/Makefile \
    | sed 's/node_headers = *//; s/\\//' | tr -s ' \t' '\n' | grep '\.h$' | sed 's|^|src/include/|')

echo >&2 "  genbki.pl"
perl src/backend/catalog/genbki.pl \
    --include-path=src/include --set-version="$PG_MAJOR" \
    --output=src/include/catalog $catalog_headers >/dev/null
record src/include/catalog/postgres.bki src/include/catalog/schemapg.h \
       src/include/catalog/system_fk_info.h src/include/catalog/system_constraints.sql \
       src/include/catalog/syscache_ids.h src/include/catalog/syscache_info.h \
       src/include/catalog/pg_*_d.h

echo >&2 "  gen_node_support.pl"
perl src/backend/nodes/gen_node_support.pl --outdir src/backend/nodes $node_headers >/dev/null
cp src/backend/nodes/nodetags.h src/include/nodes/nodetags.h
record src/include/nodes/nodetags.h src/backend/nodes/nodetags.h \
       src/backend/nodes/*funcs.funcs.c src/backend/nodes/*funcs.switch.c

echo >&2 "  Gen_fmgrtab.pl"
perl -I src/backend/catalog src/backend/utils/Gen_fmgrtab.pl \
    --include-path=src/include --output=src/backend/utils \
    src/include/catalog/pg_proc.dat >/dev/null
cp src/backend/utils/fmgroids.h src/backend/utils/fmgrprotos.h src/include/utils/
record src/include/utils/fmgroids.h src/include/utils/fmgrprotos.h \
       src/backend/utils/fmgroids.h src/backend/utils/fmgrprotos.h src/backend/utils/fmgrtab.c

echo >&2 "  generate-errcodes.pl"
perl src/backend/utils/generate-errcodes.pl \
    --outfile src/include/utils/errcodes.h src/backend/utils/errcodes.txt
record src/include/utils/errcodes.h

echo >&2 "  generate-wait_event_types.pl"
perl src/backend/utils/activity/generate-wait_event_types.pl \
    --outdir src/backend/utils/activity --code \
    src/backend/utils/activity/wait_event_names.txt >/dev/null
cp src/backend/utils/activity/wait_event_types.h src/include/utils/wait_event_types.h
record src/include/utils/wait_event_types.h src/backend/utils/activity/wait_event_types.h \
       src/backend/utils/activity/pgstat_wait_event.c \
       src/backend/utils/activity/wait_event_funcs_data.c

echo >&2 "  generate-lwlocknames.pl"
perl src/backend/storage/lmgr/generate-lwlocknames.pl \
    --outdir src/include/storage \
    src/include/storage/lwlocklist.h src/backend/utils/activity/wait_event_names.txt >/dev/null
record src/include/storage/lwlocknames.h

# Gen_dummy_probes.pl is a sed-style script, so it needs perl -n. This stands in
# for dtrace, which we don't build against.
echo >&2 "  Gen_dummy_probes.pl"
perl -n src/backend/utils/Gen_dummy_probes.pl src/backend/utils/probes.d \
    > src/include/utils/probes.h
record src/include/utils/probes.h

echo >&2 "  snowball_create.pl"
perl src/backend/snowball/snowball_create.pl \
    --input src/backend/snowball --outdir src/backend/snowball >/dev/null
record src/backend/snowball/snowball_create.sql

echo >&2 "  create_help.pl / gen_tabcomplete.pl"
perl src/bin/psql/create_help.pl \
    --docdir doc/src/sgml/ref --outdir src/bin/psql --basename sql_help >/dev/null
perl src/bin/psql/gen_tabcomplete.pl \
    --outfile src/bin/psql/tab-complete.c src/bin/psql/tab-complete.in.c
record src/bin/psql/sql_help.c src/bin/psql/sql_help.h src/bin/psql/tab-complete.c

# bison: every grammar takes -d so the matching .h is emitted next to the .c.
echo >&2 "  bison"
for y in src/backend/parser/gram \
         src/backend/bootstrap/bootparse \
         src/backend/replication/repl_gram \
         src/backend/replication/syncrep_gram \
         src/backend/utils/adt/jsonpath_gram; do
    bison -d -o "${y}.c" "${y}.y"
    record "${y}.c" "${y}.h"
done

# flex: backend scanners use -CF, frontend scanners -Cfe, both with -p -p, per
# the per-directory FLEXFLAGS overrides in upstream's Makefiles.
echo >&2 "  flex"
flex_gen() { flex $1 -o "${2}.c" "${2}.l"; record "${2}.c"; }
flex_gen "-CF -p -p" src/backend/parser/scan
flex_gen "-CF -p -p" src/backend/utils/adt/jsonpath_scan
flex_gen "-CF -p -p" src/backend/bootstrap/bootscanner
flex_gen "-CF -p -p" src/backend/replication/repl_scanner
flex_gen "-CF -p -p" src/backend/replication/syncrep_scanner
flex_gen "-CF -p -p" src/backend/utils/misc/guc-file
flex_gen "-Cfe -p -p" src/fe_utils/psqlscan
flex_gen "-Cfe -p -p" src/bin/psql/psqlscanslash

sort -u "$MANIFEST" -o "$MANIFEST"
echo >&2 "  generated $(wc -l < "$MANIFEST" | tr -d ' ') files"
