# HAProxy Deployer

Ce projet construit et lance une instance HAProxy configurable avec un fichier
`.env`. Il fournit également un benchmark HTTP basé sur `wrk` et un exemple
composé de deux serveurs Nginx.

## Prérequis

- Docker ;
- Docker Compose v2 (`docker compose`) ;
- Bash ;
- OpenSSL, uniquement pour générer un certificat local autosigné.

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
http://localhost
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
`templates/haproxy.http.cfg.template` ou
`templates/haproxy.https.cfg.template`, puis validée avec `haproxy -c` avant
le démarrage du processus.

## HTTPS optionnel

Par défaut, le projet active uniquement HTTP. L’option `--https` ajoute le port
HTTPS, monte le certificat configuré et utilise le modèle HAProxy HTTPS :

```bash
./deploy --https
```

Avec les serveurs d’exemple :

```bash
./deploy --example --https
```

Lorsque HTTPS est actif, les requêtes HTTP sont redirigées vers HTTPS.

### Générer un certificat local

Créer un certificat autosigné pour `localhost` :

```bash
mkdir -p certs

openssl req \
  -x509 \
  -newkey rsa:2048 \
  -sha256 \
  -nodes \
  -days 365 \
  -keyout certs/site.key \
  -out certs/site.crt \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"
```

Créer ensuite le fichier PEM attendu par HAProxy :

```bash
cat certs/site.crt certs/site.key > certs/site.pem
chmod 600 certs/site.key certs/site.pem
```

Vérifier le chemin dans `.env` :

```dotenv
HAPROXY_CERTIFICATE_PATH=./certs/site.pem
```

Puis lancer et tester :

```bash
./deploy --example --https
curl -k https://localhost/
```

L’option `-k` est nécessaire pour ce test, car le certificat autosigné n’est pas
reconnu par une autorité de certification publique. Il ne doit pas être utilisé
en production. En production, utiliser un certificat valide, par exemple fourni
par Let’s Encrypt, et réunir la chaîne de certificats et la clé privée dans le
fichier PEM attendu par HAProxy.

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
privée. Les fichiers `certs/*.pem` et `certs/*.key` sont ignorés par Git et ne
doivent pas être commités.

Lancer le benchmark avec les backends définis dans `.env` :

```bash
./deploy --benchmark
```

Lancer l’exemple puis le benchmark :

```bash
./deploy --example --benchmark
```

Lancer l’exemple avec HTTPS puis le benchmark :

```bash
./deploy --example --https --benchmark
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

## Licence

Ce projet est distribué sous licence MIT. Il peut être utilisé, copié, modifié,
publié, distribué et intégré dans des projets personnels ou commerciaux, sous
réserve de conserver la notice de copyright et la licence.

Consulter le fichier [`LICENSE`](LICENSE) pour les conditions complètes.

## Versions des images

Les Dockerfiles utilisent des versions explicites :

```text
HAProxy 3.2.21 Alpine
Nginx 1.31.3
wrk 4.0.2
```

Ces versions évitent de récupérer automatiquement une nouvelle version majeure
ou corrective lors d’une future construction.

Pour obtenir des constructions encore plus strictement reproductibles, les
images Docker peuvent également être épinglées par digest.

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
