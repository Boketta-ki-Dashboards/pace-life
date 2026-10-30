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
