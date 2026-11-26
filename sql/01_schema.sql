-- Schéma e-commerce (utilisateur TUNING) - volontairement SANS index secondaires
SET ECHO OFF FEEDBACK OFF
BEGIN
  FOR t IN (SELECT table_name FROM user_tables) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE '||t.table_name||' CASCADE CONSTRAINTS PURGE';
  END LOOP;
END;
/
CREATE TABLE clients (
  id NUMBER PRIMARY KEY, nom VARCHAR2(60), ville VARCHAR2(40),
  pays VARCHAR2(30), date_inscription DATE);
CREATE TABLE produits (
  id NUMBER PRIMARY KEY, libelle VARCHAR2(80), categorie VARCHAR2(30), prix NUMBER(10,2));
CREATE TABLE commandes (
  id NUMBER PRIMARY KEY, client_id NUMBER, date_cmd DATE,
  statut VARCHAR2(15), montant NUMBER(12,2));
CREATE TABLE lignes_commande (
  id NUMBER PRIMARY KEY, commande_id NUMBER, produit_id NUMBER,
  quantite NUMBER, prix_unitaire NUMBER(10,2));
CREATE TABLE bench_results (
  phase VARCHAR2(10), test VARCHAR2(40), elapsed_ms NUMBER,
  hard_parses NUMBER, logical_reads NUMBER, temp_writes NUMBER,
  wa_optimal NUMBER, wa_onepass NUMBER, wa_multipass NUMBER, rc_hits NUMBER,
  run_date DATE DEFAULT SYSDATE);
PROMPT Schema cree.
EXIT
