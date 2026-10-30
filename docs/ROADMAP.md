# Pace Life – verbindliche Entwicklungsroadmap
Status pro Modul: `Not started` / `In progress` / `Implemented` / `Verified`. Status nur mit realem Code und Tests erhöhen.

| Modul | Aktueller Status | Implementiert | Verifiziert / offen |
|---|---|---|---|
| Life Modes | In progress | Phase-1-CRUD, manuelle Aktivierung, Habit-Tagesvorlagen und Historie | Core-Tests bestanden; iOS-Abnahme, wiederkehrende Pläne und Routinen offen |
| Life Paths | Not started | Als geplantes Modul ausgewiesen | Phase 2: Ziele, Meilensteine, Habit-Verknüpfungen |
| Pace Adaptive | Not started | Als geplantes Modul ausgewiesen | Phase 2: bestätigte regelbasierte Anpassungen |
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
Habits, Life-Mode-Tagesvorlagen, persistente Home-Widgets und Einstellungen sind implementiert. Kein Modul wird wegen eines UI-Platzhalters als `Implemented` oder `Verified` geführt. Die lokale Domäne hat 16 bestandene XCTest-Tests; die SwiftUI-App und fünf XCUITests benötigen noch Xcode-/Geräteabnahme. Details und Grenzen: [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md).
