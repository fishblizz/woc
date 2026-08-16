# PlayerBots optioneel

PlayerBots is bewust niet standaard geinstalleerd.

## Huidige stand

De meest relevante actuele module is:

```text
https://github.com/mod-playerbots/mod-playerbots
```

Belangrijke beperkingen:

- De module vereist een custom `Playerbot` branch van AzerothCore.
- Je moet zelf bouwen; prebuilt standaard AzerothCore images zijn niet genoeg.
- De module noemt Docker-installaties experimenteel/onofficieel met beperkte support.
- CPU- en RAM-gebruik stijgen afhankelijk van botgedrag, aantal bots en random bot instellingen.

## Advies voor DS218+

De Intel Celeron J3355 is krap voor PlayerBots. Voorzichtig pad:

1. Eerst vanilla AzerothCore stabiel krijgen.
2. Daarna testen op een aparte branch of aparte compose-map.
3. Begin met 1-3 bots.
4. Zet random/autologin bots laag of uit.
5. Meet DSM CPU/RAM tijdens questen, combat en reizen.
6. Stop als DSM begint te swappen of worldserver vaak boven 80-100% CPU komt.

Voor een echte bot-rijke solo-MMO-ervaring is krachtigere hardware waarschijnlijk verstandiger.

