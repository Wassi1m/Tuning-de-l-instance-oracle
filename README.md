# Tuning de l'instance Oracle

Projet d'**Administration avancée des bases de données** : diagnostiquer puis optimiser une instance **Oracle 23ai Free** (Docker) sur une base e-commerce simulée de **3,1 millions de lignes**.

> Résultat : le benchmark passe de **12,25 s à 0,71 s** (**×17**) en réglant 4 éléments, sans changer de matériel.

## Démarche

| Étape | Script | Rôle |
|---|---|---|
| 1. Installer | `docker-compose.yml` | Oracle 23ai Free (`gvenzl/oracle-free:23-slim`) |
| 2. Simuler | `sql/00_setup_user.sql`, `sql/01_schema.sql`, `sql/02_data.sql` | Utilisateur `TUNING`, schéma, 3,1 M lignes |
| 3. Dégrader | `sql/03_config_avant.sql`, `sql/03b_reset_schema.sql` | Instance « mal configurée », sans index ni stats |
| 4. Mesurer | `sql/04_bench.sql AVANT` | 4 scénarios chronométrés + deltas `v$mystat` |
| 5. Diagnostiquer | `sql/05_diagnostic.sql` | Ratios, `v$sql`, advisors PGA/SGA, événements d'attente |
| 6. Tuner | `sql/06_tuning_instance.sql`, `sql/07_tuning_schema.sql` | Paramètres d'instance + index/statistiques |
| 7. Vérifier | `sql/04_bench.sql APRES`, `sql/08_rapport.sql` | Comparaison avant/après |

## Lancer la démo

```bash
docker compose up -d      # premier démarrage : ~1 à 2 min
./run_demo.sh             # tout le scénario, logs dans results/
SKIP_DATA=1 ./run_demo.sh # relancer sans régénérer les données
```

Connexion manuelle : `sqlplus tuning/Tuning123@//localhost:1521/FREEPDB1` (SYS : `Oracle123`).

## Diagnostic (état initial)

| Constat | Source |
|---|---|
| 263 curseurs identiques au littéral près, soft parse ratio 84,5 % | `v$sql`, `v$sysstat` |
| PGA cache hit estimé à 47 % à 10 Mo, overalloc = 2 | `v$pga_target_advice` |
| 1er événement d'attente : `direct path write temp` (tris sur disque) | `v$system_event` |
| 1,47 M lectures logiques pour 300 recherches par client (full scan) | `v$sql`, `v$mystat` |

## Actions de tuning

| Zone | Paramètre | Avant → Après |
|---|---|---|
| PGA | `pga_aggregate_target` | 10M → 512M |
| Shared pool | `cursor_sharing` | EXACT → FORCE |
| Result cache | `result_cache_mode` / `result_cache_max_size` | MANUAL → FORCE / 64M |
| Session | `session_cached_cursors` | 100 (statique, au prochain redémarrage) |
| Objets | index + `DBMS_STATS` | aucun → 3 index + statistiques |

## Résultats

| Scénario | Avant | Après | Gain | Indicateur |
|---|---:|---:|---:|---|
| T1 · 10 000 requêtes à littéraux | 3 990 ms | 140 ms | ×28 | hard parses 10 042 → 5 |
| T2 · tri de 2 M lignes + GROUP BY | 1 300 ms | 450 ms | ×2,9 | blocs TEMP 11 756 → 0, multipass 2 → 0 |
| T3 · rapport répété ×15 | 2 120 ms | 110 ms | ×19 | 14 résultats servis par le result cache |
| T4 · 300 recherches par client | 4 840 ms | 10 ms | ×484 | lectures logiques 1 474 274 → 3 907 |
| **Total** | **12 250 ms** | **710 ms** | **×17** | |

Les chiffres bruts sont dans [results/bench_results.csv](results/bench_results.csv), le détail dans `results/*.log`. Les temps varient légèrement d'une exécution à l'autre.

## Limites

- `cursor_sharing=FORCE` est un palliatif : la vraie correction consiste à utiliser des variables de liaison dans l'application.
- Le result cache n'a d'intérêt que sur des données peu modifiées, car chaque DML invalide les résultats en cache.
- Oracle Free plafonne la mémoire à 2 Go : une PGA de 1G est refusée (`ORA-56752`).

## Livrables

- Présentation : [docs/Tuning_Instance_Oracle.pptx](docs/Tuning_Instance_Oracle.pptx)
- Vidéo démo (2 min) : [docs/demo_tuning_oracle.mp4](docs/demo_tuning_oracle.mp4)
