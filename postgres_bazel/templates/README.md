# Per-release overlays

Two layers get overlaid onto the fetched tarball.

`major/<n>/` holds the BUILD file and MODULE.bazel stub shared by every
release of that major version. Version numbers in them are placeholders
(`{major}`, `{minor}`, `{version}`, `{version_num}`) that `repo.bzl`
substitutes at fetch time — get that wrong and initdb rejects its own
postgres.bki for belonging to the wrong release.

`<version>/files/` holds the per-release generated sources, mirroring the
archive layout, with `files.manifest` listing them because Starlark can't glob
a directory from a module extension.

Edit `major/<n>/BUILD.bazel` directly. The build settings and shared starlark
it refers to live in `@postgres_config` (see `config/` at the module root), so
every version shares one set of flags. Everything under `<version>/files/` is
produced by `scripts/distprep.sh <version>` — don't hand-edit it.

## Why generated sources are checked in

PostgreSQL 17 dropped `make distprep` when upstream moved to meson, and 18
kept it that way, so those tarballs no longer ship the perl/bison/flex output
that 16.x does — no `gram.c`, no `postgres.bki`, no `sql_help.c`. Running
those tools during the build would put perl, bison and flex on every
consumer's critical path.

Generating once and committing is safe because the output is platform-neutral
by design. The values that vary by target are deliberately left unresolved:
`postgres.bki` keeps `FLOAT8PASSBYVAL`, `NAMEDATALEN`, `SIZEOF_POINTER` and
`ALIGNOF_POINTER` as literal tokens that `initdb` rewrites at runtime
(`replace_token`, `src/bin/initdb/initdb.c`), and `schemapg.h` keeps them as C
identifiers the target compiler resolves. See the comment at `genbki.pl:1057`.
Re-running the generators is byte-for-byte reproducible.

16.x tarballs still carry most of their distprep output, but only under
`src/backend`; the build expects it under `src/include` too, which upstream
arranges with symlinks. `distprep.sh` copies those across rather than
regenerating, so a 16.x tree is ~72 files of copies plus `probes.h`, which no
release ships.

Per-release cost in git is small: between two minors of the same major only a
handful of files actually differ (for 18.0 vs 18.4 it's four), so the rest
dedupe away.

## Adding a release

1. Add it to `versions.bzl` with its tarball sha256.
2. `scripts/distprep.sh <version>`.
3. If it opens a new major version, copy `templates/major/<n>/` from the
   nearest one and adjust. Between majors expect real differences: 18 added
   `gen_tabcomplete.pl` and `generate-wait_event_types.pl`, and moved
   `generate-lwlocknames.pl` onto `lwlocklist.h`.
4. Add a `postgres_smoke_test` for it in `postgres_test_builds/BUILD.bazel`.
