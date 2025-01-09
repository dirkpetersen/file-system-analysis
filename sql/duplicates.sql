SELECT 
    "parent-inode", 
    "directory-depth", 
    filename, 
    st_size
FROM 
    '${PWALK_TABLE}'
WHERE 
    st_size > 0
GROUP BY 
    filename, st_size
HAVING 
    COUNT(DISTINCT "parent-inode") > 1;
