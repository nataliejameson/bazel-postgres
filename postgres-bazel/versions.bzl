PostgresVersion = provider(
    fields = [
        "pg_version_num",
        "major",
        "minor",
        "sha256",
    ],
)

VERSIONS = {
    "16": {
        "2": PostgresVersion(pg_version_num = "160002", major = "16", minor = "2", sha256 = "2b8201047ec81acd1bad29dba278d788e7891b9c3e8232eda16bb29dec8131c7"),
        "3": PostgresVersion(pg_version_num = "160003", major = "16", minor = "3", sha256 = "bd3798c399bc1b6d08b94340f9dd7a75a30a7fa076788ef2f4848be2be6a5fc5"),
        "4": PostgresVersion(pg_version_num = "160004", major = "16", minor = "4", sha256 = "2e17a90062403e15d6540480fdec50c8b005eb48729a91cb4989ffeb04df193c"),
        "5": PostgresVersion(pg_version_num = "160005", major = "16", minor = "5", sha256 = "dcbf8db1df3348466da999c7e19c6a2225be2263a9034dda87666002e5b251a5"),
        "6": PostgresVersion(pg_version_num = "160006", major = "16", minor = "6", sha256 = "520d173632e93507f26eb66713d953b687cfba5e72c467d3adbc8ec4dbb8148f"),
        "7": PostgresVersion(pg_version_num = "160007", major = "16", minor = "7", sha256 = "717932fe181fb7bdbaffdcfbedb2e6d12edd3fdac15ab217781c619ef7addc75"),
        "8": PostgresVersion(pg_version_num = "160008", major = "16", minor = "8", sha256 = "5f12e4c2a83b3b94437c963803f1e22a59f737a1610d31463fb571715dc07919"),
        "9": PostgresVersion(pg_version_num = "160009", major = "16", minor = "9", sha256 = "df5aaddcf7841457cbf9d31b7d79124a2057cdc7cdae47e8e0271c973546618e"),
        "10": PostgresVersion(pg_version_num = "160010", major = "16", minor = "10", sha256 = "91ede566d6c35db9617a619a5e015c985242144ad27fccae63d11c91cd8c3eed"),
        "11": PostgresVersion(pg_version_num = "160011", major = "16", minor = "11", sha256 = "48c7d6529cad3938af09365c81b9277e8febf1447bd6417efd3533fe4ca8ce3f"),
        "12": PostgresVersion(pg_version_num = "160012", major = "16", minor = "12", sha256 = "ced6f95aa2779d7374b68765591c46d692653b2fe3fb5b845de51292f3f83a92"),
        "13": PostgresVersion(pg_version_num = "160013", major = "16", minor = "13", sha256 = "9b767d0dfd156424b0b8f02b65eebb4b6958ef6413ebf7c8349e28b0b91e6b09"),
        "14": PostgresVersion(pg_version_num = "160014", major = "16", minor = "14", sha256 = "ca18d43510bbb09a271383e1aa705b05b76bc8e9400f9857178ba8ec54cf461a"),
    },
    "17": {
        "0": PostgresVersion(pg_version_num = "170000", major = "17", minor = "0", sha256 = "bf81c0c5161e456a886ede5f1f4133f43af000637e377156a02e7e83569081ad"),
        "1": PostgresVersion(pg_version_num = "170001", major = "17", minor = "1", sha256 = "f4e1a2add2404b7eb7f51c69957f2a960a94e9d609883b79850d996cfd485aa6"),
        "2": PostgresVersion(pg_version_num = "170002", major = "17", minor = "2", sha256 = "51d8cdd6a5220fa8c0a3b12f2d0eeb50fcf5e0bdb7b37904a9cdff5cf1e61c36"),
        "3": PostgresVersion(pg_version_num = "170003", major = "17", minor = "3", sha256 = "0229bb3352126771b89a4abee5930b5dc881870cf23ff0fc8c6cc901cb9d5e56"),
        "4": PostgresVersion(pg_version_num = "170004", major = "17", minor = "4", sha256 = "e69d0714c3a8480c208aadba6c031fb8ce9cf580930c8012bf748c8b5ed11850"),
        "5": PostgresVersion(pg_version_num = "170005", major = "17", minor = "5", sha256 = "730bfef34b03825c051ae0fc37542c8be26b55a44e472369221afd397196e303"),
        "6": PostgresVersion(pg_version_num = "170006", major = "17", minor = "6", sha256 = "2910b85283674da2dae6ac13fe5ebbaaf3c482446396cba32e6728d3cc736d86"),
        "7": PostgresVersion(pg_version_num = "170007", major = "17", minor = "7", sha256 = "4a9e94204e265b292b0b36534c38543f24f9d96f5413ceac489ef053082ae752"),
        "8": PostgresVersion(pg_version_num = "170008", major = "17", minor = "8", sha256 = "b038dadefad54c2a8459eee91736a44319771eec021bf85fed3ce7cf1f77553e"),
        "9": PostgresVersion(pg_version_num = "170009", major = "17", minor = "9", sha256 = "70eaebacf5344a0951075a666369d95d25ae4485ad0d6d3df652065277f4943c"),
        "10": PostgresVersion(pg_version_num = "170010", major = "17", minor = "10", sha256 = "e4b43025f32ea3d271be64365d284c8462cffd41d80db0c3df6fc62417a2d9dc"),
    },
    "18": {
        "0": PostgresVersion(pg_version_num = "180000", major = "18", minor = "0", sha256 = "30e97fc1f1594a7226580ea51080d3d883f4a0fb6ff716dbf7ad09e9f7e93ab2"),
        "1": PostgresVersion(pg_version_num = "180001", major = "18", minor = "1", sha256 = "b0f18c2d6973d2aa023cfc77feda787d7bbe9c31a3977d0f04ac29885fb98ec4"),
        "2": PostgresVersion(pg_version_num = "180002", major = "18", minor = "2", sha256 = "85268ec707b72665ecc88daf5438e84081dc07d9d16326ebf3ef9a5fec9ce1e0"),
        "3": PostgresVersion(pg_version_num = "180003", major = "18", minor = "3", sha256 = "9e054ffd6e013da2c2c9a1bfd6e062c98875d340df080516551c96b9b0926a59"),
        "4": PostgresVersion(pg_version_num = "180004", major = "18", minor = "4", sha256 = "450aa8f2da06c46f8221916e82ae06b04fb1040f8f00643dbf8b7d663caac0b9"),
    },
}
