# Phase 1 – Implementierungs- und Prüfstand

Stand: 30. Oktober 2026. Native iPhone-App für iOS 17+, Swift 6, Xcode 16+. **Der iOS-Build und die Ausführung auf einem iPhone sind noch nicht verifiziert.**

## Implementiert

- Eingechecktes `PaceLife.xcodeproj`, gemeinsames Scheme `PaceLife`, lokales Swift-Package, reproduzierbarer Projektgenerator ohne externe Abhängigkeiten.
- Life Modes: Anlegen, Bearbeiten, Löschen, manuelles Aktivieren/Deaktivieren, Habit-Auswahl als Tagesvorlage, erhaltene Aktivierungshistorie.
- Habits: Name, Wochentage, binär/Zähler/Minuten, Bearbeiten, Archivieren mit erhaltener Historie; heutige Werte setzen/ändern/zurücksetzen.
- Persistente Tages-Snapshots für Ziel und Zieltyp; Mode-/Zieländerungen verfälschen gespeicherte Erfüllungen nicht.
- Home: tatsächlicher Tagesfortschritt, aktiver Mode, fällige Habits; Widget-Reihenfolge und Sichtbarkeit gespeichert.
- Vier native Root-Tabs; lokale Einstellungen für Auto/Hell/Dunkel und DE/EN/RU.
- Atomarer versionierter JSON-Store im App-Container; iOS-Dateischutz, sichtbarer Fehlerzustand statt automatischem Datenreset.
- Alle 23 Design-Farbpaare, Karten/Buttons/Ring/Header, Dynamic-Type-Basis und expliziter Logo-Platzhalter.
- Geplante Module transparent benannt; Circles/Connect-Interfaces ausschließlich als Unavailable-Capabilities, keine Netzwerk-/Auth-Anbindung.

## Tatsächlich ausgeführte Prüfungen

- Swift 6.0.3 unter Linux im offiziellen Docker-Image, ohne Netzwerk im Testcontainer: **16 XCTest-Tests bestanden, 0 Fehler**. Die separate Ausgabe „Testing Library: 0 tests“ gehört zum ungenutzten Swift-Testing-Runner; die 16 Tests wurden durch XCTest ausgeführt.
- Geprüft: Frequenzen, DST/lokale Tagesgrenzen, Zeitzonen-Deduplizierung, historische Zieltypen/-werte, Teilfortschritt, Mode-Wechsel/Löschung, Archive, Persistenz-Roundtrip inklusive Widgets/Sprache/Theme, Fehler-Rollback, beschädigte/neuere Schemata und inkonsistente Daten.
- Alle 23 Farbpaare gegen die schriftliche Spezifikation abgeglichen.
- Swift-App/UI-Testquellen per Swift-Frontend auf Syntax geprüft; das ersetzt keine Apple-SDK-Typprüfung.
- Xcode-Projekt als OpenStep-Property-List geprüft; Projektgenerator und Schemes geprüft. Das ersetzt keinen `xcodebuild`-Lauf.

## Noch auszuführen

- `scripts/test-ios.sh` auf macOS mit Xcode 16+ und installiertem iPhone-Simulator. Fünf XCUITests sind implementiert: Habit-Erfüllung/Undo nach Neustart, Mode-Aktivierung nach Neustart, Widget-Sichtbarkeit nach Neustart, Sprachwechsel/Persistenz, Dock/Navigation.
- Echter iPhone-Start mit eigenem Signing-Team; lokale Daten nach App-Neustart und gesperrtem/entsperrtem Gerät prüfen.
- Kleine/große iPhone-Größen, Landscape, größte Dynamic-Type-Stufen, VoiceOver, DE/EN/RU und Dark/Light visuell abnehmen.
- Tastatur/Safe Areas, Scroll-Enden, native Back-Gesten, Widget-Drag und Interaktionskonflikte auf Gerät prüfen. Horizontales Root-Paging wurde im ersten Abschnitt bewusst nicht eingeführt; dessen spätere Umsetzung benötigt eigene Swipe-/Cancel-Abnahme.
- Visueller Videoabgleich ausstehend: Beide privaten MP4-Anhänge überschreiten das 32-MiB-Transferlimit. Kein Video/Frame wurde angesehen oder veröffentlicht. Original-Wordmark und finale App-Icon-Assets fehlen.
- Eine vorhandene CI-Datei ist kein bestandenes CI-Ergebnis. Aktuellen GitHub-Actions-Lauf separat prüfen.

## Nächste Entwicklungsabschnitte

Phase 2: Life Paths mit Zielen/Meilensteinen und Habit-Verknüpfungen; Pace Adaptive mit nachvollziehbaren, ausdrücklich bestätigten Tagesanpassungen. Ursprüngliche Ziele bleiben erhalten, reduzierte Ziele gelten nicht automatisch als voller Abschluss.

Weitere offene Funktionen: wiederkehrende Mode-Pläne, eigenständige Routinen, Benachrichtigungen, Export/Import, vollständige Streak-/Kalenderoberfläche, Chapters, Experiments und freigegebene Backendintegration. Kein App-Store-Release oder Anspruch einer vollständigen Implementierung aller sieben Module.

## Offline-Beta-Sprint – Abschnitt A

Ausgangsstand: `c2299e5`, remote Phase-1-Branch am Sprintstart unverändert. Der gemeldete Actions-Lauf 41043535208 ist öffentlich als fehlgeschlagen bestätigt (Exit 65). Seine vollständigen Logs erfordern einen GitHub-Login; die vom Nutzer gelieferte Fehlermeldung nennt einen x86_64-App-Compile gegen ein nur arm64 gebautes Simulator-Package.

Der Projektgenerator ließ `ONLY_ACTIVE_ARCH` offen. Die App kann dadurch in Debug beide Simulatorarchitekturen anfordern, während Xcodes Swift-Package-Target nur die aktive Destination baut. Die Korrektur setzt konsistent Xcodes normale Policy: Debug `YES`, Release `NO`. Keine Architektur wird ausgeschlossen oder fest auf arm64 gesetzt. CI prüft native Simulator-Builds/UI-Tests auf Apple Silicon und Intel sowie einen generischen Release-Simulator-Build. Der Erfolg dieser Korrektur wird erst nach dem neuen CI-Lauf bestätigt.

Der erste Korrekturlauf 41046026637 erreicht auf Apple Silicon nun die eigentliche SwiftUI-Kompilierung. Er deckt einen weiteren Phase-1-Fehler auf: `Font.title3.semibold()` ist keine SwiftUI-API. Korrigiert zu `Font.title3.weight(.semibold)`. Zwei neue Tests mit dem eingefrorenen Schema-1-Datenbestand bestanden; aktuell insgesamt **18 Core-Tests, 0 Fehler**. Die Schema-Version bleibt bis zur getesteten Migration unverändert bei 1.

## Fortsetzung am 3. November 2026 – Widget-Stabilisierung

Remote-Ausgangspunkt geprüft: `codex/pace-life-offline-beta` bei `232cd520`.
Actions-Lauf 41046372623: Core-Tests und Simulator-Build auf **beiden** Runnern
(`macos-15` und `macos-15-intel`) erfolgreich; UI-Test für ausgeblendetes
Fortschritts-Widget fehlgeschlagen (Zeile 105), vier andere UI-Tests bestanden.
Damit ist die frühere Architektur-/SwiftUI-Buildblockade behoben.

Der Widget-Editor startet jetzt außerhalb des Sortiermodus; Sortieren wird über
„Bearbeiten“ gezielt aktiviert. Der Regressionstest prüft den Schalterzustand
bereits vor dem Speichern sowie die Anzeige vor und nach dem Neustart. Dadurch
werden fehlgeschlagene Umschaltgesten von Persistenzfehlern unterschieden.
Projektgenerator reproduzierbar, `git diff --check` bestanden. Die Bestätigung
der UI-Korrektur folgt im neuen macOS-CI-Lauf; lokal ist kein Xcode verfügbar.

## Schema 2 und Routinen – 3. November 2026

- Schema 1 wird über ein explizites Legacy-DTO gelesen, validiert und ohne
  Dateischreibzugriff migriert. Erst eine erfolgreiche Änderung schreibt atomar
  Schema 2. Alle bisherigen Felder bleiben erhalten. Das Routinen-Widget wird
  bei Migration hinten und ausgeblendet ergänzt; neue Installationen zeigen es.
- Schema 2 verlangt Routinen und Tages-Sessions als Pflichtfelder. Fehlende
  Felder, beschädigte/neuere Dateien und extern ausgetauschte Dateien werden
  abgewiesen; der sichtbare Zustand bleibt bei Schreibfehlern unverändert.
- Routinen: Erstellen/Bearbeiten, Beschreibung, Wochentage, optionale Tageszeit,
  Mode-Zuordnung, sortierbare Schritte mit optionaler Dauer, Start, Teilabschluss,
  Pause/Fortsetzen, Rückgängig pro Schritt, Archiv/Wiederherstellen und Verlauf.
  Tages-Snapshots behalten Titel, Schritt-IDs, Reihenfolge und Dauer. Ein erneuter
  Start setzt denselben Tag fort. Mode-Löschung löst nur die Vorlagen-Zuordnung.
- Home verbindet fällige Routinen mit dem aktiven Mode und zeigt echte
  Teilfortschritte. Die Routinenverwaltung bleibt auch bei verborgenem Widget
  erreichbar. Neue Texte sind DE/EN/RU lokalisiert.
- **24 Core-XCTest-Tests unter Swift 6.0.3/Linux bestanden, 0 Fehler**.
  Enthalten: vollständiger Schema-1-Felderhalt, striktes Schema 2, wiederholtes
  Laden, Schreibfehler, Fremdersatz, Mode-/Routine-/Neustartablauf, Teilfortschritt,
  Pause, Archiv und Vorlagenänderung. SwiftUI/UI-Testquellen syntaxgeprüft.
- Ein zusätzlicher XCUITest prüft Anlegen, Teilabschluss, Pause und Wiederaufnahme
  nach Neustart. Apple-SDK-Typprüfung und UI-Test dieser Erweiterung folgen in CI;
  Syntaxprüfung ist ausdrücklich kein iOS-Buildnachweis.
- Offen: wiederkehrende automatische Mode-Aktivierung, historische Habit-
  Planrevisionen/Kalender, Paths, Adaptive, Chapters, Experiments, lokale Circles.
  Geplante Uhrzeiten erzeugen noch keine Benachrichtigungen.

### Widget-Ursache durch CI eingegrenzt

Lauf 41619060817 baut erfolgreich, scheitert aber an der neuen Sofortprüfung:
Der XCUI-Tap auf die Mitte des SwiftUI-Switch-Elements lässt dessen Wert bei `1`.
Der Accessibility-Rahmen enthält die gesamte beschriftete Zeile. Der Test tippt
nun gezielt auf den rechten nativen Schalter und wartet auf den gewünschten Wert.
Sichtbarkeits- und Persistenzassertionen bleiben unverändert erhalten. Der erste
Sortiermodus-Fix allein war damit noch keine bestätigte Fehlerbehebung.
Routinen-Commit 23caf4a: Simulator-Build und 24 Core-Tests inzwischen auf beiden
Mac-Runnern erfolgreich; UI-Tests laufen noch.

## Life Paths – 3. November 2026

- Nutzbare Übersicht, Details, Erstellen/Bearbeiten, Lebensbereich, Beschreibung,
  Start-/Zieldatum, mehrere sortierbare Meilensteine, aktive/pausierte/abgeschlossene/
  archivierte Paths, Wiederaktivierung und Home-Widget. Zugriff über Entwicklung.
- Meilensteine: binär, Zähler oder Minuten; manuelle Tagesbeiträge mit Korrektur
  oder exakt eine Habit-Quelle. Quell-IDs und Einheiten bleiben nach Erstellung
  fest. Es zählen ausschließlich tatsächliche Werte in der gespeicherten Einheit
  ab Path-Start; Archivierung und Änderungen der Habit-Vorlage löschen nichts.
- Beiträge werden berechnet, nicht bei Anzeige inkrementiert. Ein korrigierter
  Habit-Wert korrigiert genau einen Beitrag. Ein Path wird nur nach vollständigen
  Meilensteinen manuell abgeschlossen; spätere Korrekturen können ihn wieder öffnen.
- Schema 3 liest Schema 1 und 2 über explizite Migrationen. Routinen/Sessions und
  vorhandene Widget-Einstellungen bleiben erhalten; Paths-Widget bei Migration
  hinten und ausgeblendet. Neue Felder `paths` und `pathEntries` sind obligatorisch.
- **28 Core-Tests bestanden, 0 Fehler**; SwiftUI-Quellen syntaxgeprüft, Projekt
  reproduzierbar erzeugt. Ein zusätzlicher UI-Test erfasst einen Meilenstein und
  prüft ihn nach Neustart; aktueller Apple-SDK-/UI-Nachweis folgt in CI.
- Noch offen: Routine-Beiträge zu Paths, Titelbilder, Änderung einer bestehenden
  Beitragsregel mit eigener historischer Gültigkeit und reichhaltige Diagramme.
  Das Modul ist ein nutzbarer erster Ausbau, nicht die vollständige Sprintabnahme.

## Pace Adaptive – 3. November 2026

- Reine deterministische Engine mit Zeitbudget, Energie, Belastung, geschützten
  Minuten-Habits, festen Routine-Dauern und höherem Gewicht für aktive Life Paths.
  Aktivitäten ohne Zeitangabe werden ausdrücklich außerhalb der Zeitschätzung
  ausgewiesen. Feste Aufgaben über Budget erzeugen keine falsche Budgetgarantie.
- Vorschläge benötigen Einzelzustimmung; annehmen, ablehnen, Ziel manuell ändern
  und zurücknehmen sind gespeichert. Ein eingefrorener Tagesplan ersetzt sich
  nicht durch Doppeltippen oder spätere Mode-/Vorlagenänderungen. Entscheidungen
  für vergangene Tage werden abgewiesen. Null bedeutet zurückgestellt, nicht erledigt.
- Originalziel, angenommenes Tagesziel und tatsächlicher Wert bleiben getrennt
  sichtbar. Home zeigt angepasste Ziele zusätzlich, sein ursprünglicher
  Erfüllungsstatus bleibt ehrlich. Path-Beiträge verwenden weiterhin nur Istwerte.
- Native Adaptive-Oberfläche über Heute/Entwicklung, Tageshistorie und Home-Widget;
  sämtliche neuen Texte DE/EN/RU. Bestehende Schema-1/2/3-Daten werden auf Schema 4
  migriert, das neue Widget bleibt für bestehende Nutzer zunächst verborgen.
- **33 Core-Tests bestanden, 0 Fehler**. Getestet: Budgetgrenzen, deterministische
  Vorschläge, unbekannte Dauer, geschützte Aufgaben, Path-Gewichtung, Ablehnung,
  Annahme/individuelles Ziel, Original-Snapshots, Neustart, Rückgängig, frühere
  Tage, ungültige Werte, Schreibfehler und Null-Ziel. Der integrierte Ablauf
  Mode → Habit → Adaptive → tatsächlicher Fortschritt → Path ist geprüft.
- Acht XCUITests sind jetzt vorhanden. Der neue Adaptive-Test prüft, dass ein
  erfülltes reduziertes Tagesziel nicht das ursprüngliche Ziel als erfüllt ausgibt.
  Aktuelle CI-Builds/UI-Tests werden getrennt nachverfolgt; lokal nur Syntaxcheck.
- Offen: Neuberechnung eines bereits eingefrorenen Tagesplans, Reduktion einzelner
  Routine-Schritte und freie Prioritäten/Zeitfenster. Routinen werden aktuell
  bewusst als feste Aufgaben berücksichtigt. Keine KI-API oder Online-Verbindung.
