-- SYSDBA : diagnostic de l'instance (vues dynamiques + advisors)
SET LINESIZE 160 PAGESIZE 100 FEEDBACK OFF
COLUMN name FORMAT a45
COLUMN value FORMAT a25
ALTER SESSION SET CONTAINER = FREEPDB1;
PROMPT
PROMPT ===== 1. Parametres memoire / parsing actuels =====
SELECT name, display_value value FROM v$parameter
WHERE name IN ('sga_target','pga_aggregate_target','cursor_sharing','result_cache_mode',
               'result_cache_max_size','session_cached_cursors','open_cursors','db_cache_size','shared_pool_size')
ORDER BY name;

PROMPT
PROMPT ===== 2. Ratios de sante de l'instance =====
SELECT 'Buffer cache hit ratio (%)' name,
       TO_CHAR(ROUND(100*(1 - phy.value/NULLIF(db.value+con.value,0)),2)) value
FROM v$sysstat phy, v$sysstat db, v$sysstat con
WHERE phy.name='physical reads cache' AND db.name='db block gets from cache' AND con.name='consistent gets from cache'
UNION ALL
SELECT 'Library cache hit ratio (%)', TO_CHAR(ROUND(100*SUM(pinhits)/NULLIF(SUM(pins),0),2)) FROM v$librarycache
UNION ALL
SELECT 'Soft parse ratio (%)', TO_CHAR(ROUND(100*(1 - h.value/NULLIF(t.value,0)),2))
FROM v$sysstat h, v$sysstat t WHERE h.name='parse count (hard)' AND t.name='parse count (total)'
UNION ALL
SELECT 'Work areas optimal (%)', TO_CHAR(ROUND(100*o.value/NULLIF(o.value+p.value+m.value,0),2))
FROM v$sysstat o, v$sysstat p, v$sysstat m
WHERE o.name='workarea executions - optimal' AND p.name='workarea executions - onepass'
  AND m.name='workarea executions - multipass';

PROMPT
PROMPT ===== 3. Top 5 SQL par temps ecoule (v$sql) =====
COLUMN sql_text FORMAT a70
SELECT * FROM (
  SELECT ROUND(elapsed_time/1e6,2) sec, executions execs, SUBSTR(sql_text,1,70) sql_text
  FROM v$sql WHERE parsing_schema_name='TUNING' ORDER BY elapsed_time DESC)
WHERE ROWNUM <= 5;

PROMPT
PROMPT ===== 4. Requetes quasi identiques non partagees (litteraux) =====
SELECT COUNT(*) nb_curseurs, MAX(SUBSTR(sql_text,1,50)) exemple
FROM v$sql WHERE sql_text LIKE 'SELECT montant FROM commandes WHERE id = %'
HAVING COUNT(*) > 0;

PROMPT
PROMPT ===== 5. PGA Advisor (v$pga_target_advice) =====
COLUMN target_mb FORMAT 99999
SELECT ROUND(pga_target_for_estimate/1024/1024) target_mb, pga_target_factor factor,
       estd_pga_cache_hit_percentage hit_pct, estd_overalloc_count overalloc
FROM v$pga_target_advice ORDER BY 1;

PROMPT
PROMPT ===== 6. SGA Advisor (v$sga_target_advice) =====
SELECT sga_size sga_mb, sga_size_factor factor, estd_db_time db_time, estd_physical_reads phys_reads
FROM v$sga_target_advice ORDER BY 1;

PROMPT
PROMPT ===== 7. Top evenements d'attente (hors idle) =====
COLUMN event FORMAT a45
SELECT * FROM (
  SELECT event, total_waits, ROUND(time_waited_micro/1e6,2) sec
  FROM v$system_event WHERE wait_class <> 'Idle' ORDER BY time_waited_micro DESC)
WHERE ROWNUM <= 7;
EXIT
