# Pace-Social-Referenzanalyse für Pace Life

Stand: 8. November 2026. Diese Analyse ersetzt den bisherigen Vermerk
„visueller Videoabgleich ausstehend“ für die **Auswertung** der Referenzen. Ein
1:1-Abgleich der fertigen Pace-Life-Oberfläche auf Simulator und iPhone bleibt eine
eigene, fortlaufende Prüfung (siehe unten).

## Quelle und Datenschutz

- Zwei Original-Bildschirmaufnahmen von Pace Social, als Anhänge im aktiven Claude-
  Code-Chat bereitgestellt (Dark: 78,7 s, 720 × 1280, 15 fps; Light: 99,2 s,
  480 × 854, 30 fps; SHA-256-Präfixe `a8af6a64…` und `f02b2fcc…`).
- Auswertung: Einzelbilder mit `ffmpeg` (1 fps plus gezielte Vollbilder) nur im
  sitzungsprivaten Scratchpad. **Keine Videos, Frames, Kontaktbögen oder
  Ausschnitte wurden in dieses oder ein anderes Repository übernommen.**
- Die Aufnahmen enthalten echte Namen, Profilbilder, Gruppen, Regionen und
  Chat-Inhalte. Diese werden hier nicht wiedergegeben und nirgends als Testdaten
  verwendet. Das Pace-Social-Repository wurde nicht geöffnet.
- Gemessene Farben stimmen innerhalb der Videokompression mit den Tokens aus
  `DESIGN_SYSTEM.md` überein (z. B. Dark-Hintergrund `#0C1215` gemessen vs. Token
  `#0B1315`, Mint-Auswahl `#89FFD5` vs. `#8EF8DC`, Light-„Anpassen“ `#124F33` vs.
  `#075237`). Die Tokens bleiben daher unverändert; gemessene Werte ersetzen sie
  nicht.

## Gemessene Layout-Grundwerte

Umrechnung über die sichtbare Screenbreite (≈ 1,5 px/pt im Dark-Video, iPhone mit
393 pt Breite). Werte sind auf das 4-pt-Raster gerundet.

| Element | Beobachtung | Pace-Life-Umsetzung |
|---|---|---|
| Seitenrand | Karten 16 pt vom Rand | `PaceSpacing.m` |
| Kartenabstand | 12–16 pt vertikal | 12 pt auf Home, 16 pt in Unterseiten |
| Karte | weiß / `#111A1D`, 1-pt-Rand, ca. 20 pt Radius, 16 pt Innenabstand | `PaceCard` unverändert |
| Innere Kachel | eigener Rand, ca. 14 pt Radius, gleiche Fläche wie Karte | `PaceTile` |
| Kopfzeile | Wortmarke links (≈ 34 pt, sehr fett, gerundet), rechts Primäraktion „Anpassen“ (≈ 39 pt hoch, 12 pt Radius, Icon + 17 pt semibold) | `PaceRootHeader` |
| Begrüßung | „Hi ‹Name›“ ≈ 28 pt bold, rechts Kalender- und Glocken-Icon (44-pt-Ziele) | Begrüßung mit optionalem lokalem Namen |
| Positionskacheln | 4 gleich breite Kacheln, 8 pt Abstand: Icon, Chevron oben rechts, Label, `#1` heavy, Untertitel | 4 Life-Kacheln (Mode, Serie, Routinen, Paths) |
| Hauptkarte | Titel 17 pt semibold links, Aktion „Tagesziel ändern“ (Akzent, Zielscheiben-Icon) rechts; Zahl ≈ 58–60 pt bold; „von …“; linearer Balken (≈ 8 pt, runde Enden); „Noch … bis zu deinem Ziel“; Ring ≈ 112 pt, 12 pt Linie, Prozent zentriert | `HomeHeroCard` mit erledigten Gewohnheiten |
| Unterzeile der Hauptkarte | Kachel mit zwei Hälften, je Icon + Wert + Untertitel + Chevron, vertikaler Trenner | Routinen / erfasste Minuten |
| Serienkarte | Kreis-Icon (≈ 40 pt), „0 Tage“ heavy, „Heute offen“ | Life-Serie über alle geplanten Tage |
| Wochenkarte | Titel + Chevron; Balken Mo–So mit Y-Achse, Ziellinie, heutiger Balken dunkler/Mint, künftige Tage gestrichelte Platzhalter; zwei Kennzahl-Kacheln; Fußzeile mit Häkchen „n von m Tagen Ziel erreicht“ | `WeekWidget` |
| Kalenderkarte | Monatsraster; erreichte Tage gefüllt (`goalReachedFill`), sonst Fortschrittskreis um die Zahl, heute umrandet, Zukunft grau mit „–“, Wert klein darunter | `CalendarWidget` / Kalender-Unterseite |
| Gruppenkarte | Titel + Chevron, Zeilen als innere Kacheln mit Avatar, Name, Status, Flammen-Zähler | Kreise-Widget (lokal, Demo gekennzeichnet) |
| Tab-Bar | volle Breite, Fläche `surface`, feine Oberkante; 4 Ziele; aktiv: Mint-Fläche (≈ 90 × 47 pt, 14 pt Radius), **gefülltes** Icon, fetter Text; inaktiv: Kontur-Icon, sekundärer Text | `PaceDock` |
| Unterseite | „‹ Home“ (Akzent) oben links, darunter Wortmarke und großer Titel (≈ 28 pt bold); Tab-Bar bleibt sichtbar | Push-Navigation mit sichtbarem Dock |
| Segment | Tag/Woche/Monat als gleich breite Felder; aktiv Light `accentStrong`+weiß, Dark Mint+dunkel; inaktiv `fieldBackground` | `PaceSegmentedControl` |
| Filter-Chips | Icon + Text, aktiv `selectionFill`, Kapselform | `PaceChip` |
| Einstellungszeilen | Karte je Zeile: Icon in Mint-Quadrat, Titel + zweizeiliger Untertitel, Wert rechts, Chevron | `PaceSettingsRow` |
| Buttons | Primär voll breit `accentStrong`; sekundär `selectionFill`/`accentSoft` mit Akzenttext; destruktiv rot mit Icon in Zeile | `PaceButtonStyle` (52 pt) |
| Schalter | Toggle in getönter Zeile (`selectionFill`), Tint `accentStrong` | `PaceToggleRow` |

## Interaktionen

- **Anpassen-Modus des Homescreens:** „Anpassen“ wird zu „Fertig“; darunter
  „+ Widget hinzufügen“ und der Hinweis „Halten und verschieben, um deine Übersicht
  anzupassen.“ Jede Karte zeigt oben links ein ×, oben rechts „Größe auswählen“
  (Klein/Mittel/Groß/Max) und einen Griff; die ausgewählte Karte erhält einen
  Akzentrahmen. Inhalt bleibt live sichtbar.
- **Unterseiten:** Standard-Push von rechts mit Parallaxe; die Tab-Bar bleibt stehen.
  Der Zurück-Link heißt wie die Ausgangsseite.
- **Scrollen:** Kopfzeile scrollt mit dem Inhalt; die Tab-Bar bleibt fixiert.
  Inhalte laufen unter der Statusleiste nicht sichtbar weiter (System-Blur).
- **Tagesziel ändern:** Sheet mit Rad-Picker, „Abbrechen“/„Sichern“, erklärender
  Fußzeile. Für Pace Life entspricht das der Tagesanpassung (Pace Adaptive).
- **Kalender:** Monat wechseln mit Pfeilen; Antippen eines Tages zeigt eine
  Tageskarte mit Zahl, Ring, Balken und darunter Bestwerte.
- **Statistik:** Segment Tag/Woche/Monat, Metrik-Chips, Periodennavigation in
  einer Karte, große Zahl + Vergleich zur Vorperiode, Balkendiagramm mit Ziellinie,
  „Tippe auf einen Tag für Details“, Bestwerte-Liste mit Pokal-Icons.

## Übertragung auf Pace Life (fachlich)

Das Referenzmaterial bestimmt Form und Interaktion, nicht den Inhalt. Pace Life
übersetzt die Bausteine auf eigene Daten:

| Pace Social | Pace Life |
|---|---|
| Schritte heute / Tagesziel | Erledigte Gewohnheiten heute / geplante Gewohnheiten |
| Tagesziel ändern | Tag anpassen (Pace Adaptive) |
| Regionen-Positionen | Life Mode, Serie, Routinen, Life Paths |
| Deine Woche (Schritte) | Deine Woche (Tagesfortschritt in %) |
| Deine Gruppen | Deine Kreise (ausdrücklich lokal/Demo) |
| Rankings-Tab | Entwicklung (Paths, Chapters, Experiments, Statistik) |
| Social-Tab | Kreise |
| Profil-Tab | Profil (Einstellungen, Erinnerungen, Backup, Pace Connect) |

## Bewusste Abweichungen

- **Wortmarke:** Das Original-Logoasset wurde nicht übergeben. Pace Life zeichnet
  „pace“ in der gerundeten Systemschrift nach und ergänzt „life“. Das ist eine
  Systemschrift-Annäherung, kein Originalasset; Profil → Über Pace Life und
  VoiceOver weisen darauf hin. Das echte Asset kann ohne Codeumbau ersetzt werden.
- **Zurück-Navigation:** Der Zurück-Link bleibt als native Navigationsleiste
  fixiert statt mitzuscrollen. Damit bleiben Edge-Swipe, VoiceOver und
  Accessibility-Verhalten vollständig nativ.
- **Werte:** Pace Life zeigt keine erfundenen Schritt-, Ranking- oder Gruppendaten.

## Offene visuelle Prüfungen

- Systematischer Screenshot-Vergleich jeder neuen Ansicht (Simulator) gegen diese
  Messwerte. Ergebnisse stehen in `IMPLEMENTATION_STATUS.md`.
- Abnahme auf dem physischen iPhone, kleinere/größere Displays, VoiceOver.
- Pixelgenaue Übereinstimmung wird nicht behauptet: Videokompression und die
  fehlende Originalschrift der Wortmarke begrenzen die Genauigkeit.

## Screenshot-Vergleich (3344d22)

Echte Simulatoraufnahmen (siehe `docs/screenshots`) gegen die Messwerte oben.
✓ = entspricht der Referenz, ≈ = bewusst angepasst/angenähert, ✗ = offene Abweichung.

| Bereich | Referenz (Pace Social) | Pace Life (Simulator) | Bewertung |
|---|---|---|---|
| Kopfzeile | Wortmarke links, gefüllter „Anpassen“-Knopf rechts, darunter Begrüßung + Kalender/Glocke | identisch aufgebaut; rechts Kalender + Statistik statt Glocke | ✓ / ≈ (Wortmarke Systemschrift) |
| Kachelreihe | 4 Positionskacheln mit Icon, Chevron, Label, `#1`, Ort | 4 Kacheln Mode/Serie/Routinen/Paths mit gleichem Aufbau | ✓ |
| Hauptkarte | Titel + Akzentlink, große Zahl, „von …“, Balken, „Noch …“, Ring 21 %, Doppelkachel | gleicher Aufbau („Tag anpassen“, 1 von 3, 56 %, Routinen/Minuten) | ✓ |
| Serienkarte | Flammenkreis, „0 Tage“, „Heute offen“ | gleich, zusätzlich „Rekord“ | ✓ |
| Wochenkarte | Balken Mo–So, Y-Achse, Ziellinie, heute dunkel, zwei Kennzahlen, Fußzeile | gleich; erreichte Tage zusätzlich in `goalReachedFill` | ✓ / ≈ |
| Kalenderkarte | Monatsraster, erreichte Tage grün gefüllt mit Wert | gleich (Wert „3/3“ statt Schrittzahl) | ✓ |
| Dock | Mint-Fläche, gefülltes Icon, fette Beschriftung, feste Position | gleich, auch auf Unterseiten | ✓ |
| Unterseiten | „‹ Home“, Wortmarke, großer Titel, Aktionen als Mint-Quadrate | gleich („‹ Heute“, „‹ Entwicklung“) | ✓ |
| Profil-Darstellung | Segmente Automatisch/Hell/Dunkel, aktiv dunkelgrün | identisch | ✓ |
| Stepper/Quick-Picks | große Zahl mit −/+ in Mint-Quadraten, Wertekacheln | Adaptive-Zeitbudget identisch aufgebaut | ✓ |
| Dark Mode | sehr dunkle Petrol-Flächen, Mint-Akzente | gleiche Tokens | ✓ |
| Leerzustände | Icon im Kreis, Titel, Text | gleich | ✓ |
| Wortmarke | Originallogo | Systemschrift-Annäherung „pace life“ | ≈ (Asset ausstehend) |
| Anpassen-Modus | ×, Größe, Griff an jeder Karte, Akzentrahmen | vorhanden; Screenshot folgt nach grünem Lauf | offen |

Nicht geprüft: physisches iPhone, kleine/große Displays, VoiceOver-Abnahme, alle
langen RU-Texte. Pixelgenaue Gleichheit wird nicht behauptet.
