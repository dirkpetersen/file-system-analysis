SELECT 
    filename, 
    st_size, 
    COUNT(*) as duplicate_count
FROM 
    '${PWALK_TABLE}'
WHERE 
    pw_fcount = -1
GROUP BY 
    filename, 
    st_size
HAVING 
    COUNT(*) > 1;
