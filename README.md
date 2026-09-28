# Postgres On Bazel

Builds PostgreSQL from source with Bazel.

Differences from the [BCR postgres module](https://registry.bazel.build/modules/postgres):

- Multiple postgres versions can be configured concurrently, rather than relying on a single BCR version
- Builds the server and frontend tools in addition to `libpq`.

**beep boop** this is mostly robot generated. PRs making this more human friendly are welcome.

## Usage

```bazel
bazel_dep(name = "postgres_bazel")
git_override(
    module_name = "postgres_bazel",
    commit = "<commit>",
    remote = "https://github.com/nataliejameson/bazel-postgres.git",
    strip_prefix = "postgres_bazel",
)

postgres = use_extension("@postgres_bazel//:extension.bzl", "postgres")
postgres.add_version(repo_name = "postgres_17", version = "17.4")
postgres.add_version(version = "18.4")
postgres.default_version(repo_name = "my_postgres", version = "17.4")
use_repo(postgres, "my_postgres", "postgres_17", "postgres_18_4", "postgres_config")
```

Then depend on what you need:

```bazel
cc_library(
    name = "needs_libpq",
    deps = ["@postgres_18_4//:libpq"],
)
```

### Available Versions

By default there are a number of postgres 16, 17, and 18 minor revisions available. See [versions.bzl](./postgres_bazel/versions.bzl) for a complete list.

### Available Targets

Libraries:

* `libpq`

Binaries:

* `psql`
* `initdb`
* `pg_ctl`
* `postgres`

For using each of these binaries as tools or via `bazel run`, use the `_bin` suffixed version of each of those targets. They pull all dependent files in as runfiles, ensure that postgres has its expected path layout, and executes the binary in the right bazel configuration.

### Extension API

`add_version`:
  * `repo_name`: The name of the repo to export. Defaults to `postgres_<major>_<minor>`
  * `version`: The version to use. Unless `url` + `sha256` are specified, this must be present in `postgres_bazel/versions.bzl`
  * `url`: The url to postgres source for this version. Requires `sha256` if set.
  * `sha256`: The hash of the file at `url`. Invalid if `url` is not specified.
  * `template`: The major version BUILD template to use.

`default_version`:
  * `repo_name`: The name of the repo to export. Defaults to `postgres`
  * `version`: The version to alias to. This must be specified in an `add_version()` call.


### Testing a version

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

To run a full integration test like CI does, run `./scripts/test.sh` from the repository root. It will build every version in versions.bzl for you and verify that it works.

## Adding a version

For new minor versions, run `./scripts/add_version.py <major> <minor> <sha256>` where sha256 is the hash of the postgres source tarball.

For new major versions, you will also need to create a `postgres_bazel/templates/major/<major>/BUILD.bazel` and `postgres_bazel/templates/major/<major>/MODULE.bazel.template` file.

Note that this will add some generated files from the postgres source tree to the repository because distprep needs to be run for each minor revision.

`postgres_bazel/templates/README.md` has more details about what actually happens here, and what the differences are that had to be accounted for each major version.

## Build configuration

Upstream's `--with-*` switches are available as Bazel flags, and they live in one shared `@postgres_config` repository rather than per version, so a project building several releases configures them once.

Available bazel flags are:

* `--@postgres_config//:enable_cassert`: bool (default false)
* `--@postgres_config//:gssapi_lib`: label (default system gssapi)
* `--@postgres_config//:with_blocksize`: int (default 8): One of 2^{0..5}
* `--@postgres_config//:with_gssapi`: bool (default false)
* `--@postgres_config//:with_krb_srvnam`: string (default postgres)
* `--@postgres_config//:with_libcurl`: bool (default false)
* `--@postgres_config//:with_lz4`: bool (default false)
* `--@postgres_config//:with_pgport`: int (default 5432)
* `--@postgres_config//:with_readline`: bool (default false)
* `--@postgres_config//:with_segsize`: int (default 1)
* `--@postgres_config//:with_ssl`: One of `openssl` (default), `boringssl`, or `none`
* `--@postgres_config//:with_wal_blocksize`: int (default 8). One of 2^{0..6}.
* `--@postgres_config//:with_zlib`: bool (default false)
* `--@postgres_config//:with_zstd`: bool (default false)

`pg_config.h` comes from a real `rules_cc_autoconf` probe of upstream's `pg_config.h.in`, not a hand-maintained header. See the `:autoconf_probes` target in each postgres version's root.
