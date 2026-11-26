-- Utilisateur TUNING : etat initial = aucun index secondaire, aucune statistique
SET FEEDBACK OFF
BEGIN
  FOR i IN (SELECT index_name FROM user_indexes WHERE index_name LIKE 'IDX\_%' ESCAPE '\') LOOP
    EXECUTE IMMEDIATE 'DROP INDEX '||i.index_name;
  END LOOP;
  DBMS_STATS.DELETE_SCHEMA_STATS('TUNING');
END;
/
EXIT
