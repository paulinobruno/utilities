-- Detecting Session Locks
SELECT
  blocked_locks.pid AS blocked_pid,
  blocked_activity.usename AS blocked_user,
  blocking_locks.pid AS blocking_pid,
  blocking_activity.usename AS blocking_user,
  blocked_activity.query AS blocked_statement,
  blocking_activity.query AS current_statement_in_blocking_process
FROM pg_catalog.pg_locks blocked_locks
  JOIN pg_catalog.pg_stat_activity blocked_activity  ON blocked_activity.pid = blocked_locks.pid
  JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
  JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;

-- List sessions from users
SELECT *
FROM pg_catalog.pg_stat_activity
WHERE pid != pg_backend_pid()
  AND usename = 'rdsadmin';

-- Kill specified session (per pid)
SELECT pg_terminate_backend(:pid);

-- List all privileges for role
select
  pg_user.usename,
  t1.nspname,
  t1.relname, 
  relacl.privilege_type,
  relacl.is_grantable
from (
  select
    pg_namespace.nspname,
    pg_class.relname,
    coalesce(pg_class.relacl, ('{' || pg_user.usename || '=arwdDxt/' || pg_user.usename || '}')::aclitem[]) as relacl
  from
    pg_class
    inner join pg_namespace on pg_class.relnamespace = pg_namespace.oid
    inner join pg_user on pg_class.relowner = pg_user.usesysid
  where
    pg_namespace.nspname !~ '^pg_'
    and pg_namespace.nspname != 'information_schema'
) as t1
cross join aclexplode(t1.relacl) as relacl
inner join pg_user on relacl.grantee = pg_user.usesysid
order by
  pg_user.usename,
  t1.nspname,
  t1.relname,
  relacl.privilege_type
