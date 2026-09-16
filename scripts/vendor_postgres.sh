#!/bin/bash
# Re-vendor the PostgreSQL source tree into postgres_bazel/ and run the code
# generators that PG18 no longer ships (upstream dropped `make distprep` when it
# moved to meson).
#
# The generated output is platform-neutral: the values that do vary by target
# (FLOAT8PASSBYVAL, NAMEDATALEN, SIZEOF_POINTER, ALIGNOF_POINTER) are left as
# literal tokens that initdb rewrites at runtime, or as C identifiers the target
# compiler resolves. So generating once here and committing is safe for every
# platform we build for.

set -euo pipefail

PG_MAJOR="${PG_MAJOR:-18}"
PG_MINOR="${PG_MINOR:-4}"
PG_VERSION="${PG_MAJOR}.${PG_MINOR}"
PG_SHA256="${PG_SHA256:-450aa8f2da06c46f8221916e82ae06b04fb1040f8f00643dbf8b7d663caac0b9}"

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
DEST="${REPO_ROOT}/postgres_bazel"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

for tool in perl bison flex; do
    command -v "$tool" >/dev/null || { echo >&2 "error: $tool is required to re-vendor"; exit 1; }
done

TARBALL="${WORK}/postgresql-${PG_VERSION}.tar.gz"
echo >&2 "Downloading postgresql-${PG_VERSION}"
curl -fsSL -o "$TARBALL" \
    "https://ftp.postgresql.org/pub/source/v${PG_VERSION}/postgresql-${PG_VERSION}.tar.gz"

ACTUAL=$(shasum -a 256 "$TARBALL" | awk '{print $1}')
if [ "$ACTUAL" != "$PG_SHA256" ]; then
    echo >&2 "error: sha256 mismatch for postgresql-${PG_VERSION}"
    echo >&2 "  expected ${PG_SHA256}"
    echo >&2 "  actual   ${ACTUAL}"
    exit 1
fi

tar xzf "$TARBALL" -C "$WORK"
SRC="${WORK}/postgresql-${PG_VERSION}"

echo >&2 "Generating sources"
"${REPO_ROOT}/scripts/distprep.sh" "$SRC"

echo >&2 "Replacing ${DEST}"
# Keep the Bazel files; everything else is replaced wholesale by the tarball.
mkdir -p "$DEST"
find "$DEST" -mindepth 1 -maxdepth 1 \
    ! -name 'MODULE.bazel' ! -name 'BUILD.bazel' ! -name 'MODULE.bazel.lock' \
    -exec rm -rf {} +
cp -R "$SRC"/. "$DEST"/

# The tarball ships its own .gitignore files, which ignore both the outputs
# distprep.sh just generated and a few files upstream actually distributes
# (src/port/win32ver.rc is caught by a global `win32ver.rc` rule aimed at
# build-generated copies). We want the whole vendored tree tracked verbatim,
# so force-add it wholesale rather than curating exceptions.
echo >&2 "Staging"
rm -f "${DEST}/generated.manifest"
cd "$REPO_ROOT"
git add --force "$DEST"

echo >&2 "Done. Vendored postgresql-${PG_VERSION} into ${DEST}"
