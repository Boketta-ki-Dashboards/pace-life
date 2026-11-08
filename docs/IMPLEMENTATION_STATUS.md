# Pace Life – Implementierungs- und Prüfstand

Stand: **8. November 2026** (Design-Neuaufbau und Schema 10, Claude Code); ältere Abschnitte unten vom 4. November. Ausschließlich `Boketta-ki-Dashboards/pace-life`,
Branch `codex/pace-life-offline-beta`; Ausgangs-HEAD `74931679` remote verifiziert.
Alle Entwicklungsabschnitte sind einzeln gepusht und per Remote-HEAD überprüft.
Keine Merges nach main, kein Force-Push, keine anderen Repositories oder Backends.

## Bestandsaufnahme 8. November 2026 (Claude Code, Design-Neuaufbau)

Ausgangs-HEAD `1dfb424`. Lokal mit Swift 6.0.3/Linux: **54 Core-Tests, 0 Fehler**.
Letzter macOS-Lauf (`c4547e8`, [CI 41851293004](https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41851293004)):
Apple Silicon vollständig grün (Core, 15 UI, Debug/Release); Intel scheiterte in
den UI-Tests.

Die Funktionsbasis aller lokalen Module ist real (siehe Tabelle unten). Die
Oberfläche war dagegen generisch: Jeder Bereich öffnete ein eigenes Sheet mit
„Fertig“-Knopf, Startseite und Entwicklung bestanden aus gestapelten Buttons,
Listen nutzten Standard-`List`/`Form`, die Kopfzeile zeigte „Pace Life“ plus
sichtbares „Logo-Platzhalter“, die Startseite hatte keine Woche, keinen Kalender,
keine Serie und keinen Bearbeitungsmodus. Die Pace-Social-Originalvideos wurden
erstmals tatsächlich ausgewertet: [Referenzanalyse](DESIGN_REFERENCE_ANALYSIS.md).
Ergebnis: Die Farbtokens stimmen, Layout, Navigation und Komponenten nicht.

## Tatsächlich implementierter Umfang aller sieben USPs

| Modul | Implementierter Stand | Verbleibender Umfang |
|---|---|---|
| Life Modes | CRUD, manuelle Aktivierung, Habit-Auswahl; **Wochenplan mit transparenter Übersteuerungsregel** (manuelle Wahl gilt für den Tag), **bis zu drei Tagesprioritäten**, eingefrorene Tagespläne je Tag (historische Planänderungen bleiben erhalten), Routinen mit Mode-Zuordnung, Schritten, Teilabschluss, Pause, Erinnerungen und Home-Widget. | Mode-Duplikation/Archiv, Zeitfenster innerhalb eines Tages, physische Geräteabnahme. |
| Life Paths | Mehrere Paths, Meilenstein-Typen, Habit-/Routine-/manuelle Beiträge ohne Doppelzählung, Statuswechsel/Archiv, **Pace-Detailseite mit Ring, Meilenstein-Timeline und Fortschrittsverlauf (Stufendiagramm)**, Home-Widget mit nächstem Meilenstein. | Titelbilder, versionierte Änderungen einer Beitragsregel. |
| Pace Adaptive | Deterministische Vorschläge aus Zeit/Energie/Belastung, geschützte Habits, Routine-Dauern, Path-Gewichtung; Annahme/Ablehnung/Bearbeiten/Rückgängig, **Neuplanung des Tages unter Erhalt getroffener Entscheidungen**, Prioritäten vorab geschützt, Tageshistorie, Hero-Aktion „Tag anpassen“. | Flexible Routine-Schritte, freie Zeitfenster. |
| Life Chapters | Private Timeline, Titel/Text/Kategorie/Zeitraum, Path-Verknüpfung, Erinnerungen und persönliche Meilensteine, Bearbeiten/Archiv/Wiederherstellen/Löschen, native Fotoauswahl und separate lokale JPEG-Dateien; DE/EN/RU. | Neustart/Archiv/Editieren und nativer Fotoablauf im Simulator bestanden; Export und vollständige Geräte-/Designabnahme offen. |
| Life Experiments | 7/14/30 Tage und frei wählbarer Zeitraum; individuelle numerische, Minuten-, Skalen- und Ja/Nein-Messgrößen; Ausgangswerte, tägliche Check-ins/Korrekturen, Punktdiagramme, ehrliche Vergleiche, Reflexion, Abschluss/Wiederholung/Archiv, Habit-Links. | Neustart/Korrektur auf beiden Simulator-Architekturen bestanden; vollständige Geräte-/Designabnahme und automatischer Datenimport offen. |
| Pace Circles | Lokale Circles mit bearbeitbaren Demo-Mitgliedern/Rollen, Gruppenzielen, datierten Challenges, Beiträgen, Verlauf, Abschluss/Archiv und ausdrücklicher widerruflicher Freigabe. | Freigabe/Widerruf/Neustart auf beiden Simulator-Architekturen bestanden; keine echten Mitglieder oder Synchronisierung. |
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
Root-Pager ohne ungenutzten äußeren Stack, separate modale Detail-/Editor-Navigation; keine manuelle
Root-Drag-Geste, keine globale Toolbar-Ausblendung und keine UIKit-Delegate-Overrides. Schrift, Farben und Komponenten verwenden das bestehende Designsystem.

Nachgewiesene UI-Tests prüfen schnelle/langsame Swipes, Abbrechen, vertikales
Scrollen, Dock-Position/-Höhe und Editorisolation. Die native Detail-Zurückgeste
besteht mit einem echten 50-ms-Testkontakt und unveränderten Ergebnis-Assertions,
auch nach Entfernen aller UIKit-Overrides. Inaktive Seiten werden aus dem
Accessibility-Baum ausgeschlossen.

Die echte Screenshot-Sichtprüfung fand bei größter Accessibility-Schrift unleserlich
umgebrochene Dock-Texte. Korrektur `dfd03d7`: einzeilige kompakte Tab-Beschriftungen
mit nativem Large Content Viewer; Seiteninhalte skalieren weiterhin. Der Nachtest
verlangt kompakte Dock-Geometrie **und** tatsächlich vergrößerte Seiteninhalte sowie
alle bisherigen Touch-/Scroll-/Tastaturbedingungen. Auf Apple Silicon besteht
`dfd03d7` mit 53 Core-/15 UI-Tests und Debug-/Release-Build; Intel läuft noch.
Die korrigierte größte Schrift wurde visuell geprüft: vollständige einzeilige
Tab-Namen bei weiterhin vergrößertem Seiteninhalt. Elf echte Aufnahmen stehen
unter [screenshots](screenshots/README.md) mit Herkunft und Prüfsummen.
Originalvideos/Wordmark fehlen; visuelle 1:1-Übereinstimmung, VoiceOver, weitere
Displaygrößen und reale iPhones sind nicht verifiziert.

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

Die aktuelle Core-Domäne besteht am 4. November mit Swift 6.0.3/Linux: **54 XCTest-Fälle,
0 Fehler**. Projektgenerator, Swift-Syntax- und Diff-Prüfung bestanden. Linux ist
kein Ersatz für die tatsächliche iOS-SDK-Prüfung in den folgenden macOS-Läufen.

| Code | Tatsächlicher Nachweis |
|---|---|
| `76e0572` vor diesem Auftrag | 37 Core, acht UI, Debug/Release auf Apple Silicon und Intel; [CI 41631877527](https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41631877527). |
| `50dd2dd` | Alle drei neuen Module und Routine-Paths/Schema 8: beide Architekturen 53 Core, 13 UI, Debug/Release bestanden; [CI 41810514373](https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41810514373). |
| `d2b17e4` | Beide Architekturen 53 Core, 14 UI plus vorgezogene Back-Regression, Debug/Release bestanden; [CI 41828056482](https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41828056482). |
| `b6e8780` | Vereinfachte reine SwiftUI-Navigation ohne UIKit-Overrides: Apple 53 Core, 14 UI, Back-Regression und Debug/Release bestanden; Quelle der eingecheckten Standard-Screenshots. Intel: XCTest-AX-Abfrage hing nach einem Experiment-Tap-Timeout, anschließend Jobabbruch; [CI 41829938956](https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41829938956). |
| `7ee521e` | Nativer Fotoablauf auf beiden Architekturen bestanden. Apple vollständig 53 Core, 15 UI, Debug/Release; Intel 53 Core, 14/15 UI, Debug/Release. Ein Screenshot-Sheet öffnete nach Tabwechsel nicht; [CI 41832182819](https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41832182819). |
| `dfd03d7` | Kompakte Accessibility-Tabbar und endlicher 50-ms-Touch für einmaliges Öffnen der Screenshot-Sheets. Keine Wiederholungen maskieren Fehler, die Sheet-/Persistenz-Assertions bleiben verbindlich. Apple vollständig 53 Core, 15 UI, Debug/Release bestanden, Intel noch im Nachlauf; [CI 41837583213](https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41837583213). |

Die Suite enthält **15 UI-Tests**: die bestehenden acht Regressionen plus Paging,
Screenshots, Chapters, Experiments, lokale Circles, größte Dynamic-Type-Stufe und
native Fotoauswahl. Der Routine-Test prüft zusätzlich Path-Quellenauswahl und
Wiederherstellung. Der Foto-Test prüft Picker-Abbruch, echten Import, dekodiertes
Bild nach Neustart, Entfernen und einen weiteren Neustart. Die künstliche
Foto-Testdatei ist ausdrücklich als Eingabe gekennzeichnet, kein App-Mockup.

Bestätigter Simulator: **iPhone 16 Pro, iOS 18.5, Xcode 16.4**. Keine physischen
Gerätetests. [Elf echte PNGs samt Sichtprüfungsgrenzen](screenshots/README.md) sind
im Repository. Die reine Lese-Exportpipeline benötigt keine CI-Schreibrechte.

## Nächste Arbeiten für Claude Code

1. Den aktuellen Nachlauf der Datumskorrektur und die verbleibende Intel-UI-Prüfung
   vollständig kontrollieren. Ein Build allein ist keine Designabnahme.
2. Auf kleinem/großem iPhone und physischem Gerät lange DE/EN/RU-Texte, VoiceOver,
   Large Content Viewer sowie Kalender-/Chart-/Back-Gesten abnehmen. Die native
   Fotoauswahl ist automatisiert getestet; weitere Fotoformate und große Bestände
   brauchen noch gezielte Gerätetests.
3. Automatische wiederkehrende Life Modes und historische Habit-Planrevisionen
   umsetzen. Aktuelle Streaks verwenden weiterhin den heutigen Wochenplan; frühere
   Planänderungen sind nicht rekonstruierbar und dürfen nicht erfunden werden.
4. Tages-/Wochenroutinen vertiefen, Meilenstein-/Fortschrittsdiagramme ausbauen,
   Adaptive-Neuplanung, Prioritäten/Zeitfenster, lokale Erinnerungen mit Zustimmung,
   Export/Backup und weitere frei konfigurierbare Home-Widgets ergänzen.
5. Connect/echte Circles erst nach freigegebenem Backend-/Identitätsvertrag.

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

## Datumseditoren: gregorianische Schlüssel erhalten

Die beim Chapter-/Experiment-/Circle-Ausbau hinzugefügte Datumshilfe verwendete
`Calendar.current` zur Rekonstruktion gespeicherter gregorianischer Jahreszahlen.
Bei buddhistischem oder japanischem Systemkalender konnte dadurch ein falsches
Editor-Datum entstehen. `DayKey.localDate` verwendet nun ausdrücklich den
gregorianischen Kalender und übernimmt nur die lokale Zeitzone; bestehende
Schlüssel und JSON-Dateien werden nicht verändert. UTC-Tagesarithmetik bleibt
unverändert. Der neue 54. Core-Test prüft drei Kalendertypen, Sommer-/Winterzeit
sowie Berlin, Kiritimati und Los Angeles gegen feste erwartete Zeitpunkte und
verlustfreien DayKey-Roundtrip. Alle 54 Core-Tests lokal bestanden; eigener
iOS-Nachlauf für diese kleine Korrektur ausstehend.

Die Screenshot-Sichtprüfung zeigte außerdem eine alleinstehende, unbeschriftete
Circle-Gesamtsumme unter dem Ring. Sie trägt jetzt die vorhandene DE/EN/RU-
Beschriftung „Fortschritt“ und ist wie die Eigen-/Demo-Summen ausgerichtet.
Der existierende Freigabe-/Widerrufstest prüft weiterhin genau denselben Wert;
kein Test-Identifier oder erwarteter Beitrag wurde verändert. Syntax-/Diff-Prüfung
bestanden, vollständiger iOS-Nachlauf folgt. Die bisherige Circle-Aufnahme bleibt
bis zum neuen echten Export ausdrücklich dem älteren Quell-Commit zugeordnet.

Die echte Nachaufnahme von `531286e` zeigte, dass der wiederverwendete Home-Text
„Dein Tagesfortschritt“ für die Challenge-Gesamtsumme sachlich falsch ist. Die
Beschriftung erhält deshalb einen eigenen Circle-Schlüssel: „Gemeinsamer
Fortschritt“ / „Shared progress“ / „Общий прогресс“. Der bestehende Circle-UI-Test
prüft diese Bedeutung zusätzlich zu Privat/Freigabe/Widerruf und Neustart.
Die fehlerhaft beschriftete Zwischenaufnahme wird nicht in die Galerie übernommen.
`531286e` besteht auf Apple Silicon mit 54 Core-/15 UI-Tests und Debug/Release;
Intel scheiterte im vorgezogenen Navigation-/Foto-Schritt. Dessen vollständige
Jobdiagnose steht noch aus; keine neue grüne Intel-Abnahme wird behauptet.
