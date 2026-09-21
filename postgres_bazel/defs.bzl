"""Test helpers consumers can run against any version this module builds."""

load("@rules_shell//shell:sh_test.bzl", "sh_test")

def postgres_smoke_test(name, repo, version, **kwargs):
    """initdb a cluster, start it, query it through psql, shut it down.

    Args:
      name: target name.
      repo: the postgres repository to exercise, e.g. "@postgres_18_4".
      version: version the server is expected to report, e.g. "18.4".
      **kwargs: passed through to the underlying sh_test.
    """
    sh_test(
        name = name,
        size = kwargs.pop("size", "large"),
        srcs = ["@postgres_bazel//:smoke_test.sh"],
        args = [version] + [
            "$(rlocationpath {}//:{}_bin)".format(repo, b)
            for b in ["initdb", "pg_ctl", "psql"]
        ],
        data = ["{}//:{}_bin".format(repo, b) for b in ["initdb", "pg_ctl", "psql"]],
        deps = ["@bazel_tools//tools/bash/runfiles"],
        **kwargs
    )
