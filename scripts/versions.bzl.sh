#!/bin/bash

set -euo pipefail

DOWNLOAD_DIR="${DOWNLOAD_DIR:-}"

if [ -z "${DOWNLOAD_DIR}" ]; then
    DOWNLOAD_DIR=$(mktemp -d)
    trap 'rm -rf "$DOWNLOAD_DIR"' EXIT
    echo "Created temp path at DOWNLOAD_DIR=${DOWNLOAD_DIR}"
fi


version() {
    major="$1"
    minor="$2"

    DEST_PATH="${DOWNLOAD_DIR}/postgres-${major}.${minor}.tar.gz"
    if [ ! -f "$DEST_PATH" ]; then
        curl "https://ftp.postgresql.org/pub/source/v${major}.${minor}/postgresql-${major}.${minor}.tar.gz" -o "$DEST_PATH" 2>/dev/null
    fi
    SHA256=$(shasum -a 256 "$DEST_PATH" | awk {'print $1'})
    pg_version_num=$(printf '%02d00%02d' "$major" "$minor")
    echo "        \"${minor}\": PostgresVersion(pg_version_num =\"${pg_version_num}\", major =\"${major}\", minor = \"${minor}\", sha256 = \"${SHA256}\"),"
}

write_versions() {
    major="$1"
    echo "    \"${major}\": {"
    for minor in $(seq "${2}" "${3}"); do
        version "$major" "$minor"
    done
    echo "    },"
}

cat <<EOF
PostgresVersion = provider(
    fields = [
        "pg_version_num",
        "major",
        "minor",
        "sha256",
    ],
)

VERSIONS = {

EOF

write_versions "16" "2" "14"
write_versions "17" "0" "10"
write_versions "18" "0" "4"
    
echo '}'
