SELECT 
    substring(filename, length(filename) - strpos(reverse(filename), '/') + 2) AS file_name, 
    st_size, 
    COUNT(*) AS duplicate_count
FROM 
    '${PWALK_TABLE}'
GROUP BY 
    file_name, 
    st_size
HAVING 
    duplicate_count > 1;
