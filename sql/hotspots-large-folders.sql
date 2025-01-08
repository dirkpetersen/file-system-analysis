WITH CurrentDay AS (
    SELECT CAST(EXTRACT(EPOCH FROM CURRENT_TIMESTAMP) AS INTEGER) AS currentUnixTimestamp
)

SELECT
    UID as User,
    CAST(ROUND((CurrentDay.currentUnixTimestamp - st_atime) / 86400) AS INTEGER) as AccD,
    CAST(ROUND((CurrentDay.currentUnixTimestamp - st_mtime) / 86400) AS INTEGER) as ModD,
    ROUND(pw_dirsum / 1024 / 1024 / 1024, 3) as GiB,
    ROUND((pw_dirsum / 1024 / 1024) / pw_fcount, 3) as MiBAvg,
    filename as Folder,
    GID as Group,
    ROUND(pw_dirsum / 1024 / 1024 / 1024 / 1024, 3) as TiB,
    pw_fcount as FileCount,
    pw_dirsum as DirSize
FROM
    "${PWALK_TABLE}",
    CurrentDay
WHERE
    pw_fcount > -1 AND
    pw_dirsum > 0 AND
    AccD > 365
ORDER BY
    pw_dirsum DESC
LIMIT 1000;

