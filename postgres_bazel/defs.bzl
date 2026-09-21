"""Test helpers consumers can run against any version this module builds."""

load("@rules_shell//shell:sh_test.bzl", "sh_test")

def postgres_smoke_test(name, dist, version, **kwargs):
    """initdb a cluster, start it, query it through psql, shut it down.

    Args:
      name: target name.
      dist: the `:pg_dist` target of a postgres repo, e.g. `@postgres_18_4//:pg_dist`.
      version: version string the server is expected to report, e.g. "18.4".
      **kwargs: passed through to the underlying sh_test.
    """
    sh_test(
        name = name,
        size = kwargs.pop("size", "large"),
        srcs = ["@postgres_bazel//:smoke_test.sh"],
        args = ["$(rlocationpath {})".format(dist), version],
        data = [dist],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        **kwargs
    )
