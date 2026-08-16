# Research: AzerothCore op Synology DS218+

Datum: 2026-08-16

## Conclusie

**GO WITH LIMITATIONS**

De Synology DS218+ is technisch geschikt voor een kleine LAN-only AzerothCore WotLK 3.3.5a omgeving voor 1 speler en voorzichtig enkele vrienden. De CPU is beperkt en het geheugen is krap: AzerothCore documenteert 4 GB RAM als minimum voor 1-5 spelers en waarschuwt dat worldserver-geheugen kan groeien doordat werelddata in RAM blijft tot een restart. Met 6 GB totaal RAM moet DSM zelf ook ruimte houden. Daarom is dit realistisch als lichte homelab-server, maar niet als altijd-aan server met veel bots, veel spelers of zware modules.

## Bronnen

- AzerothCore Docker install: https://www.azerothcore.org/wiki/install-with-docker
- AzerothCore officiële Docker Compose in core repo: https://github.com/azerothcore/azerothcore-wotlk/blob/master/docker-compose.yml
- AzerothCore acore-docker prebuilt image compose: https://github.com/azerothcore/acore-docker
- AzerothCore requirements: https://www.azerothcore.org/wiki/requirements
- AzerothCore memory usage: https://www.azerothcore.org/wiki/es/memory-usage
- AzerothCore networking: https://www.azerothcore.org/wiki/networking
- AzerothCore client setup: https://www.azerothcore.org/wiki/client-setup
- AzerothCore account creation: https://www.azerothcore.org/wiki/creating-accounts
- Docker Hub worldserver tags: https://hub.docker.com/r/acore/ac-wotlk-worldserver/tags
- PlayerBots module: https://github.com/mod-playerbots/mod-playerbots

## Bevindingen

1. **Image-architectuur**

   De officiële `acore/ac-wotlk-worldserver` Docker Hub tags tonen `linux/amd64`. De DS218+ heeft een Intel Celeron J3355 en is x86-64, dus de prebuilt images passen qua CPU-architectuur. De Compose-config zet dit expliciet via `DOCKER_PLATFORM=linux/amd64`; op de DS218+ draait dit native, op Apple Silicon lokaal via Docker-emulatie.

2. **Docker en Compose**

   AzerothCore noemt Docker plus de Compose plugin als vereiste en toont als voorbeeld Docker `20.10.5` en Docker Compose `2.10.2`. Synology Container Manager ondersteunt projecten via Compose; recente Synology release notes noemen Compose-ondersteuning en Docker Engine 20.10/24.x afhankelijk van DSM/packageversie. Controleer op de NAS met:

   ```sh
   docker --version
   docker compose version
   ```

   Praktische ondergrens voor deze repository: Docker 20.10+ en Compose v2.5+; liever Compose v2.10+.

3. **Minimale services**

   Minimaal nodig:

   - `ac-database`
   - `ac-client-data-init`
   - `ac-db-import`
   - `ac-authserver`
   - `ac-worldserver`

   Niet nodig in fase 1: phpMyAdmin, Eluna TypeScript dev services, monitoring, reverse proxy, Kubernetes.

4. **Database**

   AzerothCore meldt dat MariaDB en MySQL 5.7/8.1 niet meer ondersteund zijn sinds 2024-09-19. De actuele officiële core compose gebruikt `mysql:8.4`. Deze repo volgt daarom MySQL 8.4.

5. **RAM en CPU**

   AzerothCore documenteert voor 1-5 spelers minimaal 4 GB RAM en beveelt voor zwaarder/blijvend gebruik meer aan. Op DS218+ met 6 GB RAM is dit krap maar haalbaar als DSM verder licht blijft en de server af en toe wordt herstart. CPU-belasting is normaal laag voor 1 speler, maar map loading, db-import, backups en bots kunnen pieken geven.

6. **Zelf compileren**

   Voor vanilla AzerothCore WotLK zonder modules is zelf compileren niet noodzakelijk: de officiële prebuilt `acore/ac-wotlk-*` images kunnen worden gebruikt. Zelf compileren wordt pas logisch bij custom modules, PlayerBots, source-patches of specifieke buildopties.

7. **Poorten**

   Nodig richting LAN-client:

   - `3724/tcp`: authserver
   - `8085/tcp`: worldserver

   Niet publiceren in fase 1:

   - `3306/tcp`: MySQL
   - `7878/tcp`: SOAP/admin

8. **Persistentie**

   Nodig:

   - MySQL data: `./volumes/mysql`
   - AzerothCore server-data volume: `./volumes/client-data`
   - Backups: `./backups`
   - Configuratie: `.env`, `compose.yaml`, scripts en docs in git

9. **PlayerBots**

   De actuele aanbevolen voortzetting is `mod-playerbots/mod-playerbots`. Deze vereist een custom Playerbot branch van AzerothCore en zelf bouwen; Docker-installatie wordt door de module zelf als experimenteel/onofficieel met beperkte support beschreven. Op een J3355 is dit alleen realistisch met zeer weinig bots. Begin later met 1-3 bots, meet CPU/RAM, en zet random/autologin bots uit of laag.
