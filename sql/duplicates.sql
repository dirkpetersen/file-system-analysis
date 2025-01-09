SELECT 
    a.filename,
    a."parent-inode" AS parent_inode_a,
    b."parent-inode" AS parent_inode_b,
    a.st_size,
    a.st_mtime AS mtime_a,
    b.st_mtime AS mtime_b
FROM '${PWALK_TABLE}' a
JOIN '${PWALK_TABLE}' b
    ON a.filename = b.filename
    AND a.st_size = b.st_size
    AND a."parent-inode" != b."parent-inode"
WHERE a.pw_dirsum = 0  -- Ensure we're only looking at files
    AND b.pw_dirsum = 0
    AND a.filename != '.'  -- Exclude special directory entries
    AND a.filename != '..'
ORDER BY a.filename, a.st_size;
