"""The @postgres_config repository: build settings shared by all versions."""

_FILES = {
    "BUILD.bazel": "//config:BUILD.bazel.template",
    "dist.bzl": "//config:dist.bzl",
    "private/BUILD.bazel": "//config:private/BUILD.bazel.template",
    "private/curl_ssl_transition.bzl": "//config:private/curl_ssl_transition.bzl",
}

def _postgres_config_repo_impl(repository_ctx):
    for dest, src in _FILES.items():
        repository_ctx.file(dest, repository_ctx.read(Label(src)))

postgres_config_repo = repository_rule(
    implementation = _postgres_config_repo_impl,
    doc = "Holds the flags and config_settings every postgres version selects on.",
)
