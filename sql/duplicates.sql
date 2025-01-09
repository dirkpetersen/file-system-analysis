-- Find duplicate files (same filename and size) stored in different folders
WITH file_info AS (
    SELECT 
        substring(filename, length(filename) - strpos(reverse(filename), '/') + 2) AS file_name,
        filename AS full_path,
        st_size,
        pw_fcount
    FROM '${PWALK_TABLE}'
    WHERE pw_fcount = -1  -- Only include files, not directories
    AND st_size > 0      -- Exclude empty files
)
SELECT 
    f1.file_name,
    f1.st_size,
    GROUP_CONCAT(f1.full_path, '\n') AS duplicate_locations,
    COUNT(*) AS occurrence_count
FROM file_info f1
GROUP BY f1.file_name, f1.st_size
HAVING COUNT(*) > 1
ORDER BY f1.st_size DESC, f1.file_name;
