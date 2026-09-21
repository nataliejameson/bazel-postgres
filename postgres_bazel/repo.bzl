"""Repository rule that fetches one PostgreSQL release and makes it buildable.

The tarball is the upstream source, unmodified. On top of it go three things:
the major version's BUILD file, a stub MODULE.bazel (rules_cc_autoconf's
package_info wants a version string from one), and — for 17.x and 18.x, which
no longer ship their distprep output — the pre-generated sources from
templates/<version>/files/.
"""

def _postgres_repo_impl(repository_ctx):
    version = repository_ctx.attr.version

    repository_ctx.download_and_extract(
        url = repository_ctx.attr.url,
        sha256 = repository_ctx.attr.sha256,
        stripPrefix = "postgresql-" + version,
    )

    major, minor = version.split(".")
    # Plain replace, not format(): the BUILD file is full of literal braces
    # (selects, dicts, the shell in genrule cmds) that format() would choke on.
    substitutions = {
        "{major}": major,
        "{minor}": minor,
        "{version}": version,
        # Upstream's PG_VERSION_NUM: major then minor zero-padded to 4.
        "{version_num}": major + ("0" * (4 - len(minor))) + minor,
    }

    def _render(label):
        text = repository_ctx.read(label)
        for old, new in substitutions.items():
            text = text.replace(old, new)
        return text

    repository_ctx.file("BUILD.bazel", _render(repository_ctx.attr.build_file), executable = False)
    repository_ctx.file("MODULE.bazel", _render(repository_ctx.attr.module_file), executable = False)

    # Overwrites whatever the tarball had at these paths, which is the point:
    # for 17.x/18.x nothing is there, and a 16.x tree wouldn't be listed here.
    for path, label in repository_ctx.attr.generated.items():
        repository_ctx.symlink(repository_ctx.path(label), path)

postgres_repo = repository_rule(
    implementation = _postgres_repo_impl,
    doc = "Fetches a PostgreSQL release and overlays its build files.",
    attrs = {
        "build_file": attr.label(mandatory = True, doc = "Major version's BUILD.bazel."),
        "generated": attr.string_keyed_label_dict(
            doc = "Archive-relative path -> pre-generated source to overlay.",
        ),
        "module_file": attr.label(
            mandatory = True,
            doc = "MODULE.bazel template; {version} is substituted.",
        ),
        "sha256": attr.string(mandatory = True),
        "url": attr.string(mandatory = True),
        "version": attr.string(mandatory = True, doc = "Release, e.g. \"18.4\"."),
    },
)
