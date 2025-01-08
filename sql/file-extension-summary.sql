WITH TotalSize AS (
    SELECT SUM(st_size) AS totalSize
    FROM '${PWALK_TABLE}'
)
SELECT
    fileExtension as fileExt,
    ROUND((SUM(st_size) * 100.0 / totalSize), 1) AS pct,
    ROUND((SUM(st_size) / (1024.0 * 1024.0 * 1024.0)), 3) AS GiB
FROM
    '${PWALK_TABLE}',
    TotalSize
GROUP BY
    fileExtension, totalSize
HAVING
    (SUM(st_size) * 100.0 / totalSize) > 0.1
ORDER BY
    pct DESC
LIMIT 100
;
