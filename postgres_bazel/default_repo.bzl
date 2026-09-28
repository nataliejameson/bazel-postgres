"""A repository of aliases pointing at one versioned postgres repository."""

def _postgres_default_repo_impl(repository_ctx):
    template = repository_ctx.read(repository_ctx.attr._build_file)
    repository_ctx.file("BUILD.bazel", template.replace("{repo}", repository_ctx.attr.target_repo))

postgres_default_repo = repository_rule(
    implementation = _postgres_default_repo_impl,
    doc = "Aliases every public target of a versioned postgres repository.",
    attrs = {
        "target_repo": attr.string(mandatory = True, doc = "Apparent name of the versioned repository."),
        "_build_file": attr.label(default = "//templates:default/BUILD.bazel.template"),
    },
)
