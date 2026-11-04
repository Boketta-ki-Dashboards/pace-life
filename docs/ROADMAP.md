# Pace Life – verbindliche Entwicklungsroadmap
Status pro Modul: `Not started` / `In progress` / `Implemented` / `Verified`. Status nur mit realem Code und Tests erhöhen.

| Modul | Aktueller Status | Implementiert | Verifiziert / offen |
|---|---|---|---|
| Life Modes | In progress | CRUD, manuelle Aktivierung, Habit-Tagesvorlagen, eigenständige Routinen mit Tages-Snapshots und Home-Widget | Core und Simulatorabläufe bestanden; Gerät, automatische Mode-Pläne und historische Habit-Pläne offen |
| Life Paths | In progress | Gespeicherte Paths, Meilensteine, manuelle, Habit- und vollständige Routine-Beiträge, Status/Archiv samt Abschlussdatum, Home-Widget | Core inklusive Verknüpfungen und Simulatorabläufe bestanden; Routine-Auswahl/Neustart auf beiden Architekturen bestanden; Geräte-/vollständige Designabnahme offen |
| Pace Adaptive | In progress | Deterministische Vorschläge, Bestätigung/Ablehnung/Änderung/Rückgängig, Tageshistorie und Home-Widget; Habits/Paths/Routinen verbunden | Core und Simulatorabläufe bestanden; Gerät, Neuplanung und flexible Routine-Schritte offen |
| Life Chapters | In progress | Private Chronik, Zeitraum/Kategorie, Erinnerungen/Meilensteine, Path-Links, Fotoauswahl mit separater Dateiablage, Archiv/Löschen | Fünf neue Core-Tests und Chapter-Neustart/Archiv/Editieren im Simulator bestanden; native Fotoauswahl/Abbruch/Import/Neustart/Entfernen auf beiden Architekturen bestanden; Geräteabnahme und Export offen |
| Life Experiments | In progress | Eigene Zeiträume/Messgrößen, Check-ins, Korrekturen, Baselines/Vergleiche, Punktdiagramme, Reflexion, Abschluss/Wiederholung/Archiv | Vier neue Core-Tests und Experiment-Neustart/Korrektur auf beiden Simulator-Architekturen bestanden; aktuelle UI-Korrektur wird nachgetestet |
| Pace Circles | In progress | Lokaler Testmodus, Demo-Mitglieder/Rollen, datierte Gruppenziele/Challenges, Beiträge/Verlauf, widerrufliche Freigaben, Abschluss/Archiv | Vier neue Core-Tests und Freigabe/Widerruf/Neustart auf beiden Architekturen bestanden; reale externe Gruppen erst nach freigegebenem Vertrag |
| Pace Connect | In progress | Unavailable-Identitäts-/Aktivitäts-/Freunde-Protokolle und UI-Zustand | Keine Integration implementiert; freigegebener Vertrag erforderlich |

**Phase 0:** Repo inventarisieren, Dokumentation, Architektur, kein Zugriff auf Pace Social.
**Phase 1:** Native SwiftUI App, DE/EN/RU, Design, echte lokale Habits & Life Modes, Home-Widgets, Unit-/UI-Tests.
**Phase 2:** Paths und Adaptive real implementieren, Datenmodelle/Tests erweitern.
**Phase 3:** Chapters und Experiments inklusive Bildhandling, Export und Privacy.
**Phase 4:** Lokalen Circles-Testmodus mit Gruppenzielen und Challenges implementieren. Reale externe Gruppen und Connect erst nach Freigabe von Backend/Auth und Privacy-Regeln durch Claude; produktive Migrationen nur nach gesonderter Freigabe.
**Phase 5:** harte Regression, reale iPhone-Tests, Lokalisierung, App Store und Datenschutz.

Codex muss am Ende jeder Phase dokumentieren: Implementiert, tatsächlich getestet, nicht getestet und verbleibende Punkte.


## Aktueller Nachweis und nächste Abschnitte

Die lokale Domäne besteht mit 53 XCTest-Tests. `50dd2dd` besteht auf Apple Silicon
und Intel mit 53 Core-/13 UI-Tests und Debug-/Release-Builds; `d2b17e4` mit 14 UI-Tests.
Die Suite enthält inzwischen 15 UI-Fälle einschließlich nativer Fotoauswahl; Apple
besteht mit `7ee521e` vollständig, Intel scheiterte nur am Screenshot-Sheet-Öffnen.
Die aktuelle Korrektur `dfd03d7` wird nachgetestet. Zehn echte Standard-Screenshots
wurden visuell geprüft und eingecheckt; die korrigierte größte Schrift folgt noch.
Exakte Nachweise: [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md).

1. Aktuelle Navigation-/Accessibility-Korrektur vollständig nachtesten und visuell
   prüfen; kleine/große und echte iPhones, VoiceOver, lange DE/EN/RU-Texte abnehmen.
2. Automatische Mode-Pläne und historisch versionierte Habit-Pläne/Streaks. Frühere
   unbekannte Pläne bleiben unbekannt; keine rückwirkend erfundenen Tagesziele.
3. Tages-/Wochenroutinen und Meilensteindiagramme vertiefen; Routine-Path-Beiträge
   sind bereits integriert und dürfen nicht doppelt gebucht werden.
4. Adaptive-Neuplanung, persönliche Prioritäten/Zeitfenster, zugestimmte lokale
   Erinnerungen, Export/Backup und weitere Home-Widgets.
5. Reale Circles/Connect ausschließlich nach freigegebenem Schnittstellenvertrag.

Die Modulstatus bleiben `In progress`, solange der langfristige Spezifikationsumfang
und die Geräte-/Designabnahme fehlen. Die drei neuen lokalen Module sind echte
persistierte Funktionen; Connect ist weiterhin ausdrücklich nicht verfügbar.
