SELECT 
    filename AS full_path,
    substring(filename, length(filename) - strpos(reverse(filename), '/') + 2) AS file_name,
    st_size
FROM '${PWALK_TABLE}'
WHERE pw_dirsum = 0  -- Only files, not directories
GROUP BY 
    substring(filename, length(filename) - strpos(reverse(filename), '/') + 2),
    st_size
HAVING COUNT(*) > 1
ORDER BY st_size DESC;
