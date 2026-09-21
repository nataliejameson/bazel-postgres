# Per-release overlays

Each `<version>/files/` tree is symlinked over the fetched PostgreSQL tarball
by `extension.bzl`, preserving relative paths: `files/BUILD.bazel` becomes the
repository's root BUILD file, `files/src/backend/parser/gram.c` replaces that
path in the archive. `files.manifest` lists what to overlay, because Starlark
can't glob a directory from a module extension.

A tree holds two kinds of file.

**Hand-written** — `BUILD.bazel` and a stub `MODULE.bazel` that exists only
because `rules_cc_autoconf`'s `package_info` reads a version string out of
one. Edit these directly. The build settings and shared starlark they refer
to live in `@postgres_config` (see `config/` at the module root), not here,
so every version shares one set of flags.

**Generated** — everything under `src/`, produced by `scripts/distprep.sh
<version>`. Don't hand-edit; re-run the script.

## Why generated sources are checked in

PostgreSQL 18 dropped `make distprep` when upstream moved to meson, so its
tarballs no longer ship the perl/bison/flex output that 16.x did — no
`gram.c`, no `postgres.bki`, no `sql_help.c`. Running those tools during the
build would put perl, bison and flex on every consumer's critical path.

Generating once and committing is safe because the output is platform-neutral
by design. The values that vary by target are deliberately left unresolved:
`postgres.bki` keeps `FLOAT8PASSBYVAL`, `NAMEDATALEN`, `SIZEOF_POINTER` and
`ALIGNOF_POINTER` as literal tokens that `initdb` rewrites at runtime
(`replace_token`, `src/bin/initdb/initdb.c`), and `schemapg.h` keeps them as C
identifiers the target compiler resolves. See the comment at `genbki.pl:1057`.
Re-running the generators is byte-for-byte reproducible.

16.x tarballs still carry their distprep output, so a 16.x overlay needs only
the hand-written files.

## Adding a release

1. Add it to `versions.bzl` with its tarball sha256.
2. `scripts/distprep.sh <version>`.
3. Copy `files/BUILD.bazel` and `files/MODULE.bazel` from the nearest release
   of the same major version and adjust. Between majors expect real differences: 18 added
   `gen_tabcomplete.pl` and `generate-wait_event_types.pl`, and moved
   `generate-lwlocknames.pl` onto `lwlocklist.h`.
4. Add a `postgres_smoke_test` for it in `postgres_test_builds/BUILD.bazel`.
