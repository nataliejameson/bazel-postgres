"""Known PostgreSQL source releases.

Each entry pins the upstream tarball and names the directory under
`templates/` whose BUILD file and pre-generated sources get overlaid onto it.

Only versions with a matching `templates/` directory belong here: without one
the fetched tarball has no BUILD file and nothing to build. Adding a release
means running `scripts/distprep.sh <version>` and committing what it produces.
"""

PostgresVersion = provider(
    doc = "Upstream source location for one PostgreSQL release.",
    fields = {
        "major": "Major version, e.g. \"18\".",
        "minor": "Minor version, e.g. \"4\".",
        "sha256": "sha256 of the tarball.",
        "template": "Directory under templates/ to overlay.",
        "url": "Tarball URL.",
    },
)

def _pg(major, minor, sha256, template = None):
    version = "{}.{}".format(major, minor)
    return PostgresVersion(
        major = major,
        minor = minor,
        sha256 = sha256,
        template = template or version,
        url = "https://ftp.postgresql.org/pub/source/v{v}/postgresql-{v}.tar.gz".format(v = version),
    )

VERSIONS = {
    "18.4": _pg("18", "4", "450aa8f2da06c46f8221916e82ae06b04fb1040f8f00643dbf8b7d663caac0b9"),
}
