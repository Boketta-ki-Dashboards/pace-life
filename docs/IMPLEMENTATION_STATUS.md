# Pace Life – Implementierungs- und Prüfstand

Stand: **4. November 2026**. Entwicklungsbranch: `codex/pace-life-offline-beta`.
Ausgangspunkt dieses Durchlaufs war der auf GitHub verifizierte Commit `74931679`.
Alle abgeschlossenen Abschnitte wurden einzeln committet, sofort gepusht und der
Remote-Commit anschließend überprüft. Keine Änderungen an Pace Social oder Supabase.

## Tatsächlich nutzbare Funktionen

| Modul | Implementierter Stand | Verbleibender Umfang |
|---|---|---|
| Life Modes | Bestehendes CRUD/manuelle Aktivierung/Habit-Auswahl erhalten. Eigenständige Routinen mit Mode-Zuordnung, Wochentagen, optionaler Uhrzeit, sortierbaren Schritten/Dauer, Teilabschluss, Pause/Fortsetzen, Tages-Snapshots, Archiv/Wiederherstellen und Home-Widget. | Automatische wiederkehrende Mode-Wechsel, Mode-Duplikation/Archiv, Tagesprioritäten und vollständige historische Habit-Planrevisionen. |
| Life Paths | Mehrere Paths, Lebensbereich/Beschreibung/Zieldatum, binäre/Zähler/Minuten-Meilensteine, Tagesbeiträge, Habit-Verknüpfung oder vollständige Routine-Sessions, nachvollziehbarer Fortschritt, Statuswechsel/Archiv, Verlauf und Home-Widget. | Titelbilder, historisch versionierte Änderungen einer Beitragsregel und umfassende Fortschrittsdiagramme. |
| Pace Adaptive | Lokale deterministische Vorschläge aus Zeit/Energie/Belastung, geschützten Habits, Routine-Dauern und aktiven Paths; ausdrückliche Annahme/Ablehnung, individuelle Ziele, Rückgängig, Tageshistorie und Home-Widget. | Neuplanung eines schon eingefrorenen Tages, flexible Routine-Schritte, freie Prioritäten/Zeitfenster. |
| Life Chapters | Private Timeline, Titel/Text/Kategorie/Zeitraum, Path-Verknüpfung, Erinnerungen und persönliche Meilensteine, Bearbeiten/Archiv/Wiederherstellen/Löschen, native Fotoauswahl und separate lokale JPEG-Dateien; DE/EN/RU. | Chapter-Neustart/Archiv/Editieren im Simulator bestanden; native Fotoauswahl, visuelle Abnahme und Export offen. |
| Life Experiments | 7/14/30 Tage und frei wählbarer Zeitraum; individuelle numerische, Minuten-, Skalen- und Ja/Nein-Messgrößen; Ausgangswerte, tägliche Check-ins/Korrekturen, Punktdiagramme, ehrliche Vergleiche, Reflexion, Abschluss/Wiederholung/Archiv, Habit-Links. | Neue Simulator- und visuelle Abnahme läuft; kein automatischer Datenimport. |
| Pace Circles | Lokale Circles mit bearbeitbaren Demo-Mitgliedern/Rollen, Gruppenzielen, datierten Challenges, Beiträgen, Verlauf, Abschluss/Archiv und ausdrücklicher widerruflicher Freigabe. | Neue Simulator-CI erforderlich; keine echten Mitglieder oder Synchronisierung. |
| Pace Connect | Vorhandene Capability-Protokolle melden nicht verfügbar; keine Netzwerkverbindung oder Identität wird vorgetäuscht. | Vollständige Adapter-/Berechtigungsarchitektur nach freigegebenem externen Vertrag. |

Keines der sieben Gesamtmodule wird als vollständig abgenommen deklariert.
Die neuen Funktionen verwenden echte lokale Daten und DE/EN/RU-Texte.

## Verbundene Abläufe

- Mode aktivieren → zugeordnete Routinen/Habits erscheinen → zwei von vier
  Schritten erledigen → pausieren → Neustart → unveränderter Teilfortschritt.
  Vorlagenänderung/Mode-Löschung erhält die ursprünglichen Session-Schritte.
- Dauer-Habit mit Path-Meilenstein verbinden → 45 Minuten erfassen → 45 Minuten
  Beitrag → Wert korrigieren → derselbe Beitrag wird korrigiert, nicht verdoppelt.
  Habit-Archivierung oder späterer Zieltypwechsel verliert keine alten Minuten.
- Tagesbudget reduzieren → Adaptive-Vorschlag ausdrücklich bestätigen → tatsächliche
  15 Minuten erfassen → reduziertes Ziel und ursprüngliche 60 Minuten bleiben
  getrennt. Originalfortschritt 25 %, Path-Beitrag genau 15 Minuten. Rückgängig
  verändert keine geleistete Arbeit. Ablehnung kann den aktuellen Plan über Budget
  lassen; die Oberfläche zeigt dies ausdrücklich an.
- Kalender unter Heute → Wochen-/Monatsansicht → Habit-Ergebnisse, Routine-Sessions
  und Adaptive-Ziele ansehen. Vergangene vollständige Pläne sind unbekannt und
  werden nicht erfunden. Zukunftspläne sind gekennzeichnete Vorschauen des
  aktuellen Modes und Wochenplans. Keine historische Quote aus fehlenden Daten.

## Persistenz und Migration

Aktueller Writer: **Schema 8** (zusätzlich Routine-Path-Quellen). Separate DTOs lesen Schema 1 bis 7. Alle alten
UUIDs, Habits, Ziel-Snapshots, Erfüllungen, Modes/Aktivierungen, Widgets und
Einstellungen bleiben erhalten. Neue Widgets werden bei Migration hinten und
zunächst verborgen ergänzt. Lesen migriert ausschließlich im Speicher; erst ein
erfolgreicher Schreibvorgang ersetzt die Datei atomar. Aktuelle Pflichtfelder
werden streng decodiert. Beschädigte, unbekannte neuere oder zwischenzeitlich
extern ersetzte Dateien werden nicht stillschweigend überschrieben.

Gespeicherte Routine-Schritte und Adaptive-Originalziele bleiben von späteren
Vorlagen getrennt. Path-Abschlüsse verlangen echte Beiträge bis zum Abschlussdatum;
eine Korrektur kann den Abschluss wieder öffnen. Archivierung erhält das gültige
Abschlussdatum, das auch in den Path-Details angezeigt wird. Entkräftet eine
spätere Korrektur diesen historischen Abschluss, wird das Datum entfernt, der
Path bleibt aber archiviert. Einzelner MainActor-Writer,
kein Mehrprozess-/Mehrgeräte-Sync. Große Datenmengen benötigen später einen
Hintergrund- oder Datenbankadapter; Fotos liegen als begrenzte, geschützte JPEG-Dateien außerhalb des JSON.

## Nachgewiesene Tests und CI

- **37 Core-XCTest-Tests unter Swift 6.0.3/Linux bestanden, 0 Fehler.**
  Separate Swift-Testing-Ausgabe mit 0 Tests gehört zum ungenutzten zweiten Runner.
- Abgedeckt: ursprüngliche 18 Regressionen; Schema-1-Felderhalt/1→4, Schema-2/3-
  Übernahme, strikte Pflichtfelder, fremder Dateiersatz, Schreibfehler/Rollback,
  Routine-Neustart/Snapshots/Pause, Habit-Path-Beiträge/Korrekturen/Einheiten,
  historische Abschlussdaten einschließlich Archiv/Neustart/Korrektur,
  Adaptive-Budgets/Zustimmung/Originalziele/Neustart/
  Rückgängig/Null-Ziele sowie Kalender über DST und Jahresgrenzen.
- Projektgenerator reproduzierbar; `git diff --check` bestanden. Neue SwiftUI-
  und UI-Testquellen zusätzlich syntaxgeprüft. Das ersetzt keine SDK-Typprüfung.

Geprüfter App- und Testcode: **`76e0572a18ca857547730ece0e170758f88c5322`**.
[Lauf 41631877527](https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41631877527)
prüft genau diesen Stand; spätere reine Dokumentationscommits verändern ihn nicht.
Gesamtergebnis: **erfolgreich**. Beide Jobs und ihre vollständigen Logs wurden geprüft.

| Prüfung | Apple Silicon (`macos-15`) | Intel (`macos-15-intel`) |
|---|---|---|
| 37 Core-XCTest-Tests | Bestanden, 0 Fehler | Bestanden, 0 Fehler |
| Reproduzierbares Xcode-Projekt | Bestanden | Bestanden |
| Debug-Simulator-/Test-Build | Bestanden | Bestanden |
| Acht UI-Tests | Bestanden, 0 Fehler | Bestanden, 0 Fehler |
| Generischer Release-Simulator-Build | Bestanden | Bestanden |

Die UI-Tests prüfen Habit-Erfüllung/Rückgängig nach Neustart, Mode-Aktivierung,
Widget-Sichtbarkeit/Wiederherstellung, Sprachwechsel, Routine-Teilfortschritt und
Pause, Path-Beiträge, Adaptive-Ziele sowie Tab-/Scroll-/Kalendernavigation.

Der Archiv-Datumsfix ist mit Persistenz-/Korrekturtest und iOS-Builds abgedeckt.
Die korrigierte Habit-Testsequenz prüft Texteingabe, aktivierten Speicherbutton,
geschlossenes Formular und das Wiederfinden des Habits an der gespeicherten
Home-Scrollposition. Neustart und Rückgängig bleiben Teil desselben Tests.

Die ursprüngliche Simulatorarchitektur-/Font-Blockade ist behoben. Der Widget-
Fehler lag beim XCUI-Tap in der Mitte einer beschrifteten Switch-Zeile. Der Test
trifft nun den rechten nativen Schalter und prüft sofort dessen Wert; Sichtbarkeit
vor/nach Neustart und Wiederherstellung werden weiterhin geprüft. Sortieren wird
im Widget-Editor gezielt aktiviert, statt dauerhaft aktiv zu sein.

## Offene Abnahme und nächste Arbeiten

1. Echten iPhone-Start und Speicherung mit eigenem Signing-Team prüfen.
2. Automatische Mode-Pläne, historische Habit-Wochenpläne/Streaks und Adaptive-
   Neuplanung ausbauen. Aktuelle Streak-Berechnung verwendet weiterhin den heutigen
   Habit-Wochenplan und ist keine historische Rekonstruktion.
3. Neue Experiment-/Circle-Simulatorabläufe und native Fotoauswahl abnehmen;
   Routine-Path-Auswahl ebenfalls im Simulator prüfen. Connect erst gemäß freigegebenem Vertrag.
4. Backup/Export/Import und lokale Benachrichtigungen fehlen. Der Kalender ist eine Ansicht, kein Drag-and-drop-Planer.
5. Klein/groß, Light/Dark, größte Dynamic-Type-Stufen, VoiceOver, Tastatur,
   Safe Areas, Swipe-Back und Widget-Reordering auf Gerät visuell abnehmen.

**Visueller Videoabgleich ausstehend.** In dieser Sitzung lagen keine lesbaren
Originalvideos oder Frames vor. Original-Wordmark und finales App-Icon fehlen.
Kein App-Store-Release, kein behaupteter echter iPhone-Test.

## Erster iPhone-Test

`PaceLife.xcodeproj` auf diesem Branch öffnen → Scheme **PaceLife** → eigenes
Signing-Team und gegebenenfalls eigene Bundle-ID setzen → verbundenes iPhone
mit Entwicklermodus auswählen → ⌘R. Zunächst Habit, Mode und Routine anlegen;
danach unter Entwicklung einen Path verknüpfen und unter Heute Pace Adaptive
öffnen. Werte erfassen, App vollständig beenden und erneut öffnen. Neue Widgets
bei migrierten Daten bei Bedarf unter „Home anpassen“ einblenden.

### Testnavigation im erweiterten Home

Die Testhilfe verlangt, dass das ganze Steuerelement innerhalb des aktiven
Scrollbereichs liegt, unter Berücksichtigung von Dock und Tastatur;
`isHittable` allein reicht bei nur
teilweise sichtbaren Zeilen nicht aus. Zusätzliche Assertions trennen das Öffnen
der Liste vom Wiederfinden der gespeicherten Routine und liefern bei einem Fehler
den Accessibility-Baum. Nach dem Habit-Speichern wird ausdrücklich das geschlossene
Formular bestätigt und zurück zum Habit gescrollt: Die Home-Scrollposition bleibt
beim Schließen eines Sheets erhalten, und außerhalb des sichtbaren Bereichs können
Elemente auch im Accessibility-Baum fehlen. Alle acht UI-Tests bestehen mit
`76e0572` auf beiden Mac-Architekturen.

## Entwicklung am 4. November: natives Root-Paging

Ausgangspunkt: Remote-HEAD `74931679`. Die vier bestehenden Tabs verwenden jetzt
natives interaktives SwiftUI-Page-Paging mit gemeinsamem Auswahlzustand und festem
Safe-Area-Dock. Tippen berücksichtigt Reduce Motion. Keine manuelle Root-Drag-Geste.
Neue UI-Tests prüfen Richtung, schnelle/langsame Swipes, kurzen abgebrochenen Swipe,
vertikales Scrollen, feste Dock-Position und Texteingabe im modalen Editor.
Light-/Dark-Screenshots werden als echte XCTAttachments erzeugt.

Lokale Umgebung: Linux, kein Xcode/Simulator. Die neuen UI-Tests und Screenshots
sind bis zum Abschluss der commitbezogenen macOS-CI **nicht verifiziert**.
Die 37 zuvor bestätigten Core- und acht UI-Tests gelten weiterhin nur für den
oben genannten alten Code-Commit. Visueller Videoabgleich ausstehend.

### Life Chapters – implementiert, iOS-Abnahme läuft

42 Core-XCTest-Tests unter Swift 6.0.3/Linux bestanden (0 Fehler), darunter fünf
neue Chapter-/Medien-/Schema-4-Migrationstests. Alle bisherigen Tests bleiben
aktiv. Projektgenerator und Swift-Syntaxprüfung bestanden; kein lokaler SDK-Build.
Schema 5 verlangt `chapters`; ältere Daten bekommen ausschließlich eine leere
Chronik. Historie und Widget-Reihenfolge bleiben unverändert.

Fotos werden über PhotosPicker ausgewählt, auf maximal 1600 Pixel heruntergerechnet
und ohne originale EXIF-/GPS-Metadaten als JPEG gespeichert (maximal 12 MiB/Datei).
Ein abgebrochener Picker erzeugt keinen Eintrag. Dateien werden vor JSON-Referenzen
atomar geschrieben. Bei fehlgeschlagenem JSON-Schreiben wird nur die neue Datei
entfernt. Löschen von Referenzen erfolgt vor Dateibereinigung; Archive und weitere
Kapitel behalten ihre Fotos. Fehlende/defekte Bilder erscheinen als nicht verfügbar.
Ein Dateibereinigungsfehler wird sichtbar und kann erneut versucht werden.

Neuer UI-Test: Kapitel → Erinnerung → Neustart → Archiv → Neustart →
Wiederherstellen → Bearbeiten → Neustart. Die native Auswahl echter Fotos und
Photo-Library-Abbruch sind noch nicht durch einen Simulatorlauf nachgewiesen.

Chapter-CI `41804646306`: 42 Core-Tests bestanden; iOS-Build wegen fehlendem
expliziten `return` in `ChapterCopy.text` fehlgeschlagen. Separater Korrekturcommit
behebt die Ursache; Erfolg wird erst nach dem neuen Lauf bestätigt.

Paging-Lauf `41803412187` auf Apple Silicon: Core und Debug/Release-Build bestanden;
9/10 UI-Tests bestanden. Der neue Dock-Test verglich die AX-Labelrahmen eines
aktiven und inaktiven Tabs (unterschiedliche Textgeometrie). Die Schrift bleibt
jetzt immer semibold, die Auswahl erfolgt weiter über Mint-Hintergrund/Icon/Text.
Der Test prüft Position **und Höhe des echten Dock-Containers**. Keine Assertion
entfernt oder Toleranz vergrößert. Screenshot-Test bestanden; CI exportiert jetzt
zusätzlich die tatsächlichen XCTAttachments als PNG-Dateien zur visuellen Prüfung.

Chapter-Fixlauf `41804979763`: weiterer Swift-6-Isolationsfehler im PhotoPicker-
Label gefunden. Der lokalisierte Titel wird nun auf dem MainActor vor der
Sendable-Label-Closure aufgelöst. Neuer Simulatorlauf erforderlich.

### Verifizierter Zwischenstand und Life Experiments

`9d8a140` / [CI 41805696013](https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41805696013):
Apple Silicon vollständig erfolgreich: 42 Core-Tests, 11 UI-Tests, Debug-/Release-
Simulator-Build und Screenshot-Export. Der Chapter-Neustart-/Archiv-/Editierablauf
und native Paging-Richtung, Abbrechen, Scrollen und Dock-Geometrie sind enthalten.
Intel zum Zeitpunkt dieses Eintrags noch laufend. Keine echte Geräteabnahme.

Life Experiments: 46 Core-Tests unter Swift 6.0.3/Linux bestanden (0 Fehler), davon
vier neue Tests für mehrere gespeicherte Tage, fehlende Daten, Korrekturen,
Vergleiche, unabhängige Wiederholungen, Wertevalidierung, Datumsgrenzen und Schema
5→6. Neue UI-Prüfung erfasst/korrigiert einen Wert mit zwei App-Neustarts.
Messgrößen, Einheiten und Ausgangswerte sind nach Erstellung fest; Änderungen
können gespeicherte Zahlen nicht umdeuten. Eine Wiederholung erzeugt neue IDs,
leere Messungen und keinen erfundenen Ausgangswert. Fehlende Tage zählen nie als
null. Diagramme zeigen nur echte Messpunkte; Vergleiche sind Beobachtungen ohne
Kausalitätsbehauptung. Schema 6 verlangt beide Experiment-Arrays, ältere Schemas
erhalten leere Arrays. Die neue UI ist bis zur zugehörigen CI ungeprüft.

Screenshot-Artefakte bleiben in GitHub Actions. Der direkte Download in die Cloud
wurde mit HTTP 403 blockiert. Automatische Freigabeprüfung lehnte zusätzliche
CI-Schreibrechte zum Einchecken ab; die CI behält `contents: read`. Daher bisher
keine neuen PNG-Dateien unter `docs/screenshots/` und keine behauptete Sichtprüfung.

Experiment-CI `41807223450`: Core-Tests bestanden, iOS-Build meldet fehlenden
Foundation-Import für `UUID` in `ExperimentCopy.swift`. Separat korrigiert und
mit lokaler Typprüfung der neuen Lokalisierungs-/AppModel-Erweiterung geprüft;
iOS-Nachlauf erforderlich. Der letzte vollständig auf Apple Silicon geprüfte
Code bleibt bis dahin `9d8a140`.

Experiment-Nachlauf `41807623995`: iOS-Builds und 46 Core-Tests bestanden. Der
Apple-Silicon-UI-Runner scheiterte **vor dem Start der Tests** an `Timed out waiting
for AX loaded notification`; keine fehlgeschlagene Experiment-Assertion.
`scripts/test-ios.sh` wartet jetzt mit `simctl bootstatus -b` auf den gewählten
Simulator und deaktiviert parallele UI-Runner/zusätzliche Klone. Alle Testfälle
bleiben aktiv. Das Jobbudget steigt wegen der erweiterten Suite und der gemessenen
Intel-Laufzeit (schon zehn UI-Tests ca. 14,5 Minuten plus Builds) auf 45 Minuten.

### Lokale Pace Circles – implementiert, neue iOS-Abnahme ausstehend

50 Core-XCTest-Tests unter Swift 6.0.3/Linux bestanden (0 Fehler). Vier neue Tests
prüfen Mitglieder/Challenge-Verwaltung, private gegenüber freigegebenen Beiträgen,
Widerruf nach Archivierung, Korrekturen, Neustart, fehlerhafte Writes und Schema 6→7.
Ein verbundener Test kombiniert Habit/Mode/Routine, Path, bestätigtes Adaptive-Ziel,
Experiment-Messung, Chapter-Meilenstein und explizit freigegebenen Habit-Beitrag.
Die Routine besitzt jetzt einen eigenen Meilenstein und zählt genau einmal zum Path.

Circles sind ausschließlich lokale Testdaten. Jedes weitere Mitglied ist als Demo
gekennzeichnet; Namen und Rollen sind keine Online-Identitäten oder Berechtigungen.
Gruppenziele gehören zu datierten Challenges. Eigene und simulierte Beiträge werden
getrennt angezeigt. Persönliche Beiträge bleiben standardmäßig privat. Eine
Freigabe kann einen einzelnen gespeicherten Habit-Wert einschließlich seiner
Korrekturen referenzieren; wiederholtes Speichern vervielfacht ihn nicht. Widerruf
ist auch nach Abschluss/Archiv möglich und verändert die private Quelle nicht.
Kein Netzwerkadapter oder Backend wurde angebunden.

Neuer UI-Test: Circle/Challenge erstellen → privaten Wert speichern → Gesamtwert 0
→ bewusst freigeben → Gesamtwert 30 → Neustart → widerrufen → Neustart → 0.
Zusätzliche echte Light-/Dark-XCTAttachments für Modes, Paths, Adaptive, Chapters
und Experiments sowie nativer Zurück-Swipe im Path-Detail sind vorbereitet. Diese
neuen UI-Prüfungen sind erst nach dem zugehörigen CI-Lauf bestätigt.

### Routine-Beiträge zu Life Paths

53 Core-XCTest-Tests unter Swift 6.0.3/Linux bestanden (0 Fehler). Drei neue Tests
prüfen komplette gegenüber partiellen Sessions, Deduplikation, Templateänderung,
Archiv/Neustart, Korrekturen und historische Path-Abschlüsse. Routine-Quellen sind
ausschließlich binär oder als Session-Anzahl zulässig; geplante Minuten sind keine
gemessene Arbeit. Die Quelle bleibt nach Erstellung fest. Schema 7→8 erhält die
vorhandenen Daten; ältere Meilensteine erhalten keine erfundene Routine-Verknüpfung.
Der verbundene Circle-Test deckt jetzt alle zehn Schritte des beauftragten Ablaufs
auf Domain-/Persistenzebene ab. Der bestehende Routine-UI-Test wählt zusätzlich
eine Routine als Path-Quelle und prüft deren Wert nach Neustart; CI ausstehend.
