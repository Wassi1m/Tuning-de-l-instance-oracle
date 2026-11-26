-- Génération de données simulées (≈ 3,1 millions de lignes)
SET ECHO OFF FEEDBACK OFF TIMING ON
PROMPT Generation des clients (100 000)...
INSERT /*+ APPEND */ INTO clients
SELECT level, 'Client_'||level,
       DECODE(MOD(level,8),0,'Tunis',1,'Sfax',2,'Sousse',3,'Paris',4,'Lyon',5,'Alger',6,'Casablanca','Montreal'),
       DECODE(MOD(level,4),0,'Tunisie',1,'France',2,'Maroc','Canada'),
       DATE '2018-01-01' + MOD(level*7, 2500)
FROM dual CONNECT BY level <= 100000;
COMMIT;
PROMPT Generation des produits (5 000)...
INSERT /*+ APPEND */ INTO produits
SELECT level, 'Produit_'||level,
       DECODE(MOD(level,10),0,'Informatique',1,'Telephonie',2,'Maison',3,'Sport',4,'Livres',
              5,'Jeux',6,'Mode',7,'Beaute',8,'Auto','Jardin'),
       ROUND(5 + MOD(level*37, 1995) + MOD(level,100)/100, 2)
FROM dual CONNECT BY level <= 5000;
COMMIT;
PROMPT Generation des commandes (1 000 000)...
INSERT /*+ APPEND */ INTO commandes
SELECT rownum, MOD(rownum*7919, 100000)+1, DATE '2023-01-01' + MOD(rownum, 1000),
       DECODE(MOD(rownum,5),0,'ANNULEE',1,'EN_COURS','LIVREE'),
       ROUND(10 + MOD(rownum*31, 4990) + MOD(rownum,100)/100, 2)
FROM (SELECT 1 FROM dual CONNECT BY level <= 1000), (SELECT 1 FROM dual CONNECT BY level <= 1000);
COMMIT;
PROMPT Generation des lignes de commande (2 000 000)...
INSERT /*+ APPEND */ INTO lignes_commande
SELECT rownum, MOD(rownum*104729, 1000000)+1, MOD(rownum*13, 5000)+1,
       MOD(rownum,5)+1, ROUND(5 + MOD(rownum*17, 1995) + MOD(rownum,100)/100, 2)
FROM (SELECT 1 FROM dual CONNECT BY level <= 2000), (SELECT 1 FROM dual CONNECT BY level <= 1000);
COMMIT;
-- On simule une base "jamais maintenue" : pas de statistiques
EXEC DBMS_STATS.DELETE_SCHEMA_STATS('TUNING');
SELECT 'clients='||(SELECT COUNT(*) FROM clients)||'  produits='||(SELECT COUNT(*) FROM produits)||
       '  commandes='||(SELECT COUNT(*) FROM commandes)||'  lignes='||(SELECT COUNT(*) FROM lignes_commande) AS volumes
FROM dual;
EXIT
