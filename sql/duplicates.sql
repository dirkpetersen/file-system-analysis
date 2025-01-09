-- Find duplicate files (same name and size) across different folders
WITH FileInfo AS (
    SELECT 
        filename,
        regexp_extract(filename, '[^/]+$') as basename,  -- Extract the filename without path
        st_size,
        "parent-inode"
    FROM '${PWALK_TABLE}'
    WHERE pw_fcount = -1  -- Only include files, not directories
    AND st_size > 0       -- Exclude empty files
),
DuplicateGroups AS (
    SELECT 
        LOWER(basename) as lower_basename,
        st_size,
        COUNT(*) as file_count,
        array_agg("parent-inode") as parent_inodes
    FROM FileInfo
    GROUP BY LOWER(basename), st_size
    HAVING COUNT(*) > 1
)
SELECT 
    ANY_VALUE(f.basename) AS filename,
    d.st_size AS file_size,
    d.file_count AS duplicate_count,
    GROUP_CONCAT(DISTINCT p.filename) AS locations
FROM DuplicateGroups d
JOIN FileInfo f ON LOWER(f.basename) = d.lower_basename AND f.st_size = d.st_size
JOIN '${PWALK_TABLE}' p ON p.inode = ANY(d.parent_inodes)
GROUP BY d.lower_basename, d.st_size, d.file_count
ORDER BY d.st_size DESC, d.lower_basename;
