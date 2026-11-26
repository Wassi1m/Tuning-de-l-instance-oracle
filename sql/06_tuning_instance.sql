-- SYSDBA : actions de tuning de l'instance (justifiées par 05_diagnostic)
SET ECHO ON
-- 1) PGA : l advisor montre overalloc > 0 et hit% faible a 10M -> 512M
--    (Oracle Free plafonne la memoire totale a 2 Go : 1G est refuse, ORA-56752)
ALTER SYSTEM SET pga_aggregate_target = 512M SCOPE=BOTH;
-- 2) Shared pool : des milliers de curseurs identiques aux litteraux pres -> partage force
ALTER SYSTEM SET cursor_sharing = FORCE SCOPE=BOTH;
-- 3) Rapports repetitifs sur donnees peu modifiees -> Result Cache
ALTER SYSTEM SET result_cache_max_size = 64M SCOPE=BOTH;
ALTER SYSTEM SET result_cache_mode = FORCE SCOPE=BOTH;
-- 4) Cache des curseurs de session (parametre statique : actif au prochain redemarrage)
ALTER SYSTEM SET session_cached_cursors = 100 SCOPE=SPFILE;

-- Meme point de depart que la phase AVANT (caches vides)
ALTER SYSTEM FLUSH SHARED_POOL;
ALTER SYSTEM FLUSH BUFFER_CACHE;
EXEC DBMS_RESULT_CACHE.FLUSH;
EXIT
