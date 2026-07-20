load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load(":versions.bzl", "VERSIONS")


def _create_repo(module_ctx, name, pg_version_num, major, minor, sha256, build_template, config_templates, patches):
    # e.g. https://ftp.postgresql.org/pub/source/v16.3/postgresql-16.3.tar.gz
    url = "https://ftp.postgresql.org/pub/source/v{major}.{minor}/postgresql-{major}.{minor}.tar.gz".format(
        major = major,
        minor = minor,
    )
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
                sha256 = tag.sha256 or version_info.sha256
                name = tag.name or "postgres_{}_{}".format(major, minor)

                if name in created_repos:
                    fail("Repo {} was already defined".format(name))
                _create_repo(
                    module_ctx,
                    name = name,
                    pg_version_num = pg_version_num,
                    major = major,
                    minor = minor,
                    sha256 = sha256,
                    build_template = tag.build_template,
                    config_templates = tag.config_templates,
                    patches = tag.patches,
                )
                created_repos.append(name)
    return module_ctx.extension_metadata(reproducible = True, root_module_direct_deps = created_repos, root_module_direct_dev_deps = [])

postgres = module_extension(
    implementation = _postgres_impl,
    tag_classes = {
        "version": tag_class(attrs = {
            "name": attr.string(),
            "pg_version_num": attr.string(),
            "major": attr.string(mandatory = True),
            "minor": attr.string(mandatory = True),
            "sha256": attr.string(),
            "build_template": attr.label(default = "//:BUILD.bazel.template"),
            "config_templates": attr.string_keyed_label_dict(default ={
                "templates/default/macos-aarch64/pg_config.h": "//:templates/default/macos-aarch64/pg_config.h",
                "templates/default/linux-x86_64/pg_config.h": "//:templates/default/linux-x86_64/pg_config.h",
                "templates/default/linux-aarch64/pg_config.h": "//:templates/default/linux-aarch64/pg_config.h",
                "templates/default/common/pg_config_ext.h": "//:templates/default/common/pg_config_ext.h",
                "templates/default/common/pg_config_paths.h": "//:templates/default/common/pg_config_paths.h",
            }),
            "patches": attr.label_list(default = ["//:postgres_chklocale.patch"]),
        }),
    },
)
