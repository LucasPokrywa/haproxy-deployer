# HAProxy Deployer

Ce projet construit et lance une instance HAProxy configurable avec un fichier
`.env`. Il fournit également un benchmark HTTP basé sur `wrk` et un exemple
composé de deux serveurs Nginx.

## Prérequis

- Docker ;
- Docker Compose v2 (`docker compose`) ;
- Bash.

## Démarrage rapide avec l’exemple

Créer la configuration locale :

```bash
cp .env.example .env
```

Lancer HAProxy avec les deux serveurs web d’exemple :

```bash
./deploy --example
```

HAProxy est alors disponible, par défaut, à l’adresse :

```text
http://localhost:8080
```

Pour arrêter et supprimer les conteneurs du projet :

```bash
./deploy --destroy
```

## Utiliser ses propres backends

Modifier `.env` afin d’indiquer les noms ou adresses et les ports des deux
backends :

```dotenv
BACKEND_1_HOST=application-1
BACKEND_1_PORT=3000
BACKEND_2_HOST=application-2
BACKEND_2_PORT=3000
```

Puis lancer HAProxy :

```bash
./deploy
```

Les adresses des backends doivent être résolubles et accessibles depuis le
conteneur HAProxy. Pour utiliser les noms de services Docker, HAProxy et les
applications doivent partager un réseau Docker.

Le modèle actuel configure exactement deux backends. Ajouter un nombre variable
de backends nécessite d’adapter la génération de la configuration HAProxy.

## Configuration

Les valeurs sont lues depuis `.env`. Le fichier `.env.example` sert de modèle et
peut être versionné, contrairement au fichier `.env` local.

| Variable | Description | Exemple |
| --- | --- | --- |
| `HAPROXY_HTTP_PUBLIC_PORT` | Port HTTP exposé sur la machine | `80` |
| `HAPROXY_HTTP_LISTEN_PORT` | Port HTTP écouté dans le conteneur | `80` |
| `HAPROXY_HTTPS_PUBLIC_PORT` | Port HTTPS exposé avec `--https` | `443` |
| `HAPROXY_HTTPS_LISTEN_PORT` | Port HTTPS écouté avec `--https` | `443` |
| `HAPROXY_CERTIFICATE_PATH` | Chemin local du certificat PEM | `./certs/site.pem` |
| `BACKEND_1_HOST` | Nom DNS ou adresse du premier backend | `web1` |
| `BACKEND_1_PORT` | Port du premier backend | `80` |
| `BACKEND_2_HOST` | Nom DNS ou adresse du second backend | `web2` |
| `BACKEND_2_PORT` | Port du second backend | `80` |
| `BALANCE_ALGORITHM` | Algorithme de répartition HAProxy | `roundrobin` |
| `CONNECT_TIMEOUT` | Délai maximal de connexion au backend | `5s` |
| `CLIENT_TIMEOUT` | Délai maximal côté client | `30s` |
| `SERVER_TIMEOUT` | Délai maximal côté serveur | `30s` |
| `BENCHMARK_URL` | URL testée par `wrk` | `http://haproxy/` |
| `BENCHMARK_THREADS` | Nombre de threads du benchmark | `16` |
| `BENCHMARK_CONNECTIONS` | Nombre de connexions simultanées | `1000` |
| `BENCHMARK_DURATION` | Durée du benchmark | `30s` |

La configuration HAProxy est générée depuis
`templates/haproxy.cfg.template`, puis validée avec `haproxy -c` avant le
démarrage du processus.

## Commandes

Afficher l’aide :

```bash
./deploy --help
```

Lancer HAProxy avec les backends définis dans `.env` :

```bash
./deploy
```

Lancer les serveurs d’exemple :

```bash
./deploy --example
```

Activer HTTPS en complément de HTTP :

```bash
./deploy --https
```

Cette option nécessite le certificat PEM indiqué par
`HAPROXY_CERTIFICATE_PATH`. Le fichier doit contenir le certificat et sa clé
privée. Les fichiers `certs/*.pem` et `certs/*.key` sont ignorés par Git.

Lancer le benchmark avec les backends définis dans `.env` :

```bash
./deploy --benchmark
```

Lancer l’exemple puis le benchmark :

```bash
./deploy --example --benchmark
```

Charger tous les fichiers Compose additionnels :

```bash
./deploy --all
```

Charger tous les fichiers additionnels puis exécuter le benchmark :

```bash
./deploy --all --benchmark
```

Supprimer les conteneurs du projet, y compris ceux déclarés dans les fichiers
Compose additionnels :

```bash
./deploy --destroy
```

Les formes courtes sont également disponibles :

```text
-e  --example
-a  --all
-b  --benchmark
-s  --https
-d  --destroy
-h  --help
```

## Fichiers Compose additionnels

L’option `--all` lit `compose-files.list`. Ce fichier contient un chemin de
fichier Compose par ligne :

```text
# Exemple fourni avec le projet
examples/two-webservers/docker-compose.yaml

# Autre composition
/opt/my-application/compose.yaml
```

Les lignes vides et celles commençant par `#` sont ignorées. Les chemins peuvent
être relatifs ou absolus. Les chemins relatifs sont évalués depuis la racine du
projet, quel que soit le répertoire depuis lequel la commande `deploy` est
exécutée.

Lorsque plusieurs fichiers sont fusionnés avec `docker compose -f`, les chemins
de construction déclarés dans les fichiers additionnels doivent être cohérents
avec le répertoire du fichier Compose principal.

## Benchmark

Le benchmark utilise `wrk` et alterne les requêtes entre `/` et `/index.html`.
Ses paramètres sont contrôlés par les variables `BENCHMARK_*` du fichier
`.env`.

Exemple :

```dotenv
BENCHMARK_URL=http://haproxy/
BENCHMARK_THREADS=8
BENCHMARK_CONNECTIONS=500
BENCHMARK_DURATION=15s
```

Puis :

```bash
./deploy --benchmark
```

Le benchmark génère une charge importante. Il doit être utilisé avec prudence
sur un environnement partagé ou de production.

## Versions des images

Pour obtenir des constructions reproductibles, il est préférable d’épingler les
images Docker plutôt que d’utiliser le tag `latest`.

Un tag flottant :

```dockerfile
FROM nginx:latest
```

peut désigner une image différente lors d’une construction ultérieure. Une
version explicite limite ce risque :

```dockerfile
FROM nginx:<version>-alpine
```

Pour une reproductibilité stricte, une image peut être verrouillée avec son
digest :

```dockerfile
FROM nginx:<version>-alpine@sha256:<digest>
```

Le digest peut être obtenu après téléchargement de l’image :

```bash
docker pull nginx:<version>-alpine
docker image inspect nginx:<version>-alpine \
  --format '{{index .RepoDigests 0}}'
```

Lors d’une mise à jour volontaire, il faut remplacer la version ou le digest,
reconstruire les images et exécuter le benchmark pour vérifier le comportement.
