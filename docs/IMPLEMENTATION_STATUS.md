# Pace Life – Implementierungs- und Prüfstand

Stand: **3. November 2026**. Entwicklungsbranch: `codex/pace-life-offline-beta`.
Ausgangspunkt dieses Durchlaufs war der auf GitHub verifizierte Commit `232cd520`.
Alle abgeschlossenen Abschnitte wurden einzeln committet, sofort gepusht und der
Remote-Commit anschließend überprüft. Keine Änderungen an Pace Social oder Supabase.

## Tatsächlich nutzbare Funktionen

| Modul | Implementierter Stand | Verbleibender Umfang |
|---|---|---|
| Life Modes | Bestehendes CRUD/manuelle Aktivierung/Habit-Auswahl erhalten. Eigenständige Routinen mit Mode-Zuordnung, Wochentagen, optionaler Uhrzeit, sortierbaren Schritten/Dauer, Teilabschluss, Pause/Fortsetzen, Tages-Snapshots, Archiv/Wiederherstellen und Home-Widget. | Automatische wiederkehrende Mode-Wechsel, Mode-Duplikation/Archiv, Tagesprioritäten und vollständige historische Habit-Planrevisionen. |
| Life Paths | Mehrere Paths, Lebensbereich/Beschreibung/Zieldatum, binäre/Zähler/Minuten-Meilensteine, Tagesbeiträge oder Habit-Verknüpfung, nachvollziehbarer Fortschritt, Statuswechsel/Archiv, Verlauf und Home-Widget. | Routine-Beiträge, Titelbilder, historisch versionierte Änderungen einer Beitragsregel und umfassende Fortschrittsdiagramme. |
| Pace Adaptive | Lokale deterministische Vorschläge aus Zeit/Energie/Belastung, geschützten Habits, Routine-Dauern und aktiven Paths; ausdrückliche Annahme/Ablehnung, individuelle Ziele, Rückgängig, Tageshistorie und Home-Widget. | Neuplanung eines schon eingefrorenen Tages, flexible Routine-Schritte, freie Prioritäten/Zeitfenster. |
| Life Chapters | Noch nicht implementiert; Oberfläche kennzeichnet den Bereich als nicht verfügbar. | Private Chronik, Fotos/Dateiverwaltung, Erinnerungen und Path-Verknüpfungen. |
| Life Experiments | Noch nicht implementiert; Oberfläche kennzeichnet den Bereich als nicht verfügbar. | Messgrößen, Check-ins, fehlende Daten, Diagramme und Auswertungen. |
| Pace Circles | Vorhandener Unavailable-Service und ehrlicher Leerzustand. | Noch keine Gruppen/Challenges, auch kein lokaler Demo-Modus. |
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

Aktueller Writer: **Schema 4**. Separate DTOs lesen Schema 1, 2 und 3. Alle alten
UUIDs, Habits, Ziel-Snapshots, Erfüllungen, Modes/Aktivierungen, Widgets und
Einstellungen bleiben erhalten. Neue Widgets werden bei Migration hinten und
zunächst verborgen ergänzt. Lesen migriert ausschließlich im Speicher; erst ein
erfolgreicher Schreibvorgang ersetzt die Datei atomar. Aktuelle Pflichtfelder
werden streng decodiert. Beschädigte, unbekannte neuere oder zwischenzeitlich
extern ersetzte Dateien werden nicht stillschweigend überschrieben.

Gespeicherte Routine-Schritte und Adaptive-Originalziele bleiben von späteren
Vorlagen getrennt. Path-Abschlüsse verlangen echte Beiträge bis zum Abschlussdatum;
eine Korrektur kann den Abschluss wieder öffnen. Einzelner MainActor-Writer,
kein Mehrprozess-/Mehrgeräte-Sync. Große Datenmengen benötigen später einen
Hintergrund- oder Datenbankadapter; Fotos sind noch nicht eingeführt.

## Nachgewiesene Tests und CI

- **36 Core-XCTest-Tests unter Swift 6.0.3/Linux bestanden, 0 Fehler.**
  Separate Swift-Testing-Ausgabe mit 0 Tests gehört zum ungenutzten zweiten Runner.
- Abgedeckt: ursprüngliche 18 Regressionen; Schema-1-Felderhalt/1→4, Schema-2/3-
  Übernahme, strikte Pflichtfelder, fremder Dateiersatz, Schreibfehler/Rollback,
  Routine-Neustart/Snapshots/Pause, Habit-Path-Beiträge/Korrekturen/Einheiten,
  historische Abschlussdaten, Adaptive-Budgets/Zustimmung/Originalziele/Neustart/
  Rückgängig/Null-Ziele sowie Kalender über DST und Jahresgrenzen.
- Projektgenerator reproduzierbar; `git diff --check` bestanden. Neue SwiftUI-
  und UI-Testquellen zusätzlich syntaxgeprüft. Das ersetzt keine SDK-Typprüfung.
- [Lauf 41620486944](https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41620486944),
  Commit `e44bdf0`: Apple Silicon **24 Core-Tests, sechs UI-Tests, Debug- und
  generischer Release-Simulator-Build erfolgreich**. Damit sind Widget-Ausblenden/
  Wiederherstellen und Routinen-Teilfortschritt/Pause/Neustart dort verifiziert.
- Paths-Commit `cd3bb3c`: Debug-Simulator-Build und 28 Core-Tests auf beiden
  Mac-Runnern erfolgreich; zu diesem Dokumentationsstand laufen die UI-Tests.
- Adaptive-Commit `37cac26`: 33 Core-Tests und Intel-Debug-Simulator-Build erfolgreich;
  nachfolgende Prüfungen laufen noch. Der aktuelle Branch enthält **acht UI-Tests**.
- Jüngste Kalender-/Integrationscommits haben eigene CI-Läufe. Noch laufende oder
  wartende Jobs sind kein bestandener Nachweis. Aktuelle Ergebnisse stehen unter
  [GitHub Actions](https://github.com/Boketta-ki-Dashboards/pace-life/actions).

Die ursprüngliche Simulatorarchitektur-/Font-Blockade ist behoben. Der Widget-
Fehler lag beim XCUI-Tap in der Mitte einer beschrifteten Switch-Zeile. Der Test
trifft nun den rechten nativen Schalter und prüft sofort dessen Wert; Sichtbarkeit
vor/nach Neustart und Wiederherstellung werden weiterhin geprüft. Sortieren wird
im Widget-Editor gezielt aktiviert, statt dauerhaft aktiv zu sein.

## Offene Abnahme und nächste Arbeiten

1. Neueste CI-Läufe inklusive aller acht UI-Tests und beider Release-Builds abschließen.
2. Echten iPhone-Start und Speicherung mit eigenem Signing-Team prüfen.
3. Automatische Mode-Pläne, historische Habit-Wochenpläne/Streaks und Adaptive-
   Neuplanung ausbauen. Aktuelle Streak-Berechnung verwendet weiterhin den heutigen
   Habit-Wochenplan und ist keine historische Rekonstruktion.
4. Chapters/Fotos, Experiments und lokale Circles als nächste echte Module bauen;
   danach Connect gemäß freigegebenem Vertrag. Keine produktive Auth-Anbindung.
5. Backup/Export/Import, lokale Benachrichtigungen und horizontales Root-Paging
   fehlen. Der Kalender ist eine Ansicht, kein Drag-and-drop-Planer.
6. Klein/groß, Light/Dark, größte Dynamic-Type-Stufen, VoiceOver, Tastatur,
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

### Nachtrag: Testnavigation im erweiterten Home

Im Intel-Lauf von `cd3bb3c` bestehen Widget- und Path-Neustarttest. Der Routinen-
Test erreicht nach Neustart die erwartete Liste nicht. Die Testhilfe verlangt
nun, dass das ganze Steuerelement innerhalb des aktiven Scrollbereichs liegt,
unter Berücksichtigung von Dock und Tastatur; `isHittable` allein reicht bei nur
teilweise sichtbaren Zeilen nicht aus. Zusätzliche Assertions trennen das Öffnen
der Liste vom Wiederfinden der gespeicherten Routine und liefern bei einem Fehler
den Accessibility-Baum. Bestätigung dieser Testkorrektur folgt im neuen CI-Lauf.
