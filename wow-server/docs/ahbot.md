# Auction House Bot

AHBot must use a dedicated bot character, not a real player character.

## Create a dedicated bot owner

1. Create an account for the bot, for example `AHBOT`.
2. Log in once with that account and create one character, for example `Auctionbot`.
3. Log out.

## Find the ids

On the Synology:

```sh
cd /volume1/docker/woc/wow-server

sudo docker-compose -f docker-compose.yml exec -T ac-database sh -c \
  'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" acore_characters' <<'SQL'
SELECT c.guid, c.name, c.account, a.username
FROM characters c
JOIN acore_auth.account a ON a.id = c.account
WHERE a.username = 'AHBOT' OR c.name = 'Auctionbot';
SQL
```

Use the returned account id and character guid in `.env`:

```text
AHBOT_ACCOUNT_ID=<account id>
AHBOT_CHARACTER_GUID=<character guid>
```

## Tune stock levels

Set the target amount of auctions per auction house:

```sh
cd /volume1/docker/woc/wow-server
./scripts/tune-ahbot.sh
```

Default:

```text
750 Alliance
750 Horde
750 Neutral
```

Override if needed:

```sh
AHBOT_MIN_ITEMS=1000 AHBOT_MAX_ITEMS=1000 ./scripts/tune-ahbot.sh
```

## Apply config

Restart the worldserver after changing `.env`:

```sh
sudo docker-compose -f docker-compose.yml up -d --force-recreate ac-worldserver
```

The bot fills the auction houses in update cycles. With `ItemsPerCycle=500`, an empty house should recover much faster than the original default.

## Temporary leveling gear mode

For a level 16 character, temporarily use:

```text
AHBOT_DISABLE_ITEMS_BELOW_REQ_LEVEL=10
AHBOT_DISABLE_ITEMS_ABOVE_REQ_LEVEL=25
```

Then restart the worldserver:

```sh
sudo docker-compose -f docker-compose.yml up -d --force-recreate ac-worldserver
```

Bias the auction house toward green and blue gear:

```sh
sudo docker-compose -f docker-compose.yml attach ac-worldserver
```

Run in the worldserver console:

```text
ahbotoptions percentages 2 0 0 0 0 0 0 0 0 10 65 25 0 0 0
ahbotoptions percentages 6 0 0 0 0 0 0 0 0 10 65 25 0 0 0
ahbotoptions percentages 7 0 0 0 0 0 0 0 0 10 65 25 0 0 0
ahbotoptions minitems 2 750
ahbotoptions maxitems 2 750
ahbotoptions minitems 6 750
ahbotoptions maxitems 6 750
ahbotoptions minitems 7 750
ahbotoptions maxitems 7 750
```

Detach safely with `Ctrl+p`, then `Ctrl+q`.

When the leveling bracket is no longer needed, set both `.env` level filters back to `0` and restart the worldserver again.

## Current player-owned bot auctions

If AHBot previously used a real player character, existing auctions may still show that player's name until they expire. Do not run `ahbotoptions ahexpire` unless you are sure that character has no real player auctions listed.
