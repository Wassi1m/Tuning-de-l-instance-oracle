#!/usr/bin/env bash
# Tuning de l'instance Oracle - démonstration complète (avant -> diagnostic -> tuning -> après)
set -euo pipefail
cd "$(dirname "$0")"
C=oracle-tuning
SYS()  { docker exec -i $C sqlplus -s / as sysdba @/opt/sql/$1 "${@:2}"; }
APP()  { docker exec -i $C sqlplus -s tuning/Tuning123@//localhost/FREEPDB1 @/opt/sql/$1 "${@:2}"; }
titre(){ echo; echo -e "\e[1;31m=== $* ===\e[0m"; }
mkdir -p results

titre "0. Demarrage du conteneur Oracle 23ai Free"
docker compose up -d
until [ "$(docker inspect -f '{{.State.Health.Status}}' $C)" = "healthy" ]; do printf '.'; sleep 5; done; echo " pret"

if [ "${SKIP_DATA:-0}" != "1" ]; then
  titre "1. Creation de l'utilisateur et du schema"
  SYS 00_setup_user.sql
  APP 01_schema.sql
  titre "2. Simulation des donnees (3,1 M lignes)"
  APP 02_data.sql | tee results/02_data.log
fi

titre "3. Instance MAL configuree (etat initial)"
APP 03b_reset_schema.sql
SYS 03_config_avant.sql > results/03_config_avant.log
grep -E "^SQL> ALTER" results/03_config_avant.log || cat results/03_config_avant.log

titre "4. Benchmark AVANT tuning"
APP 04_bench.sql AVANT | tee results/04_bench_avant.log

titre "5. Diagnostic de l'instance (vues V\$ + advisors)"
SYS 05_diagnostic.sql | tee results/05_diagnostic_avant.log

titre "6. Tuning de l'instance + objets"
SYS 06_tuning_instance.sql | tee results/06_tuning_instance.log
APP 07_tuning_schema.sql | tee results/07_tuning_schema.log

titre "7. Benchmark APRES tuning"
APP 04_bench.sql APRES | tee results/04_bench_apres.log

titre "8. Rapport comparatif"
APP 08_rapport.sql | tee results/08_rapport.log
docker cp $C:/tmp/bench_results.csv results/bench_results.csv
SYS 05_diagnostic.sql > results/05_diagnostic_apres.log
