# Pace Life – verbindliche Entwicklungsroadmap
Status pro Modul: `Not started` / `In progress` / `Implemented` / `Verified`. Status nur mit realem Code und Tests erhöhen.

| Modul | Aktueller Status | Implementiert | Verifiziert / offen |
|---|---|---|---|
| Life Modes | In progress | CRUD, manuelle Aktivierung, Habit-Tagesvorlagen, eigenständige Routinen mit Tages-Snapshots und Home-Widget | 36 Core-Tests bestanden; aktuelle iOS-Abnahme, automatische Mode-Pläne und historische Habit-Pläne offen |
| Life Paths | In progress | Gespeicherte Paths, Meilensteine, manuelle und Habit-Beiträge, Status/Archiv, Home-Widget | Core inklusive Verknüpfungen geprüft; aktuelle iOS-Abnahme und Routine-Beiträge offen |
| Pace Adaptive | In progress | Deterministische Vorschläge, Bestätigung/Ablehnung/Änderung/Rückgängig, Tageshistorie und Home-Widget; Habits/Paths/Routinen verbunden | 36 Core-Tests bestanden; aktuelle UI-Abnahme, Neuplanung und flexible Routine-Schritte offen |
| Life Chapters | Not started | Als geplantes Modul ausgewiesen | Phase 3: private Chronik und Erinnerungen |
| Life Experiments | Not started | Als geplantes Modul ausgewiesen | Phase 3: Experimente und Auswertungen |
| Pace Circles | In progress | Unavailable-Capability-Protokoll und ehrlicher UI-Zustand | Keine Gruppenfunktionen implementiert; Vertrag und Serverfreigaben offen |
| Pace Connect | In progress | Unavailable-Identitäts-/Aktivitäts-/Freunde-Protokolle und UI-Zustand | Keine Integration implementiert; freigegebener Vertrag erforderlich |

**Phase 0:** Repo inventarisieren, Dokumentation, Architektur, kein Zugriff auf Pace Social.
**Phase 1:** Native SwiftUI App, DE/EN/RU, Design, echte lokale Habits & Life Modes, Home-Widgets, Unit-/UI-Tests.
**Phase 2:** Paths und Adaptive real implementieren, Datenmodelle/Tests erweitern.
**Phase 3:** Chapters und Experiments inklusive Bildhandling, Export und Privacy.
**Phase 4:** Circles und Connect nach Freigabe von Backend/Auth und Privacy-Regeln durch Claude; produktive Migrationen nur nach gesonderter Freigabe.
**Phase 5:** harte Regression, reale iPhone-Tests, Lokalisierung, App Store und Datenschutz.

Codex muss am Ende jeder Phase dokumentieren: Implementiert, tatsächlich getestet, nicht getestet und verbleibende Punkte.


## Phase-1-Nachweis
Habits, Life-Mode-Tagesvorlagen, persistente Home-Widgets und Einstellungen sind implementiert. Kein Modul wird wegen eines UI-Platzhalters als `Implemented` oder `Verified` geführt. Die lokale Domäne hat 36 bestandene XCTest-Tests. Sechs UI-Tests des Routinen-/Widget-Zwischenstands sind auf Apple Silicon bestanden; der aktuelle Stand enthält acht UI-Tests und benötigt die aktuelle CI-/Geräteabnahme. Details und Grenzen: [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md).
