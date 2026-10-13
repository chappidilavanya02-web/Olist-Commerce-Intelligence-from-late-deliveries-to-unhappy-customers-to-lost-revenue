/* 
step 4: Null and blank profile (every column, every table)
 Purpose: for every column in every table (dbo schema), record
         - data type
         - total rows
         - NULL count
         - blank-string count (text columns only)
         - distinct value count
         then report the percentage of missing values per column.
Method:  dynamic SQL. The script builds one INSERT statement per column as text,
         then runs all of them at once. 
 */
use OlistDB;
GO

--creating temporory table #profile for holding profiling result & drop table if any existing temperory table present 
--# means it wxists only for this session 
IF OBJECT_ID('tempdb..#profile') IS NOT NULL DROP TABLE #profile;

--temporary table with 7 columns
CREATE TABLE #profile (
    table_name sysname,
    column_name sysname, 
    data_type sysname,
    total_rows bigint, 
    null_count bigint, 
    blank_count bigint, 
    distinct_count bigint
);
-- declaring a variable @SQL 
--this variable is used to hold the sql commands in form of text build by this script 
--N'' means an empty Unicode string
DECLARE @sql nvarchar(max) = N'';

--building sql text and this SELECT runs once per column 
--and each time it adds one INSERT statement to @sql
-- Note: '''' inside an N'...' string produces one literal quote mark in the generated SQL.
SELECT @sql = @sql
  + N'INSERT INTO #profile SELECT ''' 
  + c.TABLE_NAME 
  + N''',''' 
  + c.COLUMN_NAME
  + N''',''' 
  + c.DATA_TYPE 
  + N''', COUNT(*),'           --total rows 
--NUll count add 1 for every row where the column is NULL
  + N'SUM(
            CASE WHEN ' + QUOTENAME(c.COLUMN_NAME) + N' IS NULL
             THEN 1 
             ELSE 0 
             END
         ),'
 -- Blank count: only text columns can hold blank strings.
 -- For text columns, count rows that are empty after trimming spaces.
 -- For all other data types, write 0.
  + CASE WHEN c.DATA_TYPE IN ('varchar','nvarchar','char','nchar')
         THEN N'SUM(CASE WHEN LTRIM(RTRIM(' + QUOTENAME(c.COLUMN_NAME) + N')) = '''' 
                    THEN 1 
                    ELSE 0 
                    END
                    )'
         ELSE N'0' 
         END
  + N', COUNT(DISTINCT ' + QUOTENAME(c.COLUMN_NAME) + N') FROM '
  + QUOTENAME(c.TABLE_SCHEMA) + N'.' + QUOTENAME(c.TABLE_NAME) + N';' + CHAR(10)
 -- QUOTENAME adds [brackets] so unusual names do not break the generated SQL.
-- CHAR(10) adds a new line between statements so the generated text is readable.


FROM INFORMATION_SCHEMA.COLUMNS AS c
JOIN INFORMATION_SCHEMA.TABLES AS t
  ON t.TABLE_SCHEMA = c.TABLE_SCHEMA AND t.TABLE_NAME = c.TABLE_NAME
WHERE t.TABLE_TYPE = 'BASE TABLE' AND c.TABLE_SCHEMA = 'dbo';

PRINT @sql;

--Run all the generated INSERT statements.
EXEC sp_executesql @sql;

SELECT table_name, 
       column_name, 
       data_type, 
       total_rows, 
       null_count, 
       blank_count,
       CAST(100.0 * (null_count + blank_count) / NULLIF(total_rows, 0) AS decimal(5,2)) AS missing_pct, --calculating the missing values percentage 
       distinct_count
FROM #profile
ORDER BY table_name, missing_pct DESC;
