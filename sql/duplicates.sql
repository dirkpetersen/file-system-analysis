SELECT 
    filename,
    st_size,
    COUNT(*) AS duplicate_count
FROM 
    '${PWALK_TABLE}'
WHERE 
    pw_dirsum = 0  -- Ensure it's a file, not a directory
GROUP BY 
    filename, st_size
HAVING 
    COUNT(*) > 1
ORDER BY 
    filename, st_size;
