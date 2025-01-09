-- Find duplicate files (same name and size) across different folders
WITH FileInfo AS (
    SELECT 
        filename,
        regexp_extract(filename, '[^/]+$') as basename,  -- Extract the filename without path
        st_size,
        "parent-inode"
    FROM '${PWALK_TABLE}'
    WHERE pw_fcount = -1  -- Only include files, not directories
)
SELECT 
    LOWER(basename) AS filename,
    st_size AS file_size,
    COUNT(DISTINCT "parent-inode") AS duplicate_count,
    GROUP_CONCAT(DISTINCT filename) AS locations
FROM FileInfo
GROUP BY LOWER(basename), st_size
HAVING COUNT(DISTINCT "parent-inode") > 1
ORDER BY st_size DESC, filename;
