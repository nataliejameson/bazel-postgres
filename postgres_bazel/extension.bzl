"""Module extension that fetches PostgreSQL sources and makes them buildable.

    postgres = use_extension("@postgres_bazel//:extension.bzl", "postgres")
    postgres.add_version(version = "18.4")
    use_repo(postgres, "postgres_18_4")

Every version shares one `@postgres_config` repository holding the build
settings, so `--@postgres_config//:with_ssl=boringssl` configures all of them
at once instead of needing the flag repeated per version.

Each version becomes its own repository holding the upstream tarball with a
BUILD file and, for releases that need them, pre-generated sources overlaid on
top. See templates/README.md for why those are checked in.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load(":config_repo.bzl", "postgres_config_repo")
load(":versions.bzl", "VERSIONS")

def _default_repo_name(version):
    return "postgres_" + version.replace(".", "_")

def _overlay(module_ctx, template):
    """Maps every file under templates/<template>/files/ to its archive path.

    The tree mirrors the archive layout, so files/BUILD.bazel becomes the root
    BUILD file and files/src/backend/parser/gram.c replaces that source. The
    manifest lists the paths because Starlark can't glob a directory here.
    """
    manifest = module_ctx.read(Label("//templates:{}/files.manifest".format(template)))
    files = {}
    for line in manifest.splitlines():
        path = line.strip()
        if path:
            files[path] = Label("//templates:{}/files/{}".format(template, path))
    return files

def _postgres_impl(module_ctx):
    # One shared settings repo for every version: with_ssl and friends are
    # build-wide choices, not per-release ones.
    postgres_config_repo(name = "postgres_config")
    created = ["postgres_config"]
    for module in module_ctx.modules:
        for tag in module.tags.add_version:
            name = tag.repo_name or _default_repo_name(tag.version)
            if name in created:
                fail("postgres: repository {} was already declared".format(name))

            if tag.url and not tag.sha256:
                fail("postgres: version {} set url without sha256".format(tag.version))
            if tag.sha256 and not tag.url:
                fail("postgres: version {} set sha256 without url; it is only used with url".format(tag.version))

            known = VERSIONS.get(tag.version)
            if not known and not tag.url:
                fail("postgres: unknown version {}. Known versions: {}. Pass url and sha256 to build one that isn't listed.".format(
                    tag.version,
                    ", ".join(sorted(VERSIONS)),
                ))

            template = tag.template or (known.template if known else tag.version)
            http_archive(
                name = name,
                build_file = None,
                files = _overlay(module_ctx, template),
                sha256 = tag.sha256 or known.sha256,
                strip_prefix = "postgresql-" + tag.version,
                urls = [tag.url or known.url],
            )
            created.append(name)

    return module_ctx.extension_metadata(
        reproducible = True,
        root_module_direct_deps = created,
        root_module_direct_dev_deps = [],
    )

postgres = module_extension(
    implementation = _postgres_impl,
    doc = "Creates one repository per requested PostgreSQL version.",
    tag_classes = {
        "add_version": tag_class(
            doc = "Make a PostgreSQL version available as @postgres_<version>.",
            attrs = {
                "version": attr.string(
                    mandatory = True,
                    doc = "Release to build, e.g. \"18.4\".",
                ),
                "repo_name": attr.string(
                    doc = "Repository name. Defaults to postgres_<version>, dots replaced by underscores.",
                ),
                "url": attr.string(
                    doc = "Tarball URL, overriding the one in versions.bzl. Requires sha256.",
                ),
                "sha256": attr.string(
                    doc = "Tarball sha256. Only used together with url.",
                ),
                "template": attr.string(
                    doc = "Directory under templates/ to overlay. Defaults to the one versions.bzl names for this release.",
                ),
            },
        ),
    },
)
