# Pace Life — iOS

Native, lokale SwiftUI-App für iPhone mit iOS 17+, Swift 6 und Xcode 16 oder neuer. Der erste Entwicklungsabschnitt implementiert Life Modes, Habits und einen modularen Homescreen. Die sieben langfristigen Module bleiben in [Roadmap](docs/ROADMAP.md) und [Produktspezifikation](docs/PRODUCT_SPEC.md) verankert.

## In Xcode öffnen und auf dem iPhone testen

1. Dieses Repository klonen und `PaceLife.xcodeproj` öffnen. Das lokale Package `Packages/PaceLifeCore` wird ohne externe Abhängigkeiten eingebunden; kein Generator oder Paketmanager ist zum Öffnen nötig.
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

Pace Social wird ausschließlich von Claude betreut. Kein Zugriff auf dessen Repository, keine produktiven Supabase-Änderungen und keine eigenmächtige Account-Verknüpfung. Circles und Connect melden explizit „noch nicht verfügbar“. Referenzvideos bleiben private Chat-Anhänge und gehören niemals ins Repository.

## Projektanforderungen

[AGENTS.md](AGENTS.md), [Kickoff](05_CODEX_KICKOFF_PROMPT.md), [Designsystem](docs/DESIGN_SYSTEM.md), [Testanforderungen](docs/TEST_AND_RELEASE.md), [Integrationsvertrag](docs/INTEGRATION_CONTRACT.md) und [Videoreferenz](docs/VIDEO_REFERENCE.md).
