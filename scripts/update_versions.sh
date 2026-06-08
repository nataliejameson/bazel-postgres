#!/bin/bash

set -euo pipefail

SCRIPTS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && echo "$PWD")

PG_16="16"
PG_16_START="2"
PG_16_END="14"

PG_17="17"
PG_17_START="0"
PG_17_END="10"

PG_18="18"
PG_18_START="0"
PG_18_END="4"

DOWNLOAD_DIR="${DOWNLOAD_DIR:-}"

if [ -z "${DOWNLOAD_DIR}" ]; then
    DOWNLOAD_DIR=$(mktemp -d)
    trap 'rm -rf "$DOWNLOAD_DIR"' EXIT
    echo >&2 "Created temp path at DOWNLOAD_DIR=${DOWNLOAD_DIR}"
fi


download_version() {
    major="$1"
    minor="$2"

    DEST_PATH="${DOWNLOAD_DIR}/postgres-${major}.${minor}.tar.gz"
    if [ ! -f "$DEST_PATH" ]; then
        echo >&2 "Download ${major}.${minor}.tar.gz"
        curl "https://ftp.postgresql.org/pub/source/v${major}.${minor}/postgresql-${major}.${minor}.tar.gz" -o "$DEST_PATH" 2>/dev/null
    fi
    SHA256=$(shasum -a 256 "$DEST_PATH" | awk {'print $1'})
    pg_version_num=$(printf '%02d00%02d' "$major" "$minor")
    echo "        \"${minor}\": PostgresVersion(pg_version_num = \"${pg_version_num}\", major = \"${major}\", minor = \"${minor}\", sha256 = \"${SHA256}\"),"
}

write_versions() {
    major="$1"
    echo "    \"${major}\": {"
    for minor in $(seq "${2}" "${3}"); do
        download_version "$major" "$minor"
    done
    echo "    },"
}

write_versions_bzl() {
    versions_bzl="${SCRIPTS_DIR}/../postgres_bazel/versions.bzl"
    cat > "$versions_bzl" <<EOF
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

    write_versions "$PG_16" "$PG_16_START" "$PG_16_END" >> "$versions_bzl"
    write_versions "$PG_17" "$PG_17_START" "$PG_17_END" >> "$versions_bzl"
    write_versions "$PG_18" "$PG_18_START" "$PG_18_END" >> "$versions_bzl"

    echo '}' >> "$versions_bzl"
}

test_build_line() {
    echo "alias(name = \"postgres_${1}_${2}_pq\", actual = \"@postgres_${1}_${2}//:libpq\")"
    # Commented out until we have postgres bins building properly
    #echo "alias(name = \"postgres_${1}_${2}_postgres\", actual = \"@postgres_${1}_${2}//:postgres\")"
}

write_test_project_build_bazel() {
    test_build_bazel="${SCRIPTS_DIR}/../postgres_test_builds/BUILD.bazel"
    echo "" > "$test_build_bazel"
    for i in $(seq "$PG_16_START" "$PG_16_END"); do
        test_build_line "16" "$i" >> "$test_build_bazel"
    done
    for i in $(seq "$PG_17_START" "$PG_17_END"); do
        test_build_line "17" "$i" >> "$test_build_bazel"
    done
    for i in $(seq "$PG_18_START" "$PG_18_END"); do
        test_build_line "18" "$i" >> "$test_build_bazel"
    done
}

test_module_line() {
    cat <<EOF
postgres.version(
    major = "$1",
    minor = "$2",
)
EOF
}

write_test_project_module_bazel() {
    test_module_bazel="${SCRIPTS_DIR}/../postgres_test_builds/MODULE.bazel"
    cat > "$test_module_bazel" <<EOF
module(name = "postgres_test_builds")

bazel_dep(name = "postgres_bazel")
local_path_override(
    module_name = "postgres_bazel",
    path = "../postgres_bazel",
)

postgres = use_extension("@postgres_bazel//:extension.bzl", "postgres")

EOF
    use_repo="use_repo(\n    postgres,\n"
    for i in $(seq "$PG_16_START" "$PG_16_END"); do
        test_module_line "16" "$i" >> "$test_module_bazel"
        use_repo="${use_repo}    \"postgres_16_${i}\",\n"
    done
    for i in $(seq "$PG_17_START" "$PG_17_END"); do
        test_module_line "17" "$i" >> "$test_module_bazel"
        use_repo="${use_repo}    \"postgres_17_${i}\",\n"
    done
    for i in $(seq "$PG_18_START" "$PG_18_END"); do
        test_module_line "18" "$i" >> "$test_module_bazel"
        use_repo="${use_repo}    \"postgres_18_${i}\",\n"
    done
    use_repo="${use_repo})\n"
    echo -e "$use_repo" >> "$test_module_bazel"
}

echo >&2 "Updating versions.bzl"
write_versions_bzl
echo >&2 "Updating test project BUILD.bazel"
write_test_project_build_bazel
echo >&2 "Updating test project MODULE.bazel"
write_test_project_module_bazel
