-- Find files with unknown user or group ownership
SELECT     
    COALESCE(u.username, 'Unknown') as User,
    p.UID,
    COALESCE(g.groupname, 'Unknown') as Group,
    p.GID,
    strftime(TO_TIMESTAMP(st_mtime), '%Y-%m-%d %H:%M:%S') as ModTime,
    filename
FROM '${PWALK_TABLE}' p
LEFT JOIN 'groups.csv' g ON p.GID = g.GID 
LEFT JOIN 'users.csv' u ON p.UID = u.UID
WHERE (g.groupname = 'Unknown' or u.username = 'Unknown')
ORDER BY st_mtime DESC;
