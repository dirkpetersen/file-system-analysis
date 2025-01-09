-- Find duplicate files (same name and size in different locations)
WITH FileInfo AS (
    SELECT 
        inode,
        filename,
        st_size,
        parent_inode,
        pw_dirsum
    FROM '${PWALK_TABLE}'
    WHERE pw_dirsum = 0  -- Only actual files, not directories
)
SELECT 
    a.filename AS filename,
    a.st_size AS file_size,
    COUNT(*) AS duplicate_count,
    GROUP_CONCAT(DISTINCT a.parent_inode) AS parent_inodes
FROM FileInfo a
JOIN FileInfo b ON 
    a.filename = b.filename AND 
    a.st_size = b.st_size AND
    a.inode != b.inode  -- Exclude same file (same inode)
GROUP BY 
    a.filename,
    a.st_size
HAVING 
    COUNT(*) > 1
ORDER BY 
    a.st_size DESC,
    a.filename;
