SELECT 
    substring(filename, length(filename) - strpos(reverse(filename), '/') + 2) AS file_name, 
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
