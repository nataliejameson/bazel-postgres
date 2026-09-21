"""Known PostgreSQL source releases.

Each entry pins the upstream tarball and names the major version whose BUILD
template gets overlaid onto it.

A release needs two things to build: `templates/major/<major>/`, shared by
every release of that major version, and `templates/<version>/files/`, the
sources upstream doesn't ship. `scripts/distprep.sh <version>` produces the
latter.
"""

PostgresVersion = provider(
    doc = "Upstream source location for one PostgreSQL release.",
    fields = {
        "major": "Major version, e.g. \"18\".",
        "minor": "Minor version, e.g. \"4\".",
        "sha256": "sha256 of the tarball.",
        "template": "Major version whose BUILD template to use.",
        "url": "Tarball URL.",
    },
)

def _pg(major, minor, sha256, template = None):
    version = "{}.{}".format(major, minor)
    return PostgresVersion(
        major = major,
        minor = minor,
        sha256 = sha256,
        template = template or major,
        url = "https://ftp.postgresql.org/pub/source/v{v}/postgresql-{v}.tar.gz".format(v = version),
    )

VERSIONS = {
    "16.2": _pg("16", "2", "2b8201047ec81acd1bad29dba278d788e7891b9c3e8232eda16bb29dec8131c7"),
    "16.3": _pg("16", "3", "bd3798c399bc1b6d08b94340f9dd7a75a30a7fa076788ef2f4848be2be6a5fc5"),
    "16.4": _pg("16", "4", "2e17a90062403e15d6540480fdec50c8b005eb48729a91cb4989ffeb04df193c"),
    "16.5": _pg("16", "5", "dcbf8db1df3348466da999c7e19c6a2225be2263a9034dda87666002e5b251a5"),
    "16.6": _pg("16", "6", "520d173632e93507f26eb66713d953b687cfba5e72c467d3adbc8ec4dbb8148f"),
    "16.7": _pg("16", "7", "717932fe181fb7bdbaffdcfbedb2e6d12edd3fdac15ab217781c619ef7addc75"),
    "16.8": _pg("16", "8", "5f12e4c2a83b3b94437c963803f1e22a59f737a1610d31463fb571715dc07919"),
    "16.9": _pg("16", "9", "df5aaddcf7841457cbf9d31b7d79124a2057cdc7cdae47e8e0271c973546618e"),
    "16.10": _pg("16", "10", "91ede566d6c35db9617a619a5e015c985242144ad27fccae63d11c91cd8c3eed"),
    "16.11": _pg("16", "11", "48c7d6529cad3938af09365c81b9277e8febf1447bd6417efd3533fe4ca8ce3f"),
    "16.12": _pg("16", "12", "ced6f95aa2779d7374b68765591c46d692653b2fe3fb5b845de51292f3f83a92"),
    "16.13": _pg("16", "13", "9b767d0dfd156424b0b8f02b65eebb4b6958ef6413ebf7c8349e28b0b91e6b09"),
    "16.14": _pg("16", "14", "ca18d43510bbb09a271383e1aa705b05b76bc8e9400f9857178ba8ec54cf461a"),
    "17.0": _pg("17", "0", "bf81c0c5161e456a886ede5f1f4133f43af000637e377156a02e7e83569081ad"),
    "17.1": _pg("17", "1", "f4e1a2add2404b7eb7f51c69957f2a960a94e9d609883b79850d996cfd485aa6"),
    "17.2": _pg("17", "2", "51d8cdd6a5220fa8c0a3b12f2d0eeb50fcf5e0bdb7b37904a9cdff5cf1e61c36"),
    "17.3": _pg("17", "3", "0229bb3352126771b89a4abee5930b5dc881870cf23ff0fc8c6cc901cb9d5e56"),
    "17.4": _pg("17", "4", "e69d0714c3a8480c208aadba6c031fb8ce9cf580930c8012bf748c8b5ed11850"),
    "17.5": _pg("17", "5", "730bfef34b03825c051ae0fc37542c8be26b55a44e472369221afd397196e303"),
    "17.6": _pg("17", "6", "2910b85283674da2dae6ac13fe5ebbaaf3c482446396cba32e6728d3cc736d86"),
    "17.7": _pg("17", "7", "4a9e94204e265b292b0b36534c38543f24f9d96f5413ceac489ef053082ae752"),
    "17.8": _pg("17", "8", "b038dadefad54c2a8459eee91736a44319771eec021bf85fed3ce7cf1f77553e"),
    "17.9": _pg("17", "9", "70eaebacf5344a0951075a666369d95d25ae4485ad0d6d3df652065277f4943c"),
    "17.10": _pg("17", "10", "e4b43025f32ea3d271be64365d284c8462cffd41d80db0c3df6fc62417a2d9dc"),
    "18.0": _pg("18", "0", "30e97fc1f1594a7226580ea51080d3d883f4a0fb6ff716dbf7ad09e9f7e93ab2"),
    "18.1": _pg("18", "1", "b0f18c2d6973d2aa023cfc77feda787d7bbe9c31a3977d0f04ac29885fb98ec4"),
    "18.2": _pg("18", "2", "85268ec707b72665ecc88daf5438e84081dc07d9d16326ebf3ef9a5fec9ce1e0"),
    "18.3": _pg("18", "3", "9e054ffd6e013da2c2c9a1bfd6e062c98875d340df080516551c96b9b0926a59"),
    "18.4": _pg("18", "4", "450aa8f2da06c46f8221916e82ae06b04fb1040f8f00643dbf8b7d663caac0b9"),
}
