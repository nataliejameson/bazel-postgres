#!/usr/bin/env python3
"""Pin a PostgreSQL release in versions.bzl, stage its generated sources, and
give it a smoke test in postgres_test_builds."""

import argparse
import re
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
VERSIONS_BZL = REPO_ROOT / "postgres_bazel" / "versions.bzl"
TEST_BUILDS = REPO_ROOT / "postgres_test_builds"


def version_key(m):
    return (int(m[1]), int(m[2]))


def insert_before_later(src, matches, key, text):
    later = next((m for m in matches if version_key(m) > key), None)
    pos = later.start() if later else matches[-1].end()
    return src[:pos] + text + src[pos:]


def update_versions_bzl(major, minor, sha256):
    key = (major, minor)
    src = VERSIONS_BZL.read_text()
    matches = list(re.finditer(
        r'^    "(\d+)\.(\d+)": _pg\("\d+", "\d+", "([0-9a-f]{64})".*\n', src, re.M))
    if not matches:
        sys.exit(f"error: couldn't find the VERSIONS entries in {VERSIONS_BZL}")

    existing = next((m for m in matches if version_key(m) == key), None)
    if existing and existing[3] == sha256:
        print(f"versions.bzl already pins {major}.{minor}", file=sys.stderr)
        return
    if existing:
        print(f"versions.bzl: updating sha256 for {major}.{minor} (was {existing[3]})", file=sys.stderr)
        start, end = existing.span(3)
        src = src[:start] + sha256 + src[end:]
    else:
        print(f"versions.bzl: adding {major}.{minor}", file=sys.stderr)
        line = f'    "{major}.{minor}": _pg("{major}", "{minor}", "{sha256}"),\n'
        src = insert_before_later(src, matches, key, line)
    VERSIONS_BZL.write_text(src)


def update_module_bazel(major, minor):
    key = (major, minor)
    path = TEST_BUILDS / "MODULE.bazel"
    src = path.read_text()

    adds = list(re.finditer(r'^postgres\.add_version\(version = "(\d+)\.(\d+)"\)\n', src, re.M))
    if not adds:
        sys.exit(f"error: couldn't find postgres.add_version() calls in {path}")
    if not any(version_key(m) == key for m in adds):
        src = insert_before_later(src, adds, key, f'postgres.add_version(version = "{major}.{minor}")\n')

    use_repo = re.search(r'^use_repo\(\n    postgres,\n((?:    "[^"]+",\n)+)\)\n', src, re.M)
    if not use_repo:
        sys.exit(f"error: couldn't find use_repo(postgres, ...) in {path}")
    repos = set(re.findall(r'"([^"]+)"', use_repo[1])) | {f"postgres_{major}_{minor}"}
    start, end = use_repo.span(1)
    src = src[:start] + "".join(f'    "{r}",\n' for r in sorted(repos)) + src[end:]
    path.write_text(src)


def update_build_bazel(major, minor):
    key = (major, minor)
    path = TEST_BUILDS / "BUILD.bazel"
    src = path.read_text()
    tests = list(re.finditer(
        r'^postgres_smoke_test\(\n    name = "postgres_(\d+)_(\d+)_smoke_test",\n.*?^\)\n',
        src, re.M | re.S))
    if any(version_key(m) == key for m in tests):
        return

    repo = f"postgres_{major}_{minor}"
    block = (
        "postgres_smoke_test(\n"
        f'    name = "{repo}_smoke_test",\n'
        f'    repo = "@{repo}",\n'
        f'    version = "{major}.{minor}",\n'
        ")\n"
    )
    later = next((m for m in tests if version_key(m) > key), None)
    if later:
        src = src[:later.start()] + block + "\n" + src[later.start():]
    else:
        src = src.rstrip("\n") + "\n\n" + block
    path.write_text(src)


def sha256_arg(value):
    if not re.fullmatch(r"[0-9a-f]{64}", value):
        raise argparse.ArgumentTypeError("must be 64 lowercase hex characters")
    return value


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("major", type=int)
    parser.add_argument("minor", type=int)
    parser.add_argument("sha256", type=sha256_arg, help="sha256 of the upstream source tarball")
    args = parser.parse_args()

    update_versions_bzl(args.major, args.minor, args.sha256)
    distprep = subprocess.run([REPO_ROOT / "scripts" / "distprep.sh", f"{args.major}.{args.minor}"])
    if distprep.returncode:
        sys.exit(distprep.returncode)
    update_module_bazel(args.major, args.minor)
    update_build_bazel(args.major, args.minor)

    print(f"Added {args.major}.{args.minor}. Run scripts/test.sh, or:", file=sys.stderr)
    print(f"  (cd postgres_test_builds && bazel test //:postgres_{args.major}_{args.minor}_smoke_test)",
          file=sys.stderr)


if __name__ == "__main__":
    main()
