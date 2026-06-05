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
        "2":  PostgresVersion(pg_version_num ="160002", major ="16", minor = "2", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "3":  PostgresVersion(pg_version_num ="160003", major ="16", minor = "3", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "4":  PostgresVersion(pg_version_num ="160004", major ="16", minor = "4", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "5":  PostgresVersion(pg_version_num ="160005", major ="16", minor = "5", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "6":  PostgresVersion(pg_version_num ="160006", major ="16", minor = "6", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "7":  PostgresVersion(pg_version_num ="160007", major ="16", minor = "7", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "8":  PostgresVersion(pg_version_num ="160008", major ="16", minor = "8", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "9":  PostgresVersion(pg_version_num ="160009", major ="16", minor = "9", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "10": PostgresVersion(pg_version_num ="160010", major ="16", minor = "10", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "11": PostgresVersion(pg_version_num ="160011", major ="16", minor = "11", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "12": PostgresVersion(pg_version_num ="160012", major ="16", minor = "12", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "13": PostgresVersion(pg_version_num ="160013", major ="16", minor = "13", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "14": PostgresVersion(pg_version_num ="160014", major ="16", minor = "14", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
    },
    "17": {
        "0":  PostgresVersion(pg_version_num ="170000", major ="17", minor = "0", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "1":  PostgresVersion(pg_version_num ="170001", major ="17", minor = "1", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "2":  PostgresVersion(pg_version_num ="170002", major ="17", minor = "2", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "3":  PostgresVersion(pg_version_num ="170003", major ="17", minor = "3", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "4":  PostgresVersion(pg_version_num ="170004", major ="17", minor = "4", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "5":  PostgresVersion(pg_version_num ="170005", major ="17", minor = "5", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "6":  PostgresVersion(pg_version_num ="170006", major ="17", minor = "6", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "7":  PostgresVersion(pg_version_num ="170007", major ="17", minor = "7", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "8":  PostgresVersion(pg_version_num ="170008", major ="17", minor = "8", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "9":  PostgresVersion(pg_version_num ="170009", major ="17", minor = "9", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "10": PostgresVersion(pg_version_num ="170010", major ="17", minor = "10", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
    },
    "18": {
        "0":  PostgresVersion(pg_version_num ="180000", major ="18", minor = "0", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "1":  PostgresVersion(pg_version_num ="180001", major ="18", minor = "1", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "2":  PostgresVersion(pg_version_num ="180002", major ="18", minor = "2", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "3":  PostgresVersion(pg_version_num ="180003", major ="18", minor = "3", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
        "4":  PostgresVersion(pg_version_num ="180004", major ="18", minor = "4", sha256 = "07666b903a12a5f0757740f6b77c4dee68d17b4af68595234e3bc7de4414e2ae"),
    },

}
