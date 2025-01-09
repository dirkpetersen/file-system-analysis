WITH RECURSIVE path_builder AS (
    SELECT 
        filename,
        st_size,
        st_mtime,
        pw_dirsum,
        "parent-inode",
        filename AS full_path,
        inode
    FROM '${PWALK_TABLE}'
    WHERE "parent-inode" = 0  -- Start with root directories
    
    UNION ALL
    
    SELECT 
        f.filename,
        f.st_size,
        f.st_mtime,
        f.pw_dirsum,
        f."parent-inode",
        regexp_replace(pb.full_path || '/' || f.filename, '//+', '/'),
        f.inode
    FROM '${PWALK_TABLE}' f
    JOIN path_builder pb
        ON f."parent-inode" = pb.inode
),
file_paths AS (
    SELECT 
        filename,
        st_size,
        st_mtime,
        pw_dirsum,
        "parent-inode",
        full_path
    FROM path_builder
    WHERE filename != ''  -- Skip empty filenames
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
