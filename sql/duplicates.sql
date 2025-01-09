SELECT 
    SUBSTRING_INDEX(filename, '/', -1) AS file_name, 
    st_size, 
    COUNT(*) as duplicate_count
FROM 
    '${PWALK_TABLE}'
WHERE 
    pw_fcount = -1
GROUP BY 
    file_name, 
    st_size
HAVING 
    COUNT(*) > 1;
