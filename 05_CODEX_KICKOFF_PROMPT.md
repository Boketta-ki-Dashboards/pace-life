# ERSTER CODEX-/ASTRA-AUFTRAG — PACE LIFE

Du bist leitender SwiftUI-Entwickler und iOS-Architekt des neuen Projekts **Pace Life**.

**Lies zuerst und beachte durchgehend die mitgelieferten Dateien:**
- `AGENTS.md`
- `README.md`
- `docs/DESIGN_SYSTEM.md`
- `docs/PRODUCT_SPEC.md`
- `docs/ARCHITECTURE.md`
- `docs/ROADMAP.md`
- `docs/INTEGRATION_CONTRACT.md`
- `docs/TEST_AND_RELEASE.md`
- `docs/VIDEO_REFERENCE.md`

**Datenschutz:** Dieses GitHub-Repository ist derzeit öffentlich. Private Referenzbilder sind absichtlich nicht enthalten. Verwende die schriftliche Designspezifikation; fordere bei Bedarf ausschließlich bereinigte Bilder an. Keine Suche nach Pace Social.

## Wichtigste Projektgrenze

**Pace Social ist TABU.** Du bekommst **keinen Zugriff** auf dessen GitHub-Repository oder Quellcode. Du darfst es nicht klonen, öffnen, herunterladen, verändern oder über einen anderen Weg als Codequelle verwenden. Ausschließlich Claude bearbeitet Pace Social. Arbeite nur in dem neuen, separaten Pace-Life-Repository. Verändere keinerlei produktive Supabase-Daten, Migrationen oder fremde Projekte.

Die Repository-Dokumentation und die vom Nutzer **separat im aktiven Codex-Chat angehängten** Videos bzw. Frames sind die freigegebenen Referenzen. Erfinde keine weiteren Annahmen über den Code, Datenbanken oder APIs von Pace Social.

## Zielprodukt

Entwickle eine eigenständige **native iOS-App** mit SwiftUI, möglichst Swift 6, für iOS 17 oder neuer, die sich visuell wie ein offizielles Mitglied der Pace-Familie anfühlt. Produktpositionierung: persönliches Life Operating System — Routinen, Lebensmodi, langfristige Ziele, persönliche Chronik, Experimente, gemeinsame Ziele und spätere sichere Pace-Integration.

Die sieben Module **Life Modes, Life Paths, Pace Adaptive, Life Chapters, Life Experiments, Pace Circles und Pace Connect** sind unverzichtbar. Halte ihre Anforderungen und Etappen dauerhaft fest. **Sie müssen nicht alle in dieser ersten Ausführung vollständig implementiert sein**, aber es darf keines aus dem Gesamtplan gestrichen werden.

## Arbeitsauftrag, in dieser Reihenfolge

**0. Bestand prüfen.** Falls bereits Dateien für Pace Life vorliegen, inventarisiere sie und bewahre existierende Funktionen. Falls das Repo leer ist, initialisiere es als neues Pace-Life-Projekt. Greife niemals auf Pace Social zu.

**1. Produkt und Design festigen.** Überführe die beigefügten Anforderungen in dauerhafte `docs/`-Dateien. Lege die in `docs/DESIGN_SYSTEM.md` enthaltenen Light-/Dark-Tokenwerte und Komponentenspezifikationen als verbindliche Grundlage fest. Verwende die schriftlich dokumentierten Pace-Designregeln für Header, Home, Statistik, Karten, Tab-Bar, Gruppen und Einstellungen. Originalvideos und Frames kommen direkt über die Codex-Chat-Anhänge und dürfen nicht in GitHub kopiert werden. Keine generischen Neon-/Glas-Designs.

**2. App aufbauen.** Erzeuge ein eigenes Xcode-Projekt mit klarer modularer Struktur (z. B. lokales Swift Package / Feature-Ziele). Implementiere zentrale Dependency Injection, SwiftUI-Navigation, Theme, Sprachbasis DE/EN/RU, semantische Design-Tokens und wiederverwendbare Pace-Life-Komponenten (`PaceCard`, `PaceTile`, Header, Buttons, Progress, Status). Verwende einen explizit als Ersatz gekennzeichneten Logo-Platzhalter, bis das originale `PaceWordmark`-Asset freigegeben wurde.

**3. Erste echte Funktionen.** Implementiere einen durchgängigen lokalen MVP-Flow für:
- Life Mode erstellen, ändern, aktivieren und dauerhaft speichern;
- Gewohnheit erstellen mit Name, Häufigkeit und Zieltyp;
- Gewohnheit für heute abhaken, ändern und dauerhaft speichern;
- Habit-Fortschritt auf dem Home anzeigen;
- Home-Widgets ein-/ausblenden und Reihenfolge dauerhaft speichern;
- ruhige Navigation über `Heute`, `Entwicklung`, `Kreise`, `Profil`.

Lokale Persistenz darf SwiftData oder ein gleichwertiger dokumentierter Store sein. **Keine** nur optischen Dummys für die genannten ersten echten Funktionen.

**4. Noch nicht verfügbare Backendfunktionen korrekt behandeln.** Für Circles/Connect zunächst saubere Domain-/Service-Protokolle und klar gekennzeichnete Mock-/Unavailable-Zustände vorsehen; keine Fake-Freundesprofile als reale Nutzer ausgeben, keine Social-Tabellenraten, keine produktive Auth-Verbindung. Sichere gemeinsame Accounts sind ein gesonderter späterer Auftrag nach Freigabe des Schnittstellenvertrags von Claude.

**5. Qualität nachweisen.** Schreibe sinnvolle Unit-Tests für Habits, Modes, Datumslogik und Persistenz sowie UI-/Navigations-Tests, soweit in der Umgebung ausführbar. Kompiliere das Projekt mit Xcode, **falls tatsächlich vorhanden**. Wenn Xcode/macOS nicht verfügbar ist, behaupte keinen erfolgreichen iOS-Build; dokumentiere den exakten Mac-Buildbefehl und die ungeprüften Punkte.

**6. Projektdokumentation.** Erstelle oder aktualisiere `AGENTS.md`, `README.md`, `docs/ARCHITECTURE.md`, `docs/DESIGN_SYSTEM.md`, `docs/PRODUCT_SPEC.md`, `docs/ROADMAP.md`, `docs/INTEGRATION_CONTRACT.md`. Die Roadmap muss für jede der sieben Funktionen `Not started / In progress / Implemented / Verified` getrennt ausweisen.

## Zusätzliche Qualitätsvorgaben

- Keine direkten Datenbankaufrufe aus SwiftUI-Views.
- Keine unkontrollierten verschachtelten NavigationStacks, falschen Swipe-Richtungen oder Tastatur-/Safe-Area-Fehler.
- Korrekte Farbkontraste und Dynamic Type; Systemschrift SF Pro.
- Einmalige Datenquellen und kontrolliertes Task-/Listener-Lifecycle.
- Platzhalterdaten nur klar als Demo gekennzeichnet; reale Nutzereingaben tatsächlich speichern.
- Historische Habit-Erfüllungen dürfen bei einem Life-Mode-Wechsel nicht rückwirkend verändert werden.
- Künftige reduzierte Ziele dürfen nie als vollständig erledigt ausgegeben werden.
- Keine ungefragten Änderungen am Produktionsbackend oder an existierenden Pace-Social-Daten.

## Abschlussbericht

Liefere nach der Umsetzung:
1. Implementierte Funktionen, klar getrennt von geplanten.
2. Geänderte/neu angelegte Dateien.
3. Tatsächlich ausgeführte Tests und Build-Ergebnisse.
4. Lokale Xcode-Startanleitung.
5. Noch fehlende Assets/Informationen für die exakte Pace-Optik.
6. Welche Aufgaben in Phase 2 (Life Paths + Pace Adaptive) folgen.

**Beginne mit dem vorhandenen Pace-Life-Verzeichnis bzw. lege die neue App an, wenn es leer ist. Starte danach die Implementierung des ersten nutzbaren iOS-Projektstands, nicht nur eine abstrakte Analyse.**

## Verbindliche Originalvideo-Referenzen
Die Originalvideos werden **nur als Anhänge in diesem Codex-Chat bereitgestellt**, nicht über GitHub. Lies `docs/VIDEO_REFERENCE.md` und prüfe die tatsächliche Verfügbarkeit der Videos im aktuellen Chat. Nutze sie, wenn technisch auswertbar, zwingend zur Feinabstimmung von Bottom-HUD/Tab-Bar, Wischen, Scrollen, Animationen, Header und Safe Areas. Sind Videos nicht direkt lesbar, arbeite mit vom Nutzer im Chat bereitgestellten Frames/Beschreibungen; kennzeichne den Videoabgleich als ausstehend. Kein Verweis auf GitHub-Issue-Uploads.
