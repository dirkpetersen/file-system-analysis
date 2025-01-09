SELECT 
    "filename", 
    st_size, 
    COUNT(*) AS duplicate_count
FROM 
    '${PWALK_TABLE}'
GROUP BY 
    "filename", 
    st_size
HAVING 
    COUNT(*) > 1;
