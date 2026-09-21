"""Rule for assembling a runnable PostgreSQL installation tree."""

def _directory_output_impl(ctx):
    out = ctx.actions.declare_directory(ctx.attr.dirname or ctx.label.name)
    cmd = ctx.expand_location(
        ctx.attr.cmd,
        targets = ctx.attr.srcs + ctx.attr.tools,
    ).replace("{out}", out.path)
    ctx.actions.run_shell(
        inputs = depset(ctx.files.srcs),
        tools = ctx.files.tools,
        outputs = [out],
        command = cmd,
        use_default_shell_env = True,
        progress_message = "Assembling %s" % ctx.label.name,
    )
    return [DefaultInfo(files = depset([out]), runfiles = ctx.runfiles(files = [out]))]

directory_output = rule(
    implementation = _directory_output_impl,
    doc = """Runs a shell command that populates one output directory.

`cmd` is $(location)-expanded over srcs+tools, and `{out}` is replaced with
the output directory path.""",
    attrs = {
        "cmd": attr.string(mandatory = True),
        "dirname": attr.string(),
        "srcs": attr.label_list(allow_files = True),
        "tools": attr.label_list(allow_files = True, cfg = "exec"),
    },
)
