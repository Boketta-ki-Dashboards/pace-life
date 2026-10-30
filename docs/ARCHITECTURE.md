# Pace Life – Architektur
## Zielstack
Native SwiftUI iOS17+, Swift 6 wenn unterstützt, `@Observable`, strukturierte Concurrency, Dependency Injection und lokale Persistenz (SwiftData oder klar begründete Alternative). Keine direkte Backendlogik in Views.

Mögliche Struktur:
```
PaceLife/
  PaceLifeApp.swift
  AppDependencies.swift
  Packages/PaceLifeKit/
    Sources/PaceLifeCore/
    Sources/PaceLifeDesignSystem/
    Sources/PaceLifeBackend/
    Sources/AppFeature/
    Sources/HomeFeature/
    Sources/HabitsFeature/
    Sources/RoutinesFeature/
    Sources/ModesFeature/
    Sources/PathsFeature/
    Sources/AdaptiveFeature/
    Sources/ChaptersFeature/
    Sources/ExperimentsFeature/
    Sources/CirclesFeature/
    Sources/ConnectFeature/
    Sources/ProfileFeature/
    Tests/
```
An Struktur bestehender, im neuen Repository vorhandener Komponenten anpassen.

Views -> ViewModels/Use Cases -> Domain-Repository-Protokolle -> lokale / spätere Supabase-Adapter. Composition Root für Services. Test-Doubles ohne Netz. Schema und Migrationsdateien zunächst nur als **Vorschlag** und nicht produktiv ausführen.

## Mindest-Domainmodelle
Habit(id, title, goalType, schedule, createdAt, isArchived), HabitCompletion(id, habitID, date, actualValue, targetSnapshot), LifeMode(id, title, recurringSchedule, activeRules), ModeActivation(start, end?, modeID), HomeWidgetPreference(id, kind, position, isVisible). Datumsoperationen mit explizitem lokalem Tagesbezug, stabiler Wiederholung und Tests für Sommer-/Winterzeit.

Später: LifePath, Milestone, AdaptiveSuggestion, LifeChapter, LifeExperiment, ExperimentMeasurement, Circle, CircleMembership, CircleGoal, ShareGrant, ExternalPaceSource. Private Daten sind ohne Freigabe privat.

## Schutzregeln
- Pace Social ist exklusiv bei Claude. Kein Repository-Zugriff und keine produktiven Backendänderungen.
- Bestehendes Pace Social verwendet Supabase und derzeit anonyme Keychain-Sessions. Keine zweite anonyme Session automatisch als selben Account behandeln.
- Auth-UUID != öffentliche Profile-ID. Spätere Anbindung erst nach freigegebenem Vertragsdokument `INTEGRATION_CONTRACT.md`.
- RLS / serverseitige Autorisierung, separate Life-Tabellen, least privilege, Widerruf geteilter Daten.
- SwiftUI-Navigation stabil: kein endloser Stack; Gestenprioritäten; keine Keyboard-/Statusleisten-/Safe-Area-Überlappungen; Realtime-Lifecycle erst nach tatsächlich eingeführter Synchronisierung.

## Implementierung des ersten Abschnitts

- `PaceLife/App`: Composition Root und `@MainActor @Observable AppModel`. Der View-State wird erst nach erfolgreichem Persistieren aktualisiert.
- `PaceLife/Features`: native SwiftUI-Screens, Formulare und Navigation; keine direkten Dateizugriffe aus Views.
- `PaceLife/DesignSystem`: zentrale dynamische Farbtokens und wiederverwendbare Komponenten.
- `PaceLife/Localization`: typisierte DE/EN/RU-Texte, sofortiger Locale-Wechsel für Zahlen/Datum.
- `Packages/PaceLifeCore`: eigenständiges Swift-6-Package mit Foundation-Modellen, Use Cases, Repository-Protokoll, JSON- und Memory-Adaptern, Integration-Capability-Protokollen und Unit-Tests.
- `PaceLifeUITests`: Simulator-Tests der tatsächlichen UI; eigener Test-Dateipfad, keine Manipulation des normalen Nutzerspeichers.

### Persistenzentscheidung

Ein versionierter Codable-JSON-Store ersetzt in Phase 1 SwiftData. Damit werden dieselben Domain-/Persistenzpfade unter Linux und macOS getestet, ohne Apple-Persistenztypen an die Domäne zu koppeln. Das kleine lokale MVP verwendet einen einzelnen MainActor-Writer und atomaren Dateiersatz. `schemaVersion = 1`; unbekannte Versionen und beschädigte Daten führen zum sichtbaren Ladefehler, niemals zum stillen Reset. Ein fehlgeschlagener Schreibvorgang verwirft den vorgeschlagenen Zustand. iOS-Dateischutz ist aktiviert. Keine Mehrfensterbearbeitung und keine mehreren Store-Instanzen auf dieselbe Datei.

Der vollständige Snapshot wird synchron gespeichert. Bei stark wachsender Historie ist ein Hintergrund-Actor/SQLite-Adapter hinter demselben Protokoll erforderlich; dies ist kein Mehrgeräte-Sync-Konzept. Archive erhalten Habit-Historie. Die App synchronisiert oder veröffentlicht keine Daten; Gerätesicherungen unterliegen den Systemeinstellungen.

### Zeit- und Zielsemantik

Erfüllungen sind pro Habit und lokalem gregorianischen Kalendertag eindeutig. Zeitzonenwechsel benennen bestehende Tage nicht um; derselbe lokale Tag wird dedupliziert. Der ursprüngliche Zielwert und Zieltyp werden beim ersten Eintrag eingefroren. Auch eine heutige Zieländerung ändert diesen Snapshot nicht. Zähler sind ganzzahlig, Dauer wird in Minuten erfasst, binär ist 0/1. Teilfortschritt ist sichtbar, aber erst Zielerreichung zählt als vollständig.

Ein aktiver Life Mode filtert seine ausgewählten Habits zusätzlich nach deren Wochentagen. Ohne aktiven Mode gelten alle fälligen Habits; ein leerer Mode enthält bewusst keine. Aktivierungswechsel werden historisiert und verändern keine Erfüllungen. Wiederkehrende Mode-Planung und eigenständige Routinen sind spätere Erweiterungen. Streaks verwenden den aktuellen Habit-Wochenplan; keine Rekonstruktion früherer Planänderungen.

### Navigation

Vier Root-Tabs mit festem, Safe-Area-geschütztem Dock; Editieren in nativen Sheets/Formularen. Im ersten Abschnitt kein horizontales Root-Paging, damit Widget-Reordering, vertikales Scrollen und Texteingabe nicht mit einer eigenen Root-Geste konkurrieren. Der spätere Paging-Ausbau benötigt die Abnahme aus VIDEO_REFERENCE.md. Kein Backend-Listener und kein externes Auth-Lifecycle.
