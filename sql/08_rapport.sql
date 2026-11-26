-- Comparaison AVANT / APRES
SET LINESIZE 200 PAGESIZE 100 FEEDBACK OFF
COLUMN test FORMAT a40
COLUMN gain FORMAT a7
PROMPT
PROMPT ================== RESULTATS DU TUNING ==================
SELECT a.test,
       a.elapsed_ms avant_ms, p.elapsed_ms apres_ms,
       ROUND(a.elapsed_ms/NULLIF(p.elapsed_ms,0),1)||'x' gain,
       a.hard_parses hp_av, p.hard_parses hp_ap,
       a.temp_writes tmp_av, p.temp_writes tmp_ap,
       a.logical_reads lr_av, p.logical_reads lr_ap,
       p.rc_hits rc_hits_ap
FROM bench_results a JOIN bench_results p ON p.test = a.test AND p.phase = 'APRES'
WHERE a.phase = 'AVANT' ORDER BY a.test;
SELECT 'TOTAL : '||SUM(DECODE(phase,'AVANT',elapsed_ms))||' ms -> '||SUM(DECODE(phase,'APRES',elapsed_ms))
       ||' ms  (gain global x'||ROUND(SUM(DECODE(phase,'AVANT',elapsed_ms))/SUM(DECODE(phase,'APRES',elapsed_ms)),1)||')' total
FROM bench_results;
SET MARKUP CSV ON
SPOOL /tmp/bench_results.csv
SELECT phase,test,elapsed_ms,hard_parses,logical_reads,temp_writes,wa_optimal,wa_onepass,wa_multipass,rc_hits
FROM bench_results ORDER BY test, phase DESC;
SPOOL OFF
EXIT
