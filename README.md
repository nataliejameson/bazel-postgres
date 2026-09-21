# postgres-bazel

Builds PostgreSQL from source with Bazel. Unlike the
[BCR postgres module](https://registry.bazel.build/modules/postgres), which
stops at libpq, this builds the server and the frontend tools too, so
integration tests can start a real database instead of relying on a system
install.

Each release becomes its own repository, so a project can depend on several at
once.

## Usage

```bazel
bazel_dep(name = "postgres_bazel")
# plus a local_path_override / git_override pointing at the postgres_bazel
# subdirectory of this repo

postgres = use_extension("@postgres_bazel//:extension.bzl", "postgres")
postgres.add_version(version = "18.4")
use_repo(postgres, "postgres_18_4", "postgres_config")
```

Then depend on what you need:

```bazel
cc_library(
    name = "needs_libpq",
    deps = ["@postgres_18_4//:libpq"],
)
```

Targets per version: `libpq`, and a `<name>_bin` wrapper for each of `psql`,
`initdb`, `pg_ctl` and `postgres`:

```sh
bazel run @postgres_18_4//:psql_bin -- --version
```

The wrappers carry the installation tree as runfiles and exec the right
binary out of it, so they work as `bazel run` targets, as tools, or in a
test's `data` — no `$(location ...)/bin/psql` plumbing. The tree itself is
`pg_dist` if you need it directly; its `bin/` + `share/` layout matters,
because `get_share_path()` locates `PGSHAREDIR` by walking up from the
running executable and only does so when the binary sits in a directory
named `bin`.

`add_version` also takes `repo_name` to override the default
`postgres_<version>`, and `url` + `sha256` (both or neither) to build a
release that isn't in `versions.bzl`.

## Testing a version

`postgres_smoke_test` initdbs a cluster, starts it, queries it through psql,
and shuts it down:

```bazel
load("@postgres_bazel//:defs.bzl", "postgres_smoke_test")

postgres_smoke_test(
    name = "pg_18_4_smoke_test",
    repo = "@postgres_18_4",
    version = "18.4",
)
```

`scripts/test.sh` runs the suite in `postgres_test_builds/`, which is what CI
does.

## Adding a version

See `postgres_bazel/templates/README.md`. In short: add it to `versions.bzl`,
run `scripts/distprep.sh <version>`, copy and adjust the overlay, add a smoke
test.

## Build configuration

Upstream's `--with-*` switches are Bazel flags, and they live in one shared
`@postgres_config` repository rather than per version, so a project building
several releases configures them once:

```sh
bazel build --@postgres_config//:with_ssl=boringssl //...
```

`with_ssl` takes `openssl` (default), `boringssl` or `none`; `with_zlib`,
`with_lz4`, `with_zstd`, `with_libcurl`, `with_readline`, `with_gssapi` and
`enable_cassert` are booleans; `with_pgport`, `with_blocksize`,
`with_wal_blocksize` and `with_segsize` take values.

`pg_config.h` comes from a real `rules_cc_autoconf` probe of upstream's
`pg_config.h.in`, not a hand-maintained header.
