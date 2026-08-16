# WoW 3.3.5a client configureren

AzerothCore distribueert geen WoW-client. Gebruik alleen je eigen legitiem verkregen World of Warcraft 3.3.5a client.

## Realmlist

Open in je WoW-map:

```text
Data/realmlist.wtf
```

Zet de eerste regel op het LAN-IP van je Synology:

```text
set realmlist 192.168.x.x
```

Gebruik hetzelfde IP-adres als `LAN_IP` in `wow-server/.env` en in de database-realmlist.

Start de client bij voorkeur direct via `Wow.exe`, niet via een launcher die patchservers probeert te gebruiken.

## Eerste login

1. Start de containers.
2. Zet de database-realmlist met `./scripts/set-realmlist-db.sh`.
3. Maak een account via de worldserver console.
4. Start de client.
5. Log in met je AzerothCore-account.

