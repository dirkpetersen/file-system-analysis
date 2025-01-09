-- Find duplicate files (same name and size) across different folders
WITH FileInfo AS (
    SELECT 
        filename,
        st_size,
        "parent-inode",
        pw_dirsum,
        pw_fcount
    FROM '${PWALK_TABLE}'
    WHERE pw_fcount = -1  -- Only include files, not directories
    AND st_size > 0       -- Exclude empty files
)
SELECT 
    f1.filename AS filename,
    f1.st_size AS file_size,
    COUNT(*) AS duplicate_count,
    GROUP_CONCAT(DISTINCT p.filename) AS locations
FROM FileInfo f1
JOIN '${PWALK_TABLE}' p ON f1."parent-inode" = p.inode
WHERE EXISTS (
    SELECT 1 
    FROM FileInfo f2 
    WHERE f1.filename = f2.filename 
    AND f1.st_size = f2.st_size 
    AND f1."parent-inode" != f2."parent-inode"
)
GROUP BY f1.filename, f1.st_size
HAVING COUNT(*) > 1
ORDER BY f1.st_size DESC, f1.filename;
