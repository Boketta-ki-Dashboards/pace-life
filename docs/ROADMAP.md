# Pace Life – verbindliche Entwicklungsroadmap
Status pro Modul: `Not started` / `In progress` / `Implemented` / `Verified`. Status nur mit realem Code und Tests erhöhen.

| Modul | Aktueller Status | Implementiert | Verifiziert / offen |
|---|---|---|---|
| Life Modes | In progress | CRUD, manuelle Aktivierung, Habit-Tagesvorlagen, eigenständige Routinen mit Tages-Snapshots und Home-Widget | Core und Simulatorabläufe bestanden; Gerät, automatische Mode-Pläne und historische Habit-Pläne offen |
| Life Paths | In progress | Gespeicherte Paths, Meilensteine, manuelle, Habit- und vollständige Routine-Beiträge, Status/Archiv samt Abschlussdatum, Home-Widget | Core inklusive Verknüpfungen und Simulatorabläufe bestanden; Routine-Auswahl/Neustart auf Apple Silicon bestanden; Gerät/visuelle Abnahme offen |
| Pace Adaptive | In progress | Deterministische Vorschläge, Bestätigung/Ablehnung/Änderung/Rückgängig, Tageshistorie und Home-Widget; Habits/Paths/Routinen verbunden | Core und Simulatorabläufe bestanden; Gerät, Neuplanung und flexible Routine-Schritte offen |
| Life Chapters | In progress | Private Chronik, Zeitraum/Kategorie, Erinnerungen/Meilensteine, Path-Links, Fotoauswahl mit separater Dateiablage, Archiv/Löschen | Fünf neue Core-Tests und Chapter-Neustart/Archiv/Editieren im Simulator bestanden; native Fotoauswahl/visuelle Abnahme und Export offen |
| Life Experiments | In progress | Eigene Zeiträume/Messgrößen, Check-ins, Korrekturen, Baselines/Vergleiche, Punktdiagramme, Reflexion, Abschluss/Wiederholung/Archiv | Vier neue Core-Tests und Experiment-Neustart/Korrektur im Apple-Silicon-Simulator bestanden; aktuelle Regression läuft |
| Pace Circles | In progress | Lokaler Testmodus, Demo-Mitglieder/Rollen, datierte Gruppenziele/Challenges, Beiträge/Verlauf, widerrufliche Freigaben, Abschluss/Archiv | Vier neue Core-Tests und Freigabe/Widerruf/Neustart auf Apple Silicon bestanden; reale externe Gruppen erst nach freigegebenem Vertrag |
| Pace Connect | In progress | Unavailable-Identitäts-/Aktivitäts-/Freunde-Protokolle und UI-Zustand | Keine Integration implementiert; freigegebener Vertrag erforderlich |

**Phase 0:** Repo inventarisieren, Dokumentation, Architektur, kein Zugriff auf Pace Social.
**Phase 1:** Native SwiftUI App, DE/EN/RU, Design, echte lokale Habits & Life Modes, Home-Widgets, Unit-/UI-Tests.
**Phase 2:** Paths und Adaptive real implementieren, Datenmodelle/Tests erweitern.
**Phase 3:** Chapters und Experiments inklusive Bildhandling, Export und Privacy.
**Phase 4:** Lokalen Circles-Testmodus mit Gruppenzielen und Challenges implementieren. Reale externe Gruppen und Connect erst nach Freigabe von Backend/Auth und Privacy-Regeln durch Claude; produktive Migrationen nur nach gesonderter Freigabe.
**Phase 5:** harte Regression, reale iPhone-Tests, Lokalisierung, App Store und Datenschutz.

Codex muss am Ende jeder Phase dokumentieren: Implementiert, tatsächlich getestet, nicht getestet und verbleibende Punkte.


## Aktueller Nachweis
Kein Modul wird wegen eines UI-Platzhalters als `Implemented` oder `Verified`
geführt. Die lokale Domäne hat jetzt 53 bestandene XCTest-Tests. Commit `50dd2dd`
besteht auf Apple Silicon und Intel mit jeweils 53 Core-Tests, 13 UI-Tests,
Debug- und Release-Simulator-Build. Der Experiment-Zwischenstand `cd7f521` ist auf beiden
Architekturen vollständig bestanden. Echte Gerätetests und die oben aufgeführten
Funktionslücken bleiben offen. Commitgenaue Ergebnisse und Grenzen:
[IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md).
