-- Benchmark : 4 scénarios représentatifs. Usage : @04_bench.sql AVANT|APRES
SET SERVEROUTPUT ON FEEDBACK OFF VERIFY OFF LINESIZE 200
DELETE FROM bench_results WHERE phase = '&1';
COMMIT;
DECLARE
  v_phase VARCHAR2(10) := '&1';
  TYPE t_snap IS TABLE OF NUMBER INDEX BY VARCHAR2(64);
  s0 t_snap; t0 NUMBER; rc0 NUMBER;
  n NUMBER; m NUMBER;

  FUNCTION st(p VARCHAR2) RETURN NUMBER IS r NUMBER;
  BEGIN
    SELECT m.value INTO r FROM v$mystat m JOIN v$statname s ON s.statistic# = m.statistic#
    WHERE s.name = p;
    RETURN r;
  END;
  FUNCTION rc RETURN NUMBER IS r NUMBER;
  BEGIN
    SELECT NVL(MAX(TO_NUMBER(value)),0) INTO r FROM v$result_cache_statistics WHERE name = 'Find Count';
    RETURN r;
  END;
  PROCEDURE debut IS BEGIN
    s0('hp') := st('parse count (hard)');
    s0('lr') := st('session logical reads');
    s0('tw') := st('physical writes direct temporary tablespace');
    s0('wo') := st('workarea executions - optimal');
    s0('w1') := st('workarea executions - onepass');
    s0('wm') := st('workarea executions - multipass');
    rc0 := rc; t0 := DBMS_UTILITY.GET_TIME;
  END;
  PROCEDURE fin(p_test VARCHAR2) IS
    el NUMBER; hp NUMBER; lr NUMBER; tw NUMBER; wo NUMBER; w1 NUMBER; wm NUMBER; rh NUMBER;
  BEGIN
    el := (DBMS_UTILITY.GET_TIME - t0) * 10;
    hp := st('parse count (hard)') - s0('hp');
    lr := st('session logical reads') - s0('lr');
    tw := st('physical writes direct temporary tablespace') - s0('tw');
    wo := st('workarea executions - optimal') - s0('wo');
    w1 := st('workarea executions - onepass') - s0('w1');
    wm := st('workarea executions - multipass') - s0('wm');
    rh := rc - rc0;
    INSERT INTO bench_results(phase,test,elapsed_ms,hard_parses,logical_reads,temp_writes,
                              wa_optimal,wa_onepass,wa_multipass,rc_hits)
    VALUES (v_phase, p_test, el, hp, lr, tw, wo, w1, wm, rh);
    COMMIT;
    DBMS_OUTPUT.PUT_LINE(RPAD(v_phase||' | '||p_test, 48)||LPAD(el,8)||' ms   hard_parses='||hp||
                         '  temp_writes='||tw||'  logical_reads='||lr||'  rc_hits='||rh);
  END;
BEGIN
  -- T1 : SQL avec littéraux (appli mal écrite) -> pression sur la shared pool / hard parse
  debut;
  FOR i IN 1 .. 10000 LOOP
    EXECUTE IMMEDIATE 'SELECT montant FROM commandes WHERE id = ' || i INTO n;
  END LOOP;
  fin('T1 Parsing (10000 requetes litterales)');

  -- T2 : gros tris + agrégation -> dépend de la PGA (work areas)
  debut;
  SELECT MAX(rn) INTO n FROM (
    SELECT ROW_NUMBER() OVER (ORDER BY prix_unitaire DESC, quantite, id) rn FROM lignes_commande);
  SELECT COUNT(*) INTO m FROM (
    SELECT client_id, SUM(montant) s FROM commandes GROUP BY client_id ORDER BY s DESC);
  fin('T2 Tri et agregation (PGA)');

  -- T3 : rapport répété 15 fois -> Result Cache
  debut;
  FOR i IN 1 .. 15 LOOP
    SELECT SUM(ca) INTO n FROM (
      SELECT p.categorie, SUM(l.quantite * l.prix_unitaire) ca
      FROM lignes_commande l JOIN produits p ON p.id = l.produit_id
      GROUP BY p.categorie);
  END LOOP;
  fin('T3 Rapport repete x15 (Result Cache)');

  -- T4 : accès sélectif par client (OLTP) -> index + statistiques
  debut;
  FOR i IN 1 .. 300 LOOP
    SELECT COUNT(*), NVL(SUM(montant),0) INTO n, m FROM commandes WHERE client_id = i * 37;
  END LOOP;
  fin('T4 Acces par client x300 (Index)');
END;
/
EXIT
