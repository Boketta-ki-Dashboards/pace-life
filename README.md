# Pace Life — iOS

Native, lokale SwiftUI-App für iPhone mit iOS 17+, Swift 6 und Xcode 16 oder neuer. Der Entwicklungsbranch implementiert Life Modes, Habits, eigenständige Routinen, Life Paths, Pace Adaptive, einen Wochen-/Monatskalender, einen modularen Homescreen, private Life Chapters mit Fotos, Life Experiments und einen lokalen Pace-Circles-Testmodus. Die sieben langfristigen Module bleiben in [Roadmap](docs/ROADMAP.md) und [Produktspezifikation](docs/PRODUCT_SPEC.md) verankert.

## In Xcode öffnen und auf dem iPhone testen

1. Dieses Repository klonen, den Branch `codex/pace-life-offline-beta` auswählen und `PaceLife.xcodeproj` öffnen. Das lokale Package `Packages/PaceLifeCore` wird ohne externe Abhängigkeiten eingebunden; kein Generator oder Paketmanager ist zum Öffnen nötig.
2. Scheme **PaceLife** auswählen. Unter **Signing & Capabilities** beim Target **PaceLife** dein Apple-Entwicklerteam wählen. Falls nötig `com.boketta.pacelife` in eine eigene eindeutige Bundle-ID ändern. Es ist kein fremdes Team vorkonfiguriert.
3. iPhone verbinden, dem Mac vertrauen und den Entwicklermodus am iPhone aktivieren. Gerät als Run Destination wählen und mit **⌘R** starten. Ein kostenloses Personal Team kann für lokale Gerätetests verwendet werden; dessen Apple-Limits gelten.
4. Eine Gewohnheit erstellen, Wochentage/Ziel wählen und heutigen Fortschritt erfassen. Einen Life Mode anlegen, Gewohnheiten zuordnen und aktivieren. Home-Widgets unter „Home anpassen“ sortieren/ausblenden. App schließen und erneut öffnen: Eingaben und Einstellungen bleiben erhalten.

Es gibt kein Login, keinen Server und keine benötigten API-Schlüssel. Die App startet ohne erfundene Nutzerdaten. Das Original-Wordmark wurde nicht geliefert; die Oberfläche kennzeichnet den Text-Ersatz.

## Build und Tests

```sh
# Plattformunabhängige Domain-/Persistenztests (Swift 6)
swift test --package-path Packages/PaceLifeCore

# Auf macOS mit Xcode 16+ und installiertem iOS-Simulator:
xcodebuild -project PaceLife.xcodeproj -scheme PaceLife \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build

# Wählt einen tatsächlich installierten iPhone-Simulator und führt UI-Tests aus:
scripts/test-ios.sh
```

Das Xcode-Projekt ist eingecheckt. Nach Hinzufügen/Entfernen von Swift-Dateien lässt es sich mit `python3 scripts/generate_project.py` reproduzierbar aktualisieren. [GitHub Actions](.github/workflows/ios.yml) enthält Core-Tests sowie einen macOS-Simulator-Build mit UI-Tests. Ein angelegter Workflow ist noch kein bestandener Lauf. Tatsächliche Ergebnisse und offene Gerätetests stehen in [IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md).

## Architektur und Datenschutz

SwiftUI → `@Observable AppModel` → `LifeStore`-Use-Cases → `StateRepository`. Der atomare, versionierte JSON-Store liegt in Application Support im privaten App-Container; unter iOS mit vollständigem Dateischutz. Lokale Gerätedatensicherungen können App-Daten enthalten. Ein Lesefehler überschreibt keine Daten; Schreibfehler übernehmen keine ungespeicherten Änderungen in den angezeigten Zustand. Keine Netzwerk-SDKs, Telemetrie oder Cloud-Synchronisierung. Details: [Architektur](docs/ARCHITECTURE.md).

Pace Social wird ausschließlich von Claude betreut. Kein Zugriff auf dessen Repository, keine produktiven Supabase-Änderungen und keine eigenmächtige Account-Verknüpfung. Circles ist ausdrücklich ein lokaler Testmodus mit Demo-Mitgliedern; Connect meldet weiterhin „noch nicht verfügbar“. Referenzvideos bleiben private Chat-Anhänge und gehören niemals ins Repository.

## Projektanforderungen

[AGENTS.md](AGENTS.md), [Kickoff](05_CODEX_KICKOFF_PROMPT.md), [Designsystem](docs/DESIGN_SYSTEM.md), [Testanforderungen](docs/TEST_AND_RELEASE.md), [Integrationsvertrag](docs/INTEGRATION_CONTRACT.md) und [Videoreferenz](docs/VIDEO_REFERENCE.md).

Routinen testen: Unter **Heute → Routinen** eine Routine mit mehreren Schritten
anlegen, optional einem Life Mode zuordnen und diesen aktivieren. Routine starten,
einige Schritte erledigen, pausieren und die App neu starten. Teilfortschritt und
Pause bleiben erhalten. Das Routinen-Widget lässt sich unter „Home anpassen“
einblenden. Bestehende Schema-1-Daten werden automatisch verlustfrei übernommen.

Life Paths testen: **Entwicklung → Life Paths**, Ziel mit mehreren Meilensteinen
anlegen. Einen Minuten-Meilenstein mit einer Dauer-Gewohnheit verknüpfen (100
Lernstunden = 6000 Minuten). Heute 45 Minuten bei dieser Gewohnheit erfassen: Der
Path zeigt 45 tatsächliche Minuten. Korrekturen ändern diesen Beitrag ohne
Doppelzählung; weitere Meilensteine bleiben unabhängig.

Pace Adaptive testen: Einen Dauer-Habit mit 60 Minuten anlegen, **Heute → Pace
Adaptive** öffnen und 30 Minuten Budget wählen. Vorschlag bestätigen, 30 Minuten
erfassen: angepasstes Tagesziel erreicht, ursprüngliches Ziel erst zur Hälfte.
Der echte Wert fließt in verknüpfte Paths. Neustart erhält beide Ziele und den
Istwert. Bereits erstellte Tagespläne bleiben eingefroren; einzelne Ziele können
bearbeitet oder ihre Anpassung zurückgenommen werden.

Kalender testen: Unter **Heute** das Kalender-Symbol öffnen, zwischen Woche und
Monat wechseln und Tage auswählen. Historische Werte stammen aus gespeicherten
Ergebnissen; Zukunftspläne sind ausdrücklich eine Vorschau mit dem aktuellen Mode.

Life Chapters testen: **Entwicklung → Life Chapters → +**. Titel, Zeitraum,
Kategorie und optional verknüpfte Paths speichern. Im Kapitel Fotos über den nativen
Picker auswählen, eine Erinnerung bzw. einen Meilenstein anlegen und die App neu
starten. Ein archivierter Path bleibt verknüpft. Kapitel lassen sich archivieren,
wiederherstellen und nach Bestätigung löschen. Fotos bleiben privat im App-Container.
Die vier Haupttabs unterstützen natives horizontales Paging und den festen Pace-Dock.

Life Experiments testen: **Entwicklung → Life Experiments → +**, Zeitraum und
mindestens eine Messgröße wählen. Optionale Ausgangswerte selbst erfassen. Im
Experiment tägliche Check-ins eingeben, leere Felder als fehlende Daten belassen.
Ein erneuter Check-in am selben Tag korrigiert die Werte. Diagramm und Vergleich
zeigen nur eingegebene Beobachtungen. Abschließen, Reflexion bearbeiten oder als
neues Experiment ohne alte Messwerte wiederholen. Neustart erhält alle Einträge.

Pace Circles testen: **Circles → Circle erstellen**, optional ausdrücklich lokale
Demo-Mitglieder und Rollen hinzufügen. Eine Challenge mit Zeitraum und Ziel anlegen.
Eigene oder simulierte Tagesbeiträge erfassen; ohne aktive Freigabe bleibt der
Beitrag privat und fehlt in der Gruppensumme. Einen Habit-Beitrag gezielt auswählen
und freigeben; spätere Korrekturen aktualisieren dieselbe Quelle. Neustart prüfen,
Freigabe widerrufen und erneut starten. Auch archivierte Challenges erlauben den
Widerruf. Es gibt keine Online-Mitglieder, Nachrichten oder Synchronisierung.

Echte Simulator-Screenshots werden in den CI-Artefakten bereitgestellt; Download
und verbleibende visuelle Prüfungen: [docs/screenshots](docs/screenshots/README.md).

Routine mit Path verbinden: Im neuen Meilenstein unter **Beitragsquelle** eine
Routine wählen (binär oder Anzahl). Nur vollständig erledigte gespeicherte
Sessions ab Path-Start zählen. Teilfortschritt bleibt in der Routine erhalten.
Korrekturen aktualisieren denselben Path-Beitrag; geplante Minuten werden nicht
als tatsächliche Arbeitszeit verbucht.
