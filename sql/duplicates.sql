-- Find duplicate files with same name and size in different folders
WITH FileGroups AS (
  SELECT 
    filename,
    st_size,
    COUNT(*) as instances,
    GROUP_CONCAT(DISTINCT parent_inode) as locations
  FROM read_csv_auto('*.csv')
  WHERE pw_fcount = -1  -- Only look at files, not directories
  GROUP BY filename, st_size
  HAVING COUNT(*) > 1   -- Only show files that appear more than once
)
SELECT 
  f.filename,
  f.st_size,
  f.instances as duplicate_count,
  f.locations as parent_inodes,
  GROUP_CONCAT(DISTINCT p.filename) as parent_folders
FROM FileGroups f
JOIN read_csv_auto('*.csv') c ON c.inode::VARCHAR IN (string_split_regex(f.locations, ','))
JOIN read_csv_auto('*.csv') p ON p.inode = c.parent_inode
ORDER BY f.st_size DESC, f.filename;
