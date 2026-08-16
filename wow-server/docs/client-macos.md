# macOS clientroute voor WoW 3.3.5a

Status op 2026-08-16: **INSTALLER ROUTE FAILED / CLIENT REQUIRED**.

Deze notitie documenteert de gecontroleerde stand voor het lokaal starten van
een WoW WotLK 3.3.5a Windows-client op Apple Silicon tegen deze AzerothCore
server. Er zijn geen Blizzard-assets, clientbestanden of private-server
clientdownloads gezocht, gedownload of gedistribueerd.

## Servercontext

- Serverproject: `/Users/ceesvisser/WOC/wow-server`
- Installerpad dat is geinspecteerd: `/Users/ceesvisser/WOC/wow-client-3.3.5a`
- Beoogde installatiemap: `/Users/ceesvisser/WOC/wow-client-installed-3.3.5a`
- Sikarugir wrapper: `/Users/ceesvisser/Applications/Sikarugir/WoW-335a-Installer.app`
- AzerothCore authserver: `192.168.178.129:3724`
- AzerothCore worldserver: `192.168.178.129:8085`
- Testaccount: `CEES`
- Serverconfiguratie is niet gewijzigd tijdens deze clientvalidatie.

## Clientvalidatie

Vereist:

```text
World of Warcraft Wrath of the Lich King 3.3.5a - build 12340
```

Resultaat van de mapinspectie:

```text
CLIENT INVALID
```

Reden:

- `Wow.exe` is niet aanwezig.
- `Data/` is niet aanwezig.
- `Data/realmlist.wtf` is niet aanwezig.
- Er zijn geen normale WotLK MPQ-clientdata onder `Data/`.
- Build `12340` kon niet worden aangetoond.
- De map lijkt een installer-staging/download te zijn, geen uitgepakte speelklare client.

Aangetroffen inhoud:

```text
Installer.exe
Installer.mfil
ProductDefs.xml
Installer Tome.mpq.part
Installer Tome 2.mpq.part
Installer Tome 3.mpq.part
Installer Tome 4.mpq.part
Installer Tome 5.mpq.part
Movies.mpq.part
DirectX/
```

`ProductDefs.xml` bevat:

```xml
<product_defs>
ProductCode WLK
TrialCode 0
PromoCode 0
LocCode enUS
</product_defs>
```

Dit wijst op een WotLK installer met `enUS` locale, maar bewijst geen
geinstalleerde 3.3.5a build 12340 client.

## Veiligheidscontrole

Statisch gecontroleerd, zonder executables te starten:

- Mapgrootte: ongeveer `6.6G`
- `Installer.exe`: PE32 Windows GUI executable, Intel 80386
- `DirectX/dxsetup.exe`: PE32 Windows GUI executable, Intel 80386
- `DirectX/*.dll`: PE32 Windows DLLs
- `Installer.exe` SHA-256:
  `eeade0b3a75969aceaa1af6d06daa5c48784f98503fd1031632b55fb65d5153b`
- `ProductDefs.xml` SHA-256:
  `d3e4a353a2c3bc4f6f3ccff1cce93720e74815eb7f7b2cc90c6fcb8beef93ab5`

macOS quarantine-attributen zijn aanwezig op de map en installerbestanden,
afkomstig van Microsoft Edge. Er is niets als root uitgevoerd, Gatekeeper is
niet globaal aangepast, en er zijn geen quarantine-attributen verwijderd.

## Realmlist

Niet gewijzigd, omdat er geen `realmlist.wtf` aanwezig is.

Wanneer een geldige clientmap aanwezig is, configureer:

```text
set realmlist 192.168.178.129
```

Maak vooraf een backup van het originele `realmlist.wtf`.

## Gratis Apple Silicon runtime

Geinstalleerd:

```text
Sikarugir Creator 1.0.1
```

Installatiepad:

```text
/Applications/Sikarugir Creator.app
```

Installatiemethode:

```sh
/usr/local/bin/brew tap Sikarugir-App/sikarugir
/usr/local/bin/brew install --cask Sikarugir-App/sikarugir/sikarugir
```

Opmerking: dit gebruikte de bestaande Intel/Rosetta Homebrew in `/usr/local`.
Native ARM Homebrew onder `/opt/homebrew` is niet geinstalleerd, omdat de
Homebrew installer sudo-toegang vereiste.

Veiligheidsnotitie:

- De bestaande `/Applications/Whisky.app` is niet gebruikt. `codesign` meldde
  opnieuw een ongeldige signature.
- Sikarugir is geinstalleerd via de officiële GitHub/Homebrew tap.
- De Sikarugir cask zelf waarschuwt dat `https://sikarugir.com` niet door het
  project wordt beheerd. Vertrouw voor deze route op de GitHub/Homebrew bron,
  niet op die site.
- De cask downloadt `Creator-v1.0.1.tar.xz` van GitHub met SHA-256
  `187825e4e6bf96f294cf9ccb65e53049432b3ee2925480e8ad1cbca12a96e819`.
- De cask verwijdert quarantine van de Sikarugir Creator app en signeert deze
  ad-hoc. Er zijn geen quarantine-attributen verwijderd van de WoW installer.

Actuele voorkeursroute:

1. **Sikarugir**: gratis/open-source Wine-wrapper, opvolger van
   Wineskin/Kegworks, ondersteunt Apple Silicon en gebruikt officiële
   Homebrew-cask installatie.
2. **frankea/Whisky**: actieve community-fork van de gearchiveerde originele
   Whisky-app. Gebruik niet `brew install --cask whisky`, want dat verwijst
   naar de oude originele route.
3. Gratis virtualisatie pas overwegen als Wine-wrapper routes technisch niet
   haalbaar blijken.

Bronnen:

- https://github.com/Sikarugir-App/Sikarugir
- https://github.com/Sikarugir-App/homebrew-sikarugir
- https://frankea.github.io/Whisky/
- https://github.com/frankea/Whisky

## Installerpoging via Sikarugir

Uitgevoerd:

```text
Sikarugir Creator 1.0.1
Template 1.0.11
Engine WS12WineSikarugir10.0_6
Wrapper /Users/ceesvisser/Applications/Sikarugir/WoW-335a-Installer.app
```

Veiligheidskeuzes:

- De wrapper is apart aangemaakt voor de installer.
- `Map User Mac OS X folders in wrapper` is uitgezet.
- D3DMetal/DXMT/DXVK zijn uitgelaten voor de installerfase.
- De installerbestanden zijn naar `C:\Program Files\wow-client-3.3.5a_installer`
  binnen de wrapper gekopieerd, zodat de `.mpq.part` bestanden naast
  `Installer.exe` beschikbaar waren op `C:`.

Resultaat:

```text
INSTALLER ROUTE FAILED
```

De installer startte wel, maar toonde:

```text
Sorry, the installer was unable to start up.
Unable to initialize streaming. Please check your Internet connection.
```

De relevante Wine-logregels:

```text
starting C:\Program Files\wow-client-3.3.5a_installer\Installer.exe in experimental wow64 mode
starting C:\users\ceesvisser\AppData\Local\Temp\Blizzard Installer Bootstrap ...\Installer.exe in experimental wow64 mode
```

Er ontstond geen geinstalleerde client:

- geen `Wow.exe`
- geen `Data/`
- geen `Data/realmlist.wtf`
- geen geinstalleerde `World of Warcraft` map

Root cause:

`Installer.mfil` verwijst naar een oude Blizzard streaming manifest URL:

```text
http://us.version.worldofwarcraft.com/streaming/installer/8874patch3.0.1/enUS/Installer.UNIV.mfil
```

Vanaf macOS zelf resolved deze host niet meer:

```text
Could not resolve host: us.version.worldofwarcraft.com
```

Conclusie: Wine mist geen internettoegang; deze oude streaming-installer hangt
af van Blizzard-infrastructuur die niet meer beschikbaar is. DNS/hosts
ombuigen, manifests nabouwen of de installer patchen is niet gekozen, omdat dat
onbetrouwbaar en onnodig risicovol is.

## Homebrew-architectuur

Huidige situatie:

```text
arch: arm64
/usr/local/bin/brew: Homebrew 6.0.17
/opt/homebrew/bin/brew: niet aanwezig
```

Als runtime-installatie later native ARM Homebrew vereist, mag dat naast de
bestaande Intel/Rosetta Homebrew:

```text
/usr/local/...   Intel/Rosetta Homebrew
/opt/homebrew/... native Apple Silicon Homebrew
```

De bestaande `/usr/local` Homebrew-installatie mag niet verwijderd, gemigreerd
of overschreven worden.

## Volgende stap

Ruim de installer-set en tijdelijke wrapper desgewenst op.

Lever daarna een reeds volledig geinstalleerde, legitiem verkregen WotLK
3.3.5a build 12340 clientmap aan met minimaal:

```text
Wow.exe
Data/
Data/realmlist.wtf
```

Daarna opnieuw valideren en pas dan `realmlist.wtf` wijzigen:

- build `3.3.5a 12340`
- locale
- MPQ/clientdata
- realmlist-backup en configuratie
- eerste login op `CEES` met handmatig ingevoerd wachtwoord
