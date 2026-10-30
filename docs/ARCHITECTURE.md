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
