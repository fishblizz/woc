# WOC AzerothCore Server

Minimale LAN-only AzerothCore WotLK 3.3.5a omgeving voor een Synology DS218+.

Status: **GO WITH LIMITATIONS** voor 1 speler en voorzichtig enkele vrienden. De NAS is x86-64 en de officiële AzerothCore images zijn `linux/amd64`, maar 6 GB RAM is krap. Zie [docs/research.md](docs/research.md).

## Architectuur

```text
WoW 3.3.5a client op LAN
        |
        | TCP 3724 / 8085
        v
Synology DS218+
        |
        +-- ac-authserver
        |
        +-- ac-worldserver
        |
        +-- ac-database (MySQL 8.4)
              |
              +-- acore_auth
              +-- acore_characters
              +-- acore_world
```

## Eerste start

```sh
cd wow-server
cp .env.example .env
```

Pas `.env` aan:

```text
LAN_IP=192.168.x.x
DOCKER_DB_ROOT_PASSWORD=een-lang-willekeurig-wachtwoord
```

Start:

```sh
docker compose up -d
```

Status:

```sh
docker compose ps
```

Logs:

```sh
docker compose logs -f
```

Stop:

```sh
docker compose down
```

## Na eerste import

Zet het realm-adres naar het LAN-IP:

```sh
./scripts/set-realmlist-db.sh
```

Open de worldserver console:

```sh
./scripts/console.sh
```

Maak een speleraccount:

```text
account create gebruikersnaam wachtwoord
account set addon gebruikersnaam 2
```

Maak een GM/admin:

```text
account set gmlevel gebruikersnaam 3 -1
```

Detach veilig met `Ctrl+p`, daarna `Ctrl+q`.

## Scripts

- `scripts/start.sh`: start containers
- `scripts/stop.sh`: stop containers
- `scripts/status.sh`: toon status
- `scripts/logs.sh`: volg logs
- `scripts/console.sh`: worldserver console openen
- `scripts/create-account.sh`: toont accountcommando's en opent console
- `scripts/set-realmlist-db.sh`: zet realm-adres naar `LAN_IP`
- `scripts/backup.sh`: database backup
- `scripts/restore.sh`: database restore
- `scripts/full-backup.sh`: database plus config backup

## LAN-only poorten

Open alleen op LAN:

- TCP `3724`: authserver
- TCP `8085`: worldserver

Niet publiceren in fase 1:

- MySQL `3306`
- SOAP/admin `7878`

## Documentatie

- [docs/research.md](docs/research.md)
- [docs/synology.md](docs/synology.md)
- [docs/client.md](docs/client.md)
- [docs/playerbots.md](docs/playerbots.md)

