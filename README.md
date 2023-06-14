# convergence-bacon-docker

[![Docker Pulls](https://img.shields.io/docker/pulls/abesesr/convergence.svg)](https://hub.docker.com/r/abesesr/convergence/)


Ce dépôt contient la configuration docker 🐳 pour déployer l'échosystème des applications convergence Kbart2Kafka (cf sources de l'[api](https://github.com/abes-esr/kbart2kafka-api)) en local sur le poste d'un développeur, ou bien sur les serveurs de dev, test et prod.

## contenu du docker-compose.yml
Le docker-compose.yml définit les containers suivants (hors Watchtower)
- kbart2kafka-api : Web Service permettant à partir d'un fichier tsv de produire les données qu'il contient sur un serveur Kafka
- logskbart-api : composé de : 
    - 2 listener Kafka permettant d'une part de récupérer les logs d'exécution du producteur et de les stocker dans une base de données Postgresql, et d'autre part de récupérer les lignes kbart de Kafka pour les agréger dans la base de Bacon ou dans un fichier tsv.
    - 1 web service permettant de récupérer les logs pour un package kbart chargé à une date donnée.
- logskbart-db : base de données postgresql servant de stockage aux lignes de logs consommées dans Kafka.
- logskbart-db-dumper : système de sauvegarde de la base de données postgresql
- logskbart-db-adminer : interface Web d'accès à la base de données postgresql

## URLs de kbart2kafka

Les URLs correspondant aux déploiements en local, dev, test et prod de kbart2kafka sont les suivantes :

- local :
    - http://127.0.0.1:8080/ : URL interne de kbart2kafka-api
- dev :
    - http://cafeier-dev.v212.abes.fr:8080/ : URL de kbart2kafka-api
- test :
    - http://cafeier-test.v202.abes.fr:8080/ :  URL de kbart2kafka-api
- prod
    - pas encore defini

## URLs de logskbart

Les URLs correspondant aux déploiements en local, dev, test et prod de logskbart sont les suivantes : 

- local :
    - http://127.0.0.1:8083/ : URL interne de kbart2kafka-api
- dev :
    - http://cafeier-dev.v212.abes.fr:8083/ : URL de logskbart-api
- test :
    - http://cafeier-test.v202.abes.fr:8083/ :  URL de logskbart-api
- prod
    - pas encore defini

## URLs adminer 

Les URLs permettant d'accéder à l'adminer de la base postgresql sont les suivantes : 

- dev : http://cafeier-dev.v212.abes.fr:16082/ 
- test : http://cafeier-test.v202.abes.fr:16082/

## Prérequis

Disposer de :
- ``docker``
- ``docker-compose``

## Installation

Déployer la configuration docker dans un répertoire :
```bash
# adaptez /opt/pod/ avec l'emplacement où vous souhaitez déployer l'application
cd /opt/pod/
git clone https://github.com/abes-esr/convergence-bacon-docker.git
```

Configurer l'application depuis l'exemple du [fichier ``.env-dist``](./.env-dist) (ce fichier contient la liste des variables avec des explications et des exemples de valeurs) :
```bash
cd /opt/pod/convergence-bacon-docker/
cp .env-dist .env
# personnaliser alors le contenu du .env
```

**Note : les mots de passe de la base de donnée xml de test ne sont pas présent dans le fichier au moment de la copie. Vous devez aller les renseigner manuellement en editant le fichier dans la console avec nano par exemple**

Démarrer l'application :
```bash
cd /opt/pod/convergence-bacon-docker/
docker-compose up -d
```

Remarque : retirer le ``-d`` pour voir passer les logs dans le terminal et utiliser alors CTRL+C pour stopper l'application

```bash
# pour stopper l'application
cd /opt/pod/convergence-bacon-docker/
docker-compose stop


# pour redémarrer l'application
cd /opt/pod/convergence-bacon-docker/
docker-compose restart
```

## Supervision

```bash
# pour visualiser les logs de l'appli
cd /opt/pod/convergence-bacon-docker/
docker-compose logs -f --tail=100
```

Cela va afficher les 100 dernière lignes de logs générées par l'application et toutes les suivantes jusqu'au CTRL+C qui stoppera l'affichage temps réel des logs.


## Configuration

Pour configurer l'application, vous devez créer et personnaliser un fichier ``/opt/pod/convergence-bacon-docker/.env`` (cf section [Installation](#installation)). Les paramètres à placer dans ce fichier ``.env`` et des exemples de valeurs sont indiqués dans le fichier [``.env-dist``](https://github.com/abes-esr/convergence-bacon-docker/blob/develop/.env-dist)

## Sauvegardes

Les éléments suivants sont à sauvegarder:
- ``.env`` : contient la configuration spécifique de notre déploiement
- ``volumes/item-db/dump/`` : contient les dumps quotidiens de la base de données postgresql de item

Le répertoire suivant est à exclure des sauvegardes :
- ``volumes/item-db/pgdata/`` : contient les données binaires de la base de données postgresql item

### Restauration depuis une sauvegarde

Restaurez le dernier dump de la base de données postgresql de logskbart :
- récupérer le dernier dump généré par ``logskbart-db-dumper`` depuis le système de sauvegarde (le fichier dump ressemble à ceci ``pgsql_logskbart_logskbart-db_20220801-143201.sql.gz``) et placez le fichier dump récupéré (sans le décompresser) dans ``=volumes/logskbart-db/dump/`` sur la machine qui doit héberger la base de données
- ensuite lancez uniquement les conteneurs ``logskbart-db`` et ``logskbart-db-dumper`` :
   ```bash
   docker-compose up -d logskbart-db logskbart-db-dumper
   ```
- lancez le script de restauration ``restore`` comme ceci et suivez les instructions :
   ```bash
   docker exec -it logskbart-db-dumper restore
   ```
- C'est bon, la base de données logskbart est alors restaurée

Lancez alors toute les applications et vérifiez qu'elle fonctionne bien :
```bash
docker-compose up -d
```

## Déploiement continu

Les objectifs des déploiements continus de convergence-bacon sont les suivants (cf [poldev](https://github.com/abes-esr/abes-politique-developpement/blob/main/01-Gestion%20du%20code%20source.md#utilisation-des-branches)) :
- git push sur la branche ``develop`` provoque un déploiement automatique sur le serveur ``cafeier-dev``
- git push (le plus couramment merge) sur la branche ``main`` provoque un déploiement automatique sur le serveur ``cafeier-test``
- git tag X.X.X (associé à une release) sur la branche ``main`` permet un déploiement (non automatique) sur le serveur ``cafeier-prod`` / ! \pas encore en prod

Convergence bacon est déployé automatiquement en utilisant l'outil watchtower. Pour permettre ce déploiement automatique avec watchtower, il suffit de positionner à ``false`` la variable suivante dans le fichier ``/opt/pod/convergence-bacon-docker/.env`` :
```env
KBART2KAFKA_WATCHTOWER_RUN_ONCE=false
```

Le fonctionnement de watchtower est de surveiller régulièrement l'éventuelle présence d'une nouvelle image docker de ``kbart2kafka-api``, si oui, de récupérer l'image en question, de stopper le ou les les vieux conteneurs et de créer le ou les conteneurs correspondants en réutilisant les mêmes paramètres ceux des vieux conteneurs. Pour le développeur, il lui suffit de faire un git commit+push par exemple sur la branche ``develop`` d'attendre que la github action build et publie l'image, puis que watchtower prenne la main pour que la modification soit disponible sur l'environnement cible, par exemple la machine ``cafeier-dev``.

Le fait de passer ``KBART2KAFKA_WATCHTOWER_RUN_ONCE`` à false va faire en sorte d'exécuter périodiquement watchtower. Par défaut cette variable est à ``true`` car ce n'est pas utile voir cela peut générer du bruit dans le cas d'un déploiement sur un PC en local.

### Mise à jour de la dernière version

Pour récupérer et démarrer la dernière version de l'application vous pouvez le faire manuellement comme ceci :
```bash
docker-compose pull
docker-compose up
```
Le ``pull`` aura pour effet de télécharger l'éventuelle dernière images docker disponible pour la version glissante en cours (ex: ``develop-kbart2kafka-api`` ou ``main-kbart2kafka-api``). Sans le pull c'est la dernière image téléchargée qui sera utilisée.

Ou bien [lancer le conteneur ``kbart2kafka-watchtower``](https://github.com/abes-esr/convergence-bacon-docker/blob/develop/README.md#d%C3%A9ploiement-continu) qui le fera automatiquement toutes les quelques secondes pour vous.

## Architecture

Les codes de source de kbart2kafka sont ici :
- https://github.com/abes-esr/kbart2kafka-api : code source de l'API de kbart2kafka
