# Postgres-bazel

Simple Bazel module that builds postgresql with Bazel for consumption by other tools that require libpq. This is mostly based off of https://registry-preview.bazel.build/modules/postgres, however with some slight changes in how it exposes multiple versions and with support for multiple major/minor versions to be defined.

# Configuration

In your MODULE.bazel, add:

```bazel
bazel_dep(name = "postgres_bazel")
# local_path_override / git_override / whatever
# This needs to point to the postgres_bazel subdirectory

postgres = use_extension("@postgres_bazel//:extension.bzl", "postgres")
postgres.version(major = "16", minor = "14")
```

Run `bazel mod tidy` to have it update your `use_repo` usages. Then in your build file, add a dependency with:

```bazel
cc_library(
    name = "my_thing_that_needs_pq",
    ...
    deps = ["@postgres_16_14//:libpq"],
)
```

# Updating versions

To update the available versions in versions.bzl, set a new version range in `scripts/update_versions.sh`, and re-run the script. It will download every major and minor combination, get their hashes, and update versions.bzl. It will also update the test suite.

# Testing

There is a test suite, `scripts/test.sh` that runs on github actions that tests building every version of postgres on linux (arm64 and amd64), and that can easily be invoked locally. It does this by creating a sample repo, and building every single target for every combination of major and minor versions specified in `scripts/update_versions.sh`

# pg_config.h values

These were taken directly from the BCR postgres package. They're reasonable, but not hyper optimized, build settings. Feel free to take a look at the templated files if you want to change the pg_config.h values. They are in `templates/<default | version>/<common | platform>/*.h`
