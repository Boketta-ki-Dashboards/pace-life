# Pace Life — iOS

Native SwiftUI-App der Pace-Familie: Lifestyle, Gewohnheiten, Tagesmodi, langfristige Ziele, Erinnerungen, Experimente und gemeinsame Ziele.

## Codex starten
Zuerst [AGENTS.md](AGENTS.md), [05_CODEX_KICKOFF_PROMPT.md](05_CODEX_KICKOFF_PROMPT.md) und alle [docs/](docs) lesen. Anschließend ein **echt lauffähiges** erstes SwiftUI/Xcode-Projekt mit Life Modes, lokalen Habits und modularer Home-Ansicht entwickeln.

## Dokumente
- [Designsystem](docs/DESIGN_SYSTEM.md)
- [Produktspezifikation mit allen sieben Modulen](docs/PRODUCT_SPEC.md)
- [Architektur](docs/ARCHITECTURE.md)
- [Roadmap](docs/ROADMAP.md)
- [Pace-Integration](docs/INTEGRATION_CONTRACT.md)
- [Tests und Release](docs/TEST_AND_RELEASE.md)
- [Verbindliche Video- und Gestenreferenz](docs/VIDEO_REFERENCE.md)

## Isolation und Datenschutz
Pace Social wird **ausschließlich von Claude** betreut. Kein Codex-Zugriff auf dessen Repository. Keine produktiven Supabase-Änderungen oder eigenmächtige Account-Verknüpfung.

Die zwei Originalvideos aus Pace Social werden ausschließlich **im Codex-Chat als Anhänge** bereitgestellt. Sie gehören nicht in dieses GitHub-Repository oder ein GitHub-Issue. Code- und Designregeln sind dauerhaft unter `docs/` dokumentiert. Codex muss prüfen, ob es Videoanhänge tatsächlich auswerten kann; falls nicht, dienen Chat-Frames und Bewegungsbeschreibungen als Ersatz, bis ein visueller Abgleich möglich ist.

**Aktueller Stand:** Dokumentations- und Codex-Handoff; noch kein implementierter oder geprüfter Xcode-Build.
