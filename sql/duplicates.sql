WITH file_paths AS (
    SELECT 
        filename,
        st_size,
        st_mtime,
        pw_dirsum,
        "parent-inode",
        -- Construct full path using parent-inode and filename
        CASE 
            WHEN filename = '' THEN NULL  -- Skip empty filenames
            ELSE regexp_replace('/' || "parent-inode" || '/' || filename, '//+', '/') 
        END AS full_path
    FROM '${PWALK_TABLE}'
)
SELECT 
    a.filename,
    a.st_size,
    a.full_path AS path_a,
    b.full_path AS path_b,
    a.st_mtime AS mtime_a,
    b.st_mtime AS mtime_b
FROM file_paths a
JOIN file_paths b
    ON a.filename = b.filename
    AND a.st_size = b.st_size
    AND a.full_path != b.full_path  -- Ensure different paths
WHERE a.pw_dirsum = 0  -- Ensure we're only looking at files
    AND b.pw_dirsum = 0
    AND a.filename != '.'  -- Exclude special directory entries
    AND a.filename != '..'
    AND a.filename != ''   -- Exclude empty filenames
ORDER BY a.filename, a.st_size;
