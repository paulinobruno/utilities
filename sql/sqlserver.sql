-- List indexes with its tables and indexed columns
WITH all_indexes AS(
  SELECT
    i.name index_name, i.is_primary_key, i.is_unique_constraint, i.is_unique,
    t.name table_name,
    ic.index_column_id column_order,
    c.name column_name
  FROM sys.indexes i
    JOIN sys.tables t ON i.object_id = t.object_id
    JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
    JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
)
SELECT INDEX_name, is_primary_key, is_unique, column_order, column_name
FROM all_indexes
WHERE table_name = :1 -- table-name
ORDER BY index_name ASC, column_order ASC;

-- List indexes and its fragmentation percentage
SELECT b.name index_name, a.index_type_desc, a.avg_fragmentation_in_percent
FROM sys.dm_db_index_physical_stats(DB_ID(:1 /* database-name */), OBJECT_ID(:2 /* dbo.table-name */), NULL, NULL, NULL) AS a
  JOIN sys.indexes AS b ON a.object_id = b.object_id AND a.index_id = b.index_id
ORDER BY 3 desc;
  /* Fragmentation Level and recomended manouvers:
   *   Under 30%, REGORGANIZE INDEX
   *   Over  30%, REBUILD INDEX (BEWARE LOCK!)
   */

-- List sessions with it's running elapsed time and query text
SELECT
  P.spid
  , right(convert(varchar, dateadd(ms, datediff(ms, P.last_batch, getdate()), '1900-01-01'), 121), 12) as 'batch_duration'
  ,   P.cmd
  ,   P.program_name
  ,   P.hostname
  ,   P.loginame
  ,   sqltext.text
  ,   P.*
from master.dbo.sysprocesses P
    CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sqltext
where P.spid > 50 -- Don't show system-level sessions
  and P.status not in ('background', 'sleeping')
  and P.cmd not in ('AWAITING COMMAND','MIRROR HANDLER','LAZY WRITER','CHECKPOINT SLEEP','RA MANAGER')
order by batch_duration DESC;

-- Kills session with specified spid
KILL :1;

-- Enable explain of execution plan, instead of actually running statement
SET SHOWPLAN_ALL OFF
