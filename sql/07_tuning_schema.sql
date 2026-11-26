-- Utilisateur TUNING : complément au niveau objets (statistiques + index)
SET ECHO ON TIMING ON
CREATE INDEX idx_cmd_client   ON commandes(client_id);
CREATE INDEX idx_lig_commande ON lignes_commande(commande_id);
CREATE INDEX idx_lig_produit  ON lignes_commande(produit_id);
EXEC DBMS_STATS.GATHER_SCHEMA_STATS('TUNING', method_opt => 'FOR ALL COLUMNS SIZE AUTO', cascade => TRUE);
EXIT
