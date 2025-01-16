-- Find files with unknown group ownership
SELECT 
    u.username as User,
    COALESCE(g.groupname, 'Unknown') as Group,
    strftime(TIMESTAMP_SECONDS(st_mtime), '%Y-%m-%d %H:%M:%S') as ModTime,
    filename
FROM '${PWALK_TABLE}' p
LEFT JOIN 'groups.csv' g ON p.GID = g.GID 
LEFT JOIN 'users.csv' u ON p.UID = u.UID
WHERE g.groupname IS NULL
ORDER BY st_mtime DESC;
