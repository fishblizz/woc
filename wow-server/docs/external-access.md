# Externe toegang via Synology Reverse Proxy

Doel:

- Portal publiek via `https://woc.dev.fjildsoftware.nl`
- WoW login publiek via TCP `3724`
- WoW worldserver publiek via TCP `8085`
- Interne spelers blijven werken via `192.168.178.152`

## .env

Gebruik op de Synology:

```text
LAN_IP=192.168.178.152
PUBLIC_HOST=woc.dev.fjildsoftware.nl
PORTAL_PUBLIC_URL=https://woc.dev.fjildsoftware.nl
DOCKER_AUTH_EXTERNAL_PORT=3724
DOCKER_WORLD_EXTERNAL_PORT=8085
PORTAL_EXTERNAL_PORT=8090
```

Gebruik een sterk eigen `DOCKER_DB_ROOT_PASSWORD`.

## Synology Reverse Proxy

DSM:

```text
Configuratiescherm -> Aanmeldingsportal -> Geavanceerd -> Reverse Proxy
```

Regel:

```text
Bron:
Protocol: HTTPS
Hostnaam: woc.dev.fjildsoftware.nl
Poort: 443

Bestemming:
Protocol: HTTP
Hostnaam: 127.0.0.1
Poort: 8090
```

Als `127.0.0.1` niet werkt, gebruik als bestemming:

```text
192.168.178.152:8090
```

## Certificaat

DSM:

```text
Configuratiescherm -> Beveiliging -> Certificaat
```

Maak of koppel een Let's Encrypt certificaat voor:

```text
woc.dev.fjildsoftware.nl
```

## Router forwards

Op de Ziggo-router `192.168.178.1`:

```text
TCP 443  -> 192.168.178.152:443
TCP 3724 -> 192.168.178.152:3724
TCP 8085 -> 192.168.178.152:8085
```

Forward niet direct naar:

```text
8090
3306
7878
```

## Synology firewall

Sta toe:

```text
TCP 443
TCP 3724
TCP 8085
TCP 8090
```

`8090` hoeft alleen bereikbaar te zijn vanaf de Synology/reverse proxy en eventueel je LAN.

## Realmlist database

Na deploy of na wijziging van `.env`:

```sh
cd /volume1/docker/woc/wow-server
./scripts/set-realmlist-db.sh
```

Verwachte database-uitkomst:

```text
address          = woc.dev.fjildsoftware.nl
port             = 8085
localAddress     = 192.168.178.152
localSubnetMask  = 255.255.255.0
```

## Client

In `realmlist.wtf`:

```text
set realmlist woc.dev.fjildsoftware.nl
```

Gebruik geen `https://` in `realmlist.wtf`.

## Intern testen

Intern werkt `https://woc.dev.fjildsoftware.nl` alleen als de Ziggo-router hairpin NAT ondersteunt, of als je lokale DNS deze host naar `192.168.178.152` laat wijzen.

Als intern de domeinnaam niet werkt:

- maak in je lokale DNS een override: `woc.dev.fjildsoftware.nl -> 192.168.178.152`
- of gebruik intern tijdelijk `http://192.168.178.152:8090` voor de portal

Voor WoW intern blijft de database `localAddress=192.168.178.152` gebruiken voor clients uit `192.168.178.0/24`.
