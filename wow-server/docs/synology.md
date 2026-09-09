# Synology DS218+ installatie

Doel: LAN-only AzerothCore WotLK 3.3.5a op een Synology DS218+ met Container Manager/Docker.

## 1. Voorbereiding

Installeer via DSM Package Center:

- Container Manager, of Docker op oudere DSM-versies
- SSH-toegang tijdelijk aanzetten via DSM Control Panel

Controleer via SSH:

```sh
docker --version
docker compose version
```

Richtwaarde: Docker 20.10+ en Docker Compose v2.5+, liever v2.10+.

## 2. Directory

Aanbevolen locatie op de NAS:

```sh
mkdir -p /volume1/docker/woc
```

Zet de inhoud van deze repository daar neer, met deze map als project:

```sh
/volume1/docker/woc/wow-server
```

De server schrijft runtime-data onder:

```sh
/volume1/docker/woc/wow-server/volumes/mysql
/volume1/docker/woc/wow-server/volumes/client-data
/volume1/docker/woc/wow-server/backups
/volume1/docker/woc/wow-server/portal-downloads
```

## 3. Rechten

Gebruik bij voorkeur je normale beheeruser die Docker/Container Manager mag gebruiken. Maak de projectmap beschrijfbaar voor die user:

```sh
cd /volume1/docker/woc/wow-server
mkdir -p volumes/mysql volumes/client-data backups portal-downloads
```

Als Docker klaagt over rechten, controleer in DSM of je user rechten heeft op de gedeelde map waarin `/volume1/docker/woc` staat.

## 4. Configuratie

Maak je lokale env-bestand:

```sh
cd /volume1/docker/woc/wow-server
cp .env.example .env
```

Pas minimaal aan:

```sh
LAN_IP=192.168.178.152
PUBLIC_HOST=woc.dev.fjildsoftware.nl
PORTAL_PUBLIC_URL=https://woc.dev.fjildsoftware.nl
DOCKER_DB_ROOT_PASSWORD=een-lang-willekeurig-wachtwoord
DOCKER_PLATFORM=linux/amd64
DOCKER_WORLD_PLATFORM=linux/amd64
DOCKER_WORLD_IMAGE=acore/ac-wotlk-worldserver:ahbot-autobalance
PORTAL_EXTERNAL_PORT=8090
```

Gebruik het LAN-IP van de Synology. Gebruik niet `localhost` vanaf een andere computer.

## 5. Custom worldserver-image

De private server gebruikt een custom worldserver-image met AHBot en AutoBalance:

```sh
acore/ac-wotlk-worldserver:ahbot-autobalance
```

Die image moet op de Synology bestaan voordat je `docker compose up -d` draait. Als je hem op een andere machine bouwt, exporteer hem buiten git:

```sh
docker save acore/ac-wotlk-worldserver:ahbot-autobalance | gzip > ac-wotlk-worldserver-ahbot-autobalance-amd64.tar.gz
```

Kopieer dit bestand naar de Synology en laad hem daar:

```sh
gzip -dc ac-wotlk-worldserver-ahbot-autobalance-amd64.tar.gz | docker load
docker image ls | grep ahbot-autobalance
```

Commit deze image-export niet. Het is deployment-materiaal, geen broncode.

## 6. Starten via SSH

Eerste start:

```sh
docker compose up -d
```

De eerste start kan lang duren, omdat database-import en server-data-initialisatie eerst klaar moeten zijn.

Na updates kun je vanaf de project-root deployen:

```sh
cd /volume1/docker/woc
./deploy.sh
```

Het deploy-script haalt `main` op uit Git, laat de lokale `.env` en runtime-data staan, valideert Docker Compose, en brengt database, client-data-init, database-import, authserver, worldserver en portal in volgorde terug online. Dit is belangrijk op Synology-installaties met het oudere `docker-compose`. De compose gebruikt bewust geen `cpus:` limieten, omdat sommige Synology-kernels die Docker-instelling niet ondersteunen.

Laat `DOCKER_WORLD_IMAGE` in `.env` expliciet staan. Oudere Synology `docker-compose` versies verwerken geneste standaardwaarden in image-namen niet altijd goed.

Status:

```sh
docker compose ps
```

Logs:

```sh
cd /volume1/docker/woc/wow-server
docker compose logs -f
```

Snelle diagnose als containers niet goed starten:

```sh
./scripts/diagnose-synology.sh
```

Let vooral op deze waarden:

```text
DOCKER_PLATFORM=linux/amd64
DOCKER_WORLD_PLATFORM=linux/amd64
```

De DS218+ is x86-64. Gebruik daar geen `linux/arm64`; dan kan de worldserver-image verkeerd of helemaal niet starten.

Als de worldserver-log blijft herhalen:

```text
cp: cannot create regular file '/azerothcore/env/dist/etc/modules/...conf.dist': Permission denied
```

Gebruik dan de nieuwste `compose.yaml` zonder losse read-only mounts onder `/azerothcore/env/dist/etc/modules`. De module-instellingen worden via container-omgeving gezet, zodat AzerothCore zelf zijn configuratiemap kan initialiseren.

Stoppen:

```sh
docker compose down
```

## 7. Portal openen

De interne World of Cees portal draait standaard op:

```text
http://<Synology-LAN-IP>:8090
```

De portal maakt accounts aan en toont downloads uit:

```sh
/volume1/docker/woc/wow-server/portal-downloads
```

Zet interne bestanden handmatig in die map. De inhoud wordt bewust niet in git meegenomen.

## 8. Realmlist in database zetten

Na de eerste database-import:

```sh
./scripts/set-realmlist-db.sh
```

Dit zet `acore_auth.realmlist.address` op `PUBLIC_HOST` uit `.env`, en `localAddress` op de `LAN_IP`.

## 9. Account maken

Open de worldserver console:

```sh
./scripts/console.sh
```

Daarna in de console:

```sh
account create gebruikersnaam wachtwoord
account set addon gebruikersnaam 2
```

Gebruik een accountwachtwoord van maximaal 16 tekens. AzerothCore weigert langere wachtwoorden omdat de 3.3.5a client die niet ondersteunt.

GM/admin maken:

```sh
account set gmlevel gebruikersnaam 3 -1
```

Veilig loskoppelen van de console: `Ctrl+p`, daarna `Ctrl+q`.

Gebruik niet `Ctrl+c`, want dat kan de worldserver stoppen.

Account verwijderen:

```sh
account delete gebruikersnaam
```

Account blokkeren:

```sh
ban account gebruikersnaam -1 reden
```

## 10. Automatisch starten na reboot

De containers hebben `restart: unless-stopped`. Na een normale NAS reboot starten ze opnieuw zodra Docker/Container Manager beschikbaar is.

Als je Container Manager Project gebruikt:

1. Open Container Manager.
2. Ga naar Project.
3. Maak een project met pad `/volume1/docker/woc/wow-server`.
4. Gebruik `compose.yaml`.
5. Start het project.

## 11. Firewall-poorten

Openzetten op de Synology firewall:

- TCP `3724`
- TCP `8085`
- TCP `8090`
- TCP `443`, als de Synology Reverse Proxy HTTPS voor de portal afhandelt

Niet openzetten:

- TCP `3306`
- TCP `7878`

Zet voor LAN-only geen router port-forwarding aan.

## 12. Internettoegang later

Voor toegang vanaf internet zijn minimaal router port-forwards voor TCP `3724` en `8085` nodig en moet de database-realmlist naar publiek IP of DNS wijzen. Voor de portal gebruik je bij voorkeur Synology Reverse Proxy:

```text
https://woc.dev.fjildsoftware.nl:443 -> http://127.0.0.1:8090
```

Forward op de router:

```text
TCP 443  -> 192.168.178.152:443
TCP 3724 -> 192.168.178.152:3724
TCP 8085 -> 192.168.178.152:8085
```

Forward niet direct naar `8090` als reverse proxy werkt. Gebruik sterke wachtwoorden en overweeg liever VPN naar je LAN.

## 13. Backups

Database backup:

```sh
./scripts/backup.sh
```

Restore:

```sh
./scripts/restore.sh ./backups/woc-wow-db-YYYYMMDD-HHMMSS.tar.gz
```

Config backup:

```sh
./scripts/full-backup.sh
```

Je kunt de map `/volume1/docker/woc/wow-server/backups` laten meenemen door Hyper Backup.
