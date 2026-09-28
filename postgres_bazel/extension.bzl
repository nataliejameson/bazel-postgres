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

load(":config_repo.bzl", "postgres_config_repo")
load(":default_repo.bzl", "postgres_default_repo")
load(":repo.bzl", "postgres_repo")
load(":versions.bzl", "VERSIONS")

def _default_repo_name(version):
    return "postgres_" + version.replace(".", "_")

def _generated_files(module_ctx, version):
    """Per-minor generated sources, or {} for releases that ship their own.

    16.x tarballs still carry their distprep output; 17.x and 18.x don't, so
    those versions get a templates/<version>/files/ tree. See
    templates/README.md.
    """
    manifest_label = Label("//templates:{}/files.manifest".format(version))
    if not module_ctx.path(manifest_label).exists:
        return {}

    files = {}
    for line in module_ctx.read(manifest_label).splitlines():
        path = line.strip()
        if path:
            files[path] = Label("//templates:{}/files/{}".format(version, path))
    return files

def _postgres_impl(module_ctx):
    # One shared settings repo for every version: with_ssl and friends are
    # build-wide choices, not per-release ones.
    postgres_config_repo(name = "postgres_config")
    created = ["postgres_config"]
    repo_for_version = {}
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

            major = tag.template or (known.major if known else tag.version.split(".")[0])
            postgres_repo(
                name = name,
                build_file = Label("//templates:major/{}/BUILD.bazel".format(major)),
                module_file = Label("//templates:major/{}/MODULE.bazel.template".format(major)),
                generated = _generated_files(module_ctx, tag.version),
                sha256 = tag.sha256 or known.sha256,
                url = tag.url or known.url,
                version = tag.version,
            )
            created.append(name)
            repo_for_version.setdefault(tag.version, name)

    for module in module_ctx.modules:
        for tag in module.tags.default_version:
            if tag.repo_name in created:
                fail("postgres: repository {} was already declared".format(tag.repo_name))
            if tag.version not in repo_for_version:
                fail("postgres: default_version {} has no matching add_version. Added versions: {}".format(
                    tag.version,
                    ", ".join(sorted(repo_for_version)),
                ))
            postgres_default_repo(
                name = tag.repo_name,
                target_repo = repo_for_version[tag.version],
            )
            created.append(tag.repo_name)

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
                    doc = "Major-version BUILD template to use, e.g. \"18\". Defaults to this release's own major.",
                ),
            },
        ),
        "default_version": tag_class(
            doc = "Alias an added version's targets under an unversioned repository name.",
            attrs = {
                "version": attr.string(
                    mandatory = True,
                    doc = "A version also passed to add_version, e.g. \"18.4\".",
                ),
                "repo_name": attr.string(
                    default = "postgres",
                    doc = "Repository name for the aliases.",
                ),
            },
        ),
    },
)
