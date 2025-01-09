-- Find duplicate files (same filename and size) stored in different folders
WITH FileInfo AS (
  SELECT 
    substring(filename, length(filename) - strpos(reverse(filename), '/') + 2) AS file_name,
    filename AS full_path,
    st_size,
    "directory-depth"
  FROM '${PWALK_TABLE}'
  WHERE pw_fcount = -1  -- Only include files, not directories
    AND st_size > 0     -- Exclude empty files
)
SELECT 
  f1.file_name,
  f1.st_size,
  COUNT(*) as duplicate_count,
  GROUP_CONCAT(f1.full_path, '\n') as file_locations
FROM FileInfo f1
GROUP BY f1.file_name, f1.st_size
HAVING COUNT(*) > 1
ORDER BY f1.st_size DESC, f1.file_name;
