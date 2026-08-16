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
```

## 3. Rechten

Gebruik bij voorkeur je normale beheeruser die Docker/Container Manager mag gebruiken. Maak de projectmap beschrijfbaar voor die user:

```sh
cd /volume1/docker/woc/wow-server
mkdir -p volumes/mysql volumes/client-data backups
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
LAN_IP=192.168.x.x
DOCKER_DB_ROOT_PASSWORD=een-lang-willekeurig-wachtwoord
```

Gebruik het LAN-IP van de Synology. Gebruik niet `localhost` vanaf een andere computer.

## 5. Starten via SSH

Eerste start:

```sh
docker compose up -d
```

De eerste start kan lang duren, omdat database-import en server-data-initialisatie eerst klaar moeten zijn.

Status:

```sh
docker compose ps
```

Logs:

```sh
docker compose logs -f
```

Stoppen:

```sh
docker compose down
```

## 6. Realmlist in database zetten

Na de eerste database-import:

```sh
./scripts/set-realmlist-db.sh
```

Dit zet `acore_auth.realmlist.address` op de `LAN_IP` uit `.env`.

## 7. Account maken

Open de worldserver console:

```sh
./scripts/console.sh
```

Daarna in de console:

```sh
account create gebruikersnaam wachtwoord
account set addon gebruikersnaam 2
```

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

## 8. Automatisch starten na reboot

De containers hebben `restart: unless-stopped`. Na een normale NAS reboot starten ze opnieuw zodra Docker/Container Manager beschikbaar is.

Als je Container Manager Project gebruikt:

1. Open Container Manager.
2. Ga naar Project.
3. Maak een project met pad `/volume1/docker/woc/wow-server`.
4. Gebruik `compose.yaml`.
5. Start het project.

## 9. Firewall-poorten

LAN-only openzetten op de Synology firewall:

- TCP `3724`
- TCP `8085`

Niet openzetten:

- TCP `3306`
- TCP `7878`

Zet geen router port-forwarding aan voor fase 1.

## 10. Internettoegang later

Voor toegang vanaf internet zijn minimaal router port-forwards voor TCP `3724` en `8085` nodig en moet de database-realmlist naar publiek IP of DNS wijzen. Dat is bewust niet de eerste versie. Gebruik sterke wachtwoorden en overweeg liever VPN naar je LAN.

## 11. Backups

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

