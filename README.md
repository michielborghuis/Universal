# Counter

Een algemene, instelbare Flutter-scoreapp.

## Standaardspellen

### Dertigen
- Knoppen: `+1`, `+10`, `-15`
- Geen grote plus- of minknop
- Extra teller: `Gedronken`
- De teller stijgt bij gebruik van `-15`

### Tienduizenden
- Knoppen: `+50`, `+200`
- Geen grote plus- of minknop
- Geen extra teller

## Mogelijkheden

- Spellen kiezen vanuit het menu links
- Zelf spellen toevoegen en aanpassen
- Eigen scoreknoppen instellen
- Grote plus- en minknoppen optioneel inschakelen
- Stapgrootte voor de grote knoppen instellen
- Optionele extra teller per speler
- Instellen welke scoreknop de teller verhoogt
- Spelers per spel apart bewaren
- Handmatig scores aanpassen
- Undo
- Scores resetten
- Automatisch opslaan
- Tot negen spelers zonder scrollen in een raster

## Bouwen via GitHub

1. Maak een nieuwe lege GitHub-repository.
2. Upload alle bestanden en mappen uit deze ZIP.
3. Controleer dat `.github/workflows/build-apk.yml` is geüpload.
4. Open **Actions**.
5. Open **Bouw Android APK** en kies **Run workflow**.
6. Download na de build het artifact **Counter-APK**.
7. Pak het artifact uit en installeer `app-release.apk`.


## Versie 1.1

- De gouden rand voor de speler(s) met de hoogste score is nu een instelling per spel.
- Voor `Dertigen` staat deze standaard uit.
- Voor `Tienduizenden` staat deze standaard aan.
- Bij nieuwe spellen staat de optie standaard uit en kan deze tijdens het instellen worden aangezet.


## Versie 1.2.0

- Dynamische knopindeling: 1 breed, 2 naast elkaar, 3 als 2 + 1 breed, 4 als 2x2 en daarna rijen van twee.
- Gouden rand per spel instelbaar op hoogste score, hoogste extra teller of uit.
- Dertigen markeert standaard de hoogste bierteller; Tienduizenden de hoogste score.
- Naam en teller staan naast elkaar zonder overlap.
- Spelersnamen zijn maximaal 10 tekens.
- Tik op de naam om deze te wijzigen; de drie puntjes op kaarten zijn verwijderd.
- Nieuwe knop bovenaan om spelers te verwijderen.
- Teller is bewerkbaar en kan een biersymbool tonen.
- Grotere scores bij veel spelers en iets lagere knoppen.
- Nieuw blauw tellerlogo als Android-appicoon.
