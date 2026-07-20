load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load(":versions.bzl", "VERSIONS")


def _create_repo(module_ctx, name, pg_version_num, major, minor, url, sha256, build_template, config_templates, patches):
    build_tpl = module_ctx.read(build_template)
    build_bazel = build_tpl.replace(
        '%%{repo_pg_version_num}', pg_version_num
    ).replace(
        '%%{repo_major}', major
    ).replace(
        '%%{repo_minor}', minor
    )
    http_archive(
        name = name,
        strip_prefix = "postgresql-{major}.{minor}".format(major = major, minor = minor),
        urls = [url],
        sha256 = sha256,
        build_file_content = build_bazel,
        patch_strip = 1,
        patches = patches,
        files = config_templates,
    )


def _postgres_impl(module_ctx):
    created_repos = []
    for module in module_ctx.modules:
        if module.is_root:
            for tag in module.tags.version:
                if tag.major not in VERSIONS:
                    fail("Major version {} was not found".format(tag.major))
                if tag.minor not in VERSIONS[tag.major]:
                    fail("Minor version {}.{} was not found".format(tag.major, tag.minor))

                version_info = VERSIONS[tag.major][tag.minor]
                pg_version_num = tag.pg_version_num or version_info.pg_version_num
                major = tag.major or version_info.major
                minor = tag.minor or version_info.minor

                if tag.tarball_url and not tag.sha256:
                    fail("Major version {}.{} specified a tarball_url, but did not specify a sha256".format(major, minor))
                elif not tag.tarball_url and tag.sha256:
                    fail("Major version {}.{} did not specify a tarball_url, but did specify a sha256. sha256 is only used when tarball_url is set".format(major, minor))

                # e.g. https://ftp.postgresql.org/pub/source/v16.3/postgresql-16.3.tar.gz
                url = tag.tarball_url or "https://ftp.postgresql.org/pub/source/v{major}.{minor}/postgresql-{major}.{minor}.tar.gz".format(
                    major = major,
                    minor = minor,
                )

                sha256 = tag.sha256 or version_info.sha256
                name = tag.repo_name or "postgres_{}_{}".format(major, minor)

                if name in created_repos:
                    fail("Repo {} was already defined".format(name))
                _create_repo(
                    module_ctx,
                    name = name,
                    pg_version_num = pg_version_num,
                    major = major,
                    minor = minor,
                    url = url,
                    sha256 = sha256,
                    build_template = tag._build_template,
                    config_templates = tag._config_templates,
                    patches = tag._patches,
                )
                created_repos.append(name)
    return module_ctx.extension_metadata(reproducible = True, root_module_direct_deps = created_repos, root_module_direct_dev_deps = [])

postgres = module_extension(
    implementation = _postgres_impl,
    doc = "Create a postgres repository for a given major and minor revision, to be built by Bazel. By default, libpq is accessible at @postgres_<major>_<minor>//:libpq, and is a standard cc_library",
    tag_classes = {
        "version": tag_class(attrs = {
            "repo_name": attr.string(doc =  "The repository name to expose this version as. Defaults to postgres_<major>_<minor>"),
            "pg_version_num": attr.string(doc =  "The integer version number for this major/minor combination. Defaults to pulling from //:versions.bzl"),
            "major": attr.string(mandatory = True, doc =  "The major version of postgres to use. Must be present in //:versions.bzl"),
            "minor": attr.string(mandatory = True, doc =  "The minor version of postgres to use. Must be present in //:versions.bzl"),
            "tarball_url": attr.string(doc =  "Override the URL to download from. If set, sha256 *must* be set. Otherwise, ftp.postgresql.org will be used, and the sha256 will be pulled from //:versions.bzl"),
            "sha256": attr.string(doc =  "The sha256 of the postgres tarball to download. Only used if tarball_url is set"),
            "_build_template": attr.label(default = "//:BUILD.bazel.template"),
            "_config_templates": attr.string_keyed_label_dict(default ={
                "templates/default/macos-aarch64/pg_config.h": "//:templates/default/macos-aarch64/pg_config.h",
                "templates/default/linux-x86_64/pg_config.h": "//:templates/default/linux-x86_64/pg_config.h",
                "templates/default/linux-aarch64/pg_config.h": "//:templates/default/linux-aarch64/pg_config.h",
                "templates/default/common/pg_config_ext.h": "//:templates/default/common/pg_config_ext.h",
                "templates/default/common/pg_config_paths.h": "//:templates/default/common/pg_config_paths.h",
            }),
            "_patches": attr.label_list(default = ["//:postgres_chklocale.patch"]),
        }),
    },
)
