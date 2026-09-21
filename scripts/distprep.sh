#!/bin/bash
# Generate the sources a PostgreSQL release needs but does not ship, and stage
# them under postgres_bazel/templates/<version>/generated/.
#
# Postgres 18 dropped `make distprep` when upstream moved to meson, so its
# tarballs no longer carry the perl/bison/flex output that 16.x did. Rather
# than run those tools on every build, we run them once here and commit the
# result. That is safe because the output is platform-neutral: the values that
# vary by target are left as literal tokens for initdb to rewrite at runtime
# (FLOAT8PASSBYVAL and friends, see genbki.pl) or as C identifiers the target
# compiler resolves.
#
# Usage: scripts/distprep.sh <version>          # e.g. 18.4
#
# Re-run this for a single release whenever you add or refresh one; it doesn't
# touch any other version.

set -euo pipefail

VERSION=${1:-}
if [ -z "$VERSION" ]; then
    echo >&2 "usage: $(basename "$0") <version>    e.g. $(basename "$0") 18.4"
    exit 1
fi

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
MODULE="${REPO_ROOT}/postgres_bazel"
VERSIONS_BZL="${MODULE}/versions.bzl"
DEST="${MODULE}/templates/${VERSION}"

for tool in perl bison flex curl shasum; do
    command -v "$tool" >/dev/null || { echo >&2 "error: $tool is required"; exit 1; }
done

# Pull the pinned url/sha256 straight out of versions.bzl so the two can't drift.
read -r URL SHA256 < <(python3 - "$VERSIONS_BZL" "$VERSION" <<'PY'
import re, sys
src, want = open(sys.argv[1]).read(), sys.argv[2]
m = re.search(r'"%s":\s*_pg\(\s*"(\d+)",\s*"(\d+)",\s*"([0-9a-f]{64})"' % re.escape(want), src)
if not m:
    sys.exit("version %s is not listed in versions.bzl" % want)
major, minor, sha = m.groups()
print("https://ftp.postgresql.org/pub/source/v{0}.{1}/postgresql-{0}.{1}.tar.gz".format(major, minor), sha)
PY
)

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo >&2 "Downloading postgresql-${VERSION}"
curl -fsSL -o "$WORK/pg.tar.gz" "$URL"
ACTUAL=$(shasum -a 256 "$WORK/pg.tar.gz" | awk '{print $1}')
if [ "$ACTUAL" != "$SHA256" ]; then
    echo >&2 "error: sha256 mismatch for ${VERSION}"
    echo >&2 "  versions.bzl says ${SHA256}"
    echo >&2 "  download is       ${ACTUAL}"
    exit 1
fi

tar xzf "$WORK/pg.tar.gz" -C "$WORK"
SRC="$WORK/postgresql-${VERSION}"
cd "$SRC"

PG_MAJOR=${VERSION%%.*}

MANIFEST="$WORK/generated.manifest"
: > "$MANIFEST"
record() { for f in "$@"; do [ -e "$f" ] && echo "$f" >> "$MANIFEST"; done; }

# dtrace stand-in. 16 ships Gen_dummy_probes.sed and builds its .pl from a
# .prolog at build time, so the .pl alone isn't runnable there; 17+ ship only
# the perl script, which is sed-style and needs perl -n.
gen_probes() {
    if [ -f src/backend/utils/Gen_dummy_probes.sed ]; then
        sed -f src/backend/utils/Gen_dummy_probes.sed src/backend/utils/probes.d
    else
        perl -n src/backend/utils/Gen_dummy_probes.pl src/backend/utils/probes.d
    fi
}

# 16.x tarballs still carry most of their distprep output; 17 dropped it and
# 18 dropped it too while adding more generators. Where a file already ships
# we keep the shipped copy, so the generator runs below are all guarded.
SHIPS_DISTPREP=no
[ -f src/backend/parser/gram.c ] && SHIPS_DISTPREP=yes

# Even a tarball that ships the output only puts it under src/backend; the
# build expects it under src/include too, which upstream does with symlinks.
# Copy rather than regenerate so we keep exactly what upstream shipped.
if [ "$SHIPS_DISTPREP" = yes ]; then
    echo >&2 "  postgresql-${VERSION} ships its generated sources; staging them"
    cp src/backend/catalog/pg_*_d.h src/backend/catalog/schemapg.h \
       src/backend/catalog/system_fk_info.h src/include/catalog/
    cp src/backend/nodes/nodetags.h src/include/nodes/
    cp src/backend/utils/fmgroids.h src/backend/utils/fmgrprotos.h \
       src/backend/utils/errcodes.h src/include/utils/
    cp src/backend/storage/lmgr/lwlocknames.h src/include/storage/
    record src/include/catalog/pg_*_d.h src/include/catalog/schemapg.h \
           src/include/catalog/system_fk_info.h src/include/nodes/nodetags.h \
           src/include/utils/fmgroids.h src/include/utils/fmgrprotos.h \
           src/include/utils/errcodes.h src/include/storage/lwlocknames.h

    # probes.h is the one output never shipped in any release.
    gen_probes > src/include/utils/probes.h
    record src/include/utils/probes.h

    sort -u "$MANIFEST" -o "$MANIFEST"
    rm -rf "${DEST}/files"
    mkdir -p "${DEST}/files"
    while read -r f; do
        mkdir -p "${DEST}/files/$(dirname "$f")"
        cp "$f" "${DEST}/files/$f"
    done < "$MANIFEST"
    (cd "${DEST}/files" && find . -type f | sed 's|^\./||' | sort) > "${DEST}/files.manifest"
    echo >&2 "Staged $(wc -l < "$MANIFEST" | tr -d ' ') files for ${VERSION}."
    exit 0
fi

# Ordered header lists, read from upstream's own build files so they stay
# right across version bumps. Order matters: genbki needs the bootstrap
# catalogs first, and gen_node_support warns that reordering node headers
# risks ABI breakage.
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

echo >&2 "  gen_keywordlist.pl"
perl src/tools/gen_keywordlist.pl --extern --output src/common src/include/parser/kwlist.h
record src/common/kwlist_d.h

echo >&2 "  generate-errcodes.pl"
perl src/backend/utils/generate-errcodes.pl \
    --outfile src/include/utils/errcodes.h src/backend/utils/errcodes.txt
record src/include/utils/errcodes.h

# 17 introduced the wait-event tables.
if [ -f src/backend/utils/activity/generate-wait_event_types.pl ]; then
echo >&2 "  generate-wait_event_types.pl"
perl src/backend/utils/activity/generate-wait_event_types.pl \
    --outdir src/backend/utils/activity --code \
    src/backend/utils/activity/wait_event_names.txt >/dev/null
# wait_event.c and wait_event_funcs.c #include the two .c files as "utils/...",
# so they belong under src/include too.
cp src/backend/utils/activity/wait_event_types.h \
   src/backend/utils/activity/pgstat_wait_event.c \
   src/backend/utils/activity/wait_event_funcs_data.c \
   src/include/utils/
record src/include/utils/wait_event_types.h \
       src/include/utils/pgstat_wait_event.c \
       src/include/utils/wait_event_funcs_data.c \
       src/backend/utils/activity/wait_event_types.h \
       src/backend/utils/activity/pgstat_wait_event.c \
       src/backend/utils/activity/wait_event_funcs_data.c
fi

echo >&2 "  generate-lwlocknames.pl"
if [ -f src/include/storage/lwlocklist.h ]; then
    perl src/backend/storage/lmgr/generate-lwlocknames.pl \
        --outdir src/include/storage \
        src/include/storage/lwlocklist.h src/backend/utils/activity/wait_event_names.txt >/dev/null
else
    perl src/backend/storage/lmgr/generate-lwlocknames.pl \
        --outdir src/include/storage \
        src/backend/storage/lmgr/lwlocknames.txt >/dev/null
fi
record src/include/storage/lwlocknames.h

# Gen_dummy_probes.pl is a sed-style script, hence perl -n. It stands in for
# dtrace, which we don't build against.
echo >&2 "  Gen_dummy_probes"
gen_probes > src/include/utils/probes.h
record src/include/utils/probes.h

echo >&2 "  snowball_create.pl"
perl src/backend/snowball/snowball_create.pl \
    --input src/backend/snowball --outdir src/backend/snowball >/dev/null
record src/backend/snowball/snowball_create.sql

echo >&2 "  create_help.pl / gen_tabcomplete.pl"
perl src/bin/psql/create_help.pl \
    --docdir doc/src/sgml/ref --outdir src/bin/psql --basename sql_help >/dev/null
record src/bin/psql/sql_help.c src/bin/psql/sql_help.h
# 18 started generating tab-complete.c from tab-complete.in.c; before that it
# was an ordinary source file already in the tarball.
if [ -f src/bin/psql/gen_tabcomplete.pl ]; then
    perl src/bin/psql/gen_tabcomplete.pl \
        --outfile src/bin/psql/tab-complete.c src/bin/psql/tab-complete.in.c
    record src/bin/psql/tab-complete.c
fi

# plpgsql is a loadable module, but initdb's bootstrap does CREATE EXTENSION
# plpgsql, so the server can't finish initialising without it.
echo >&2 "  plpgsql"
perl src/tools/gen_keywordlist.pl --varname ReservedPLKeywords --output src/pl/plpgsql/src \
    src/pl/plpgsql/src/pl_reserved_kwlist.h
perl src/tools/gen_keywordlist.pl --varname UnreservedPLKeywords --output src/pl/plpgsql/src \
    src/pl/plpgsql/src/pl_unreserved_kwlist.h
perl src/pl/plpgsql/src/generate-plerrcodes.pl src/backend/utils/errcodes.txt \
    > src/pl/plpgsql/src/plerrcodes.h
record src/pl/plpgsql/src/pl_reserved_kwlist_d.h src/pl/plpgsql/src/pl_unreserved_kwlist_d.h \
       src/pl/plpgsql/src/plerrcodes.h

# bison: every grammar takes -d so the matching .h lands next to the .c.
echo >&2 "  bison"
for y in src/backend/parser/gram \
         src/backend/bootstrap/bootparse \
         src/backend/replication/repl_gram \
         src/backend/replication/syncrep_gram \
         src/backend/utils/adt/jsonpath_gram \
         src/pl/plpgsql/src/pl_gram; do
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

# Stage into templates/<version>/files/, which mirrors the archive layout.
# Only generated sources live here; the BUILD file is shared per major.
rm -rf "${DEST}/files"
mkdir -p "${DEST}/files"
while read -r f; do
    mkdir -p "${DEST}/files/$(dirname "$f")"
    cp "$f" "${DEST}/files/$f"
done < "$MANIFEST"

if [ ! -f "${MODULE}/templates/major/${PG_MAJOR}/BUILD.bazel" ]; then
    echo >&2
    echo >&2 "note: templates/major/${PG_MAJOR}/BUILD.bazel does not exist yet."
    echo >&2 "      Copy it from the nearest major version and adjust."
fi

# extension.bzl reads this to know what to symlink over the tarball.
(cd "${DEST}/files" && find . -type f | sed 's|^\./||' | sort) > "${DEST}/files.manifest"

echo >&2 "Wrote $(wc -l < "$MANIFEST" | tr -d ' ') generated files;" \
         "templates/${VERSION}/files.manifest now lists $(wc -l < "${DEST}/files.manifest" | tr -d ' ')."
