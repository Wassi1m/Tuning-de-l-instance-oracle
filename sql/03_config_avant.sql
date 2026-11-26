-- SYSDBA : on simule une instance MAL configuree (situation de depart)
SET ECHO ON
-- PGA sous-dimensionnee
ALTER SYSTEM SET pga_aggregate_target = 10M SCOPE=MEMORY;
-- pas de partage des curseurs (application avec litteraux)
ALTER SYSTEM SET cursor_sharing = EXACT SCOPE=MEMORY;
-- result cache inutilise
ALTER SYSTEM SET result_cache_mode = MANUAL SCOPE=MEMORY;
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
EXEC DBMS_RESULT_CACHE.FLUSH;
EXIT
