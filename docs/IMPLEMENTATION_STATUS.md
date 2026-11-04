# Pace Life – Implementierungs- und Prüfstand

Stand: **4. November 2026**. Ausschließlich `Boketta-ki-Dashboards/pace-life`,
Branch `codex/pace-life-offline-beta`; Ausgangs-HEAD `74931679` remote verifiziert.
Alle Entwicklungsabschnitte sind einzeln gepusht und per Remote-HEAD überprüft.
Keine Merges nach main, kein Force-Push, keine anderen Repositories oder Backends.

## Tatsächlich implementierter Umfang aller sieben USPs

| Modul | Implementierter Stand | Verbleibender Umfang |
|---|---|---|
| Life Modes | Bestehendes CRUD/manuelle Aktivierung/Habit-Auswahl erhalten. Eigenständige Routinen mit Mode-Zuordnung, Wochentagen, optionaler Uhrzeit, sortierbaren Schritten/Dauer, Teilabschluss, Pause/Fortsetzen, Tages-Snapshots, Archiv/Wiederherstellen und Home-Widget. | Automatische wiederkehrende Mode-Wechsel, Mode-Duplikation/Archiv, Tagesprioritäten und vollständige historische Habit-Planrevisionen. |
| Life Paths | Mehrere Paths, Lebensbereich/Beschreibung/Zieldatum, binäre/Zähler/Minuten-Meilensteine, Tagesbeiträge, Habit-Verknüpfung oder vollständige Routine-Sessions, nachvollziehbarer Fortschritt, Statuswechsel/Archiv, Verlauf und Home-Widget. | Titelbilder, historisch versionierte Änderungen einer Beitragsregel und umfassende Fortschrittsdiagramme. |
| Pace Adaptive | Lokale deterministische Vorschläge aus Zeit/Energie/Belastung, geschützten Habits, Routine-Dauern und aktiven Paths; ausdrückliche Annahme/Ablehnung, individuelle Ziele, Rückgängig, Tageshistorie und Home-Widget. | Neuplanung eines schon eingefrorenen Tages, flexible Routine-Schritte, freie Prioritäten/Zeitfenster. |
| Life Chapters | Private Timeline, Titel/Text/Kategorie/Zeitraum, Path-Verknüpfung, Erinnerungen und persönliche Meilensteine, Bearbeiten/Archiv/Wiederherstellen/Löschen, native Fotoauswahl und separate lokale JPEG-Dateien; DE/EN/RU. | Chapter-Neustart/Archiv/Editieren im Simulator bestanden; native Fotoauswahl, visuelle Abnahme und Export offen. |
| Life Experiments | 7/14/30 Tage und frei wählbarer Zeitraum; individuelle numerische, Minuten-, Skalen- und Ja/Nein-Messgrößen; Ausgangswerte, tägliche Check-ins/Korrekturen, Punktdiagramme, ehrliche Vergleiche, Reflexion, Abschluss/Wiederholung/Archiv, Habit-Links. | Experiment-Neustart/Korrektur im Apple-Silicon-Simulator bestanden; neuere Regression/visuelle Abnahme läuft, kein automatischer Datenimport. |
| Pace Circles | Lokale Circles mit bearbeitbaren Demo-Mitgliedern/Rollen, Gruppenzielen, datierten Challenges, Beiträgen, Verlauf, Abschluss/Archiv und ausdrücklicher widerruflicher Freigabe. | Freigabe/Widerruf/Neustart auf Apple Silicon bestanden; keine echten Mitglieder oder Synchronisierung. |
| Pace Connect | Vorhandene Capability-Protokolle melden nicht verfügbar; keine Netzwerkverbindung oder Identität wird vorgetäuscht. | Vollständige Adapter-/Berechtigungsarchitektur nach freigegebenem externen Vertrag. |

Die drei neuen lokalen Module haben echte Eingaben, Persistenz, Fehlerbehandlung
und DE/EN/RU-Texte. Eine Implementierung ist keine vollständige Produkt-/Designabnahme.
Die späteren Online-Funktionen von Circles und Connect sind nicht implementiert.

## Native Navigation und Design

Vier unveränderte Tabs: Heute, Entwicklung, Kreise, Profil. Ein nativer SwiftUI-
Page-TabView liefert interaktive Fingerbewegung, Einrasten und Abbrechen. Dock und
Pager teilen denselben Auswahlzustand. Der Dock bleibt außerhalb der scrollenden
Seiten im unteren Safe-Area-Inset; mintfarbener Hintergrund, Icon und Text markieren
die Auswahl. Vollständige Touch-Flächen, konstante Schriftstärke und Reduce Motion.
Ein Root-NavigationStack, separate modale Detail-/Editor-Navigation; keine manuelle
Root-Drag-Geste. Schrift, Farben und Komponenten verwenden das bestehende Designsystem.

Nachgewiesene UI-Tests prüfen schnelle/langsame Swipes, Abbrechen, vertikales
Scrollen, Dock-Position/-Höhe und Editorisolation. Der Detail-Back-Swipe-Test
und weitere Screenshotansichten sind im Lauf von `50dd2dd` bestanden; präzisierter
Gesten-Nachtest von `536b4cd` noch ausstehend. Ergebnisse
siehe den commitbezogenen Prüfstand unten. Kleinere/größere Displays, größte
Dynamic-Type-Stufen und VoiceOver bleiben offen. Originalvideos und Wordmark
liegen nicht auswertbar vor; visuelle 1:1-Übereinstimmung ist nicht verifiziert.

## Verbundene Daten und Persistenz

Aktueller Writer: **Schema 8**. Explizite Leser für Schema 1 bis 7; unveränderte
Alt-UUIDs, Erfüllungen/Ziel-Snapshots, Mode-Aktivierungen, Routine-Sessions, Widgets
und Einstellungen. Neue Arrays bleiben leer; keine historischen Daten werden
erfunden. Migration nur im Speicher, Dateiänderung erst beim erfolgreichen atomaren
Write. Unbekannte Versionen, korrupte Daten oder fremder Dateiersatz führen zum
sichtbaren Fehler. Failed Writes ändern nicht den angezeigten State.

- Chapters: private Timeline, verknüpfte archivierte Paths bleiben erhalten. Fotos
  sind separate UUID-JPEG-Dateien (max. 1600 Pixel, max. 12 MiB), ohne originale
  EXIF-/GPS-Daten. Import schreibt zuerst die Datei, dann die JSON-Referenz. Ein
  JSON-Fehler entfernt nur die neue Datei. Bereinigung erhält alle aktiven und
  archivierten Referenzen; fehlende/defekte Bilder erscheinen als nicht verfügbar.
- Experiments: eindeutige tägliche Check-ins, typgerechte Werte, fehlende Tage
  bleiben fehlend. Messdefinitionen/Baselines sind nach Erstellung fest. Diagramme
  zeigen echte Punkte, Vergleiche behaupten keine Kausalität. Wiederholung erzeugt
  neue IDs und leere Messungen/Baselines. Zivile Tagesarithmetik ohne DST-Drift.
- Circles: alle weiteren Mitglieder sind ausdrücklich Demo. Eigene und simulierte
  Beiträge werden getrennt ausgewiesen. Private Werte zählen erst nach Freigabe.
  Ein Grant auf eine gespeicherte HabitCompletion folgt deren Korrekturen genau
  einmal. Widerruf funktioniert auch nach Archivierung und verändert keine private
  Quelle. Manuelle zusätzliche Arbeit nicht nochmals als Habit-Beitrag buchen.
- Routine-Paths: vollständige gespeicherte Sessions zählen einmal ab Path-Start,
  Teilfortschritt zählt noch nicht. Nur binär/Anzahl, keine erfundenen Ist-Minuten
  aus geplanten Schrittdauern. Spätere Vorlagenänderung/Archivierung erhält die
  Session-Snapshots. Korrekturen können einen Path-Abschluss wieder öffnen.

Der Core-Integrationstest `testConnectedDailyWorkExperimentChapterAndExplicitCircleGrant`
führt alle zehn angeforderten Schritte über dieselben LifeStore-/Persistenzpfade aus:
Path mit Habit/Routine → Mode → Adaptive-Zustimmung → echte Leistung → Path-Update →
Experiment/Messung → Chapter-Meilenstein → bewusster Circle-Grant. Er prüft danach
Korrektur, fehlende Doppelzählung, Neustart und Widerruf ohne privaten Datenverlust.
Dies ist ein Domain-Integrationstest, kein behaupteter durchgehender Geräte-UI-Test.

## Commitgenauer Prüfstand

**Aktueller lokaler Nachweis:** `50dd2dd`, Swift 6.0.3/Linux, **53 Core-XCTest-Tests,
0 Fehler**; Projektgenerator reproduzierbar, SwiftUI-Syntaxprüfung und Diff-Prüfung
bestanden. Linux ersetzt keine iOS-SDK-Typprüfung.

| Code | Nachweis |
|---|---|
| `76e0572` (vor diesem Auftrag) | 37 Core-Tests, acht UI-Tests, Debug/Release auf Apple Silicon und Intel bestanden, [CI 41631877527](https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41631877527). |
| `9d8a140` | Apple Silicon: 42 Core, 11 UI, Debug/Release und echte Screenshot-Exporte bestanden; Intel bei UI nach Jobbudget abgebrochen. [CI 41805696013](https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41805696013). |
| `00de43d` | Apple Silicon vollständig bestanden: 46 Core, 12 UI, Debug/Release, Screenshot-Export. Intel-UI scheiterte vor Teststart an „Timed out waiting for AX loaded notification“. [CI 41807623995](https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41807623995). |
| `cd7f521` | Bootstatus abwarten und UI seriell starten; keine Tests entfernt. [CI 41809158539](https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41809158539): Beide Architekturen vollständig bestanden: 46 Core, zwölf UI, Debug/Release und Screenshot-Export. |
| `161cecb` | Lokale Circles. [CI 41810190437](https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41810190437): 50 Core und Simulator-Builds beider Architekturen bestanden. Apple Silicon: 12/13 UI; neuer Back-Swipe-Test fehlgeschlagen, Circle-Test und Screenshot-Test bestanden. |
| `50dd2dd` | Routine-Paths, Schema 8. [CI 41810514373](https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41810514373): Apple Silicon vollständig bestanden: 53 Core, 13 UI, Debug/Release und Screenshot-Export. Intel-Core/Simulator-Build bestanden, UI laufend. |

Die Suite enthält 13 UI-Tests: bestehende acht Regressionen plus Paging,
Screenshots, Chapters, Experiments und lokale Circles. Der Routine-Test umfasst
jetzt auch die Path-Quellenauswahl und Wiederherstellung. Die neuen Abläufe werden
nicht allein aufgrund bestandener Core-Tests als simulatorverifiziert bezeichnet.

Echte Simulatoraufnahmen und Downloadhinweise: [screenshots/README.md](screenshots/README.md).
Bisher bestätigtes Gerät: **iPhone 16 Pro, iOS 18.5, Xcode 16.4** im Apple-Silicon-
CI-Lauf. Keine echten iPhone-Tests. Keine visuelle Sichtprüfung der PNGs: der
Artefakt-Download ist in dieser Cloud mit HTTP 403 blockiert. Eine automatische
CI-Commit-Lösung wurde wegen zusätzlicher Schreibrechte abgelehnt; CI behält
`contents: read`. Deshalb sind hier noch keine neuen PNG-Dateien eingecheckt.

## Nächste Arbeiten für Claude Code

1. Aktuellen CI-Lauf vollständig prüfen; eventuelle Fehler anhand der Joblogs und
   xcresult-Artefakte beheben. Keine Assertions entfernen oder abschwächen.
2. Auf Mac/Simulator echte Fotoauswahl, Auswahlabbruch, Import/Neustart/Löschen und
   fehlende Dateien abnehmen. Core-Dateitests ersetzen diesen nativen UI-Ablauf nicht.
3. Die echten Screenshots visuell prüfen, repräsentative PNGs unter docs/screenshots
   mit Commit/Gerät benennen. Safe Areas, lange DE/EN/RU-Texte, Dynamic Type,
   VoiceOver, kleine/große iPhones und horizontale Gestenkonflikte abnehmen.
4. Automatische wiederkehrende Life Modes und historische Habit-Planrevisionen
   umsetzen. Aktuelle Streaks verwenden weiterhin den heutigen Wochenplan; frühere
   Planänderungen sind nicht rekonstruierbar und dürfen nicht erfunden werden.
5. Adaptive-Neuplanung, Prioritäten/Zeitfenster, lokale Erinnerungen mit Zustimmung,
   Export/Backup und weitere frei konfigurierbare Home-Widgets ergänzen.
6. Connect/echte Circles erst nach freigegebenem Backend-/Identitätsvertrag.

Technische Einstiegspunkte: AppModel/Composition Root unter `PaceLife/App`, neue
Feature-Views und typisierte Übersetzungen unter Features/Localization; Domain und
Tests in `Packages/PaceLifeCore`. `LifeStore.transaction` validiert und persistiert
vor UI-Übernahme. Single-Writer-JSON bleibt bewusst erhalten; bei sehr großen
Historien/Medienbeständen Hintergrundadapter und Bildcache prüfen. Keine neue
Grundarchitektur oder produktive Anbindung erforderlich.

## Auf dem eigenen iPhone installieren

Branch aktualisieren → `PaceLife.xcodeproj` öffnen → Scheme **PaceLife** → eigenes
Team und ggf. eindeutige Bundle-ID unter Signing & Capabilities wählen → iPhone
vertrauen/Entwicklermodus aktivieren → Gerät als Run Destination → **⌘R**.
Ausführliche Testabläufe für alle lokalen Module stehen in [README.md](../README.md).
Bei Migration ggf. verborgene neue Home-Widgets unter „Home anpassen“ aktivieren.
Nach dem Schreiben von Schema 8 keine ältere Beta über denselben Datencontainer
installieren: ältere Writer lehnen das neue Schema absichtlich ab.

### Offener Navigationsnachtest

Circle-CI `41810190437` auf Apple Silicon: 50 Core, Debug/Release und 12 von
13 UI-Tests bestanden. Der neue Circle-Freigabe-/Widerruf-Ablauf und alle erweiterten
Screenshotansichten bestehen. Die neue Edge-Swipe-Assertion im Path-Detail schlägt
fehl. Die Detail-Navigationsleiste wird deshalb ausdrücklich sichtbar gehalten;
der Nachtest prüft zusätzlich den nativen Back-Button und startet die Wischgeste
am tatsächlichen modalen Navigationsbereich statt am gesamten App-Rahmen.
Die Rückkehr zur Path-Liste und zum unveränderten Root-Tab bleibt verpflichtend.
Dieser Nachtest ist noch nicht bestanden; keine abgeschlossene Designabnahme.

Nachtrag: `50dd2dd` / `41810514373` hat auf Apple Silicon alle 13 UI-Tests
inklusive ursprünglichem Back-Swipe, Circle-Widerruf und Routine-Path-Auswahl
bestanden. 53 Core-Tests sowie Debug/Release ebenfalls erfolgreich.
`536b4cd` / [Nachtest 41812897844](https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41812897844)
prüft die präzisere Gestenlokalisierung und explizite native Detail-Navigation;
Core/Debug beider Architekturen bestanden, UI noch laufend.
