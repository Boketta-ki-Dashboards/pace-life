# Echte Simulatoraufnahmen

Zehn unveränderte PNGs aus `XCTAttachment(screenshot: app.screenshot())`, aufgenommen
am 4. November 2026 auf **iPhone 16 Pro, iOS 18.5, Xcode 16.4, Apple Silicon**.
Nur isolierte Testdaten, keine Nutzerfotos, Mockups oder Originalreferenzvideos.
Auflösung jeweils 1206 × 2622 Pixel. Die englischen Titel in den neuen Modulen
sind bewusst eingegebene Testdaten; die App-Oberfläche ist deutsch.

Quelle: Code `b6e87808a0704108e83db402bfb38d33f429aa80`,
[CI 41829938956](https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41829938956),
[Apple-Artefakt 13325150588](https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41829938956/artifacts/13325150588).
Dieser Apple-Job besteht mit 53 Core- und 14 UI-Tests sowie Debug-/Release-Builds.
Das ist ein commitgenauer Bildnachweis, keine Behauptung zum jeweiligen Branch-HEAD.

| Ansicht | Original-PNG |
|---|---|
| Home, hell | [Heute](pace-today-light-b6e8780.png) |
| Home, dunkel | [Heute](pace-today-dark-b6e8780.png) |
| Life Modes, leerer Startzustand | [Modes](pace-modes-light-b6e8780.png) |
| Life Paths, leerer Startzustand | [Paths](pace-paths-light-b6e8780.png) |
| Pace Adaptive | [Adaptive](pace-adaptive-light-b6e8780.png) |
| Life Chapters, gespeicherte Erinnerung nach Neustart | [Chapter](pace-chapters-detail-light-b6e8780.png) |
| Life Experiments, gespeicherter Messwert | [Experiment](pace-experiments-detail-light-b6e8780.png) |
| Pace Circles, ausdrücklich freigegebener Beitrag | [Challenge](pace-circle-challenge-light-b6e8780.png) |
| Einstellungen, hell | [Profil](pace-profile-light-b6e8780.png) |
| Einstellungen, dunkel | [Profil](pace-profile-dark-b6e8780.png) |

## Sichtprüfung und Grenzen

Alle zehn Bilder wurden tatsächlich geöffnet und visuell geprüft. In diesen
Ansichten sind Safe Areas, Kartenbreiten, Abstände, Textumbrüche und Light-/Dark-
Kontraste plausibel; der feste Dock hebt Icon und Text gemeinsam mintfarben hervor.
Unterhalb des sichtbaren Ausschnitts liegender Inhalt bleibt scrollbar. Die
zugehörigen UI-Tests prüfen zusätzlich Scrollen, Paging und erreichbare Eingaben.
Die leeren Modes-/Paths-Aufnahmen sind keine Prüfung langer Listen oder Titel.

Die zusätzliche Aufnahme mit größter Accessibility-Schrift zeigte zerrissene
mehrzeilige Dock-Beschriftungen. Deshalb wurde `dfd03d7` umgesetzt: kompakte
Tab-Texte und nativer Large Content Viewer, während Seiteninhalte weiter skalieren.
Die korrigierte Accessibility-Aufnahme und deren Nachprüfung stehen noch aus;
das fehlerhafte Vorher-Bild wird nicht als freigegebene Referenz eingecheckt.

Dies ist eine begrenzte Sichtprüfung, keine vollständige Designabnahme. VoiceOver,
kleinere/größere Displays, sämtliche langen DE/EN/RU-Texte und reale iPhones bleiben
zu prüfen. Originalvideos und Wordmark fehlen weiterhin; visuelle
1:1-Übereinstimmung ist nicht verifiziert. Der beschriftete Logo-Platzhalter folgt
der verbindlichen Vorgabe im Designsystem.

## Ergänzende Token-Kontrastprüfung

Aus den dokumentierten sRGB-Farbwerten berechnete Kontrastverhältnisse (relative
Luminanz, keine Schätzung aus komprimierten Bildschirmbildern):

| Vordergrund / Hintergrund | Hell | Dunkel |
|---|---:|---:|
| textPrimary / background | 17,95:1 | 17,38:1 |
| textSecondary / surface | 5,64:1 | 7,82:1 |
| onSelection / selectionFill | 10,84:1 | 13,39:1 |
| onAccent / accentStrong (PaceButton primär) | 9,25:1 | 13,18:1 |

Diese vier Textkombinationen überschreiten 4,5:1. Das ist keine vollständige
Barrierefreiheitsprüfung aller Zustände, Charts, Transparenzen oder Systemelemente.

## Reproduzierbare Herkunft

`provenance.json` enthält Quell-Commit, CI-Lauf, Dateigröße und SHA-256 je PNG.
Die Dateien wurden ohne Skalierung oder Bildbearbeitung aus Xcode-Anhängen übernommen.
Der reine Lese-Workflow `screenshot-evidence.yml` prüft Repository/Branch/Commit,
liest das freigegebene Artefakt und gibt nur die in `export-request.json` genannten
Bilder mit Prüfsummen aus. Er besitzt keine Repository-Schreibrechte. Erst nach
lokaler Hash- und Sichtprüfung werden Bilder regulär auf den Beta-Branch gepusht.
