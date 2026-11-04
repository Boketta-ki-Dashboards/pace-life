# Test- und Release-Anforderungen
- Unit-Tests: Habit-Frequenzen, Tagesgrenzen, Sommer-/Winterzeit, Completion-Deduplikation, Streaks, Mode-Aktivierung, Historienunveränderlichkeit, Persistenz und Widget-Reihenfolge.
- UI-/Navigations-Tests: Swipe-Richtung, Cancel-Swipe, Back-Geste, verschachtelte Navigation vermeiden, Textfelder mit Tastatur, Safe Areas, Scroll-Enden, Drag/Scroll-Konflikte.
- Visuelle Tests in Dark & Light, Dynamic Type, DE/EN/RU, lange Texte, iPhone-Größen, VoiceOver.
- Kein verschachteltes Realtime-Abo, unkontrollierte Task-Lebensdauer oder springende Charts.
- Datenschutztests vor Social-Integration: Default Private, explizites Opt-in, Widerruf, Zugriff unberechtigter Mitglieder serverseitig blockiert.
- Xcode/Simulator-Build wirklich ausführen, wenn macOS/Xcode verfügbar. In Cloud ohne Xcode niemals Erfolg behaupten. Mac-Build-Anleitung dokumentieren.
- Dokumentation der Bundle-ID, Team-Signing, Assetfreigaben, Datenschutzerklärung, Berechtigungen, App Store Review.
- Kein Release, bevor ein echter iPhone-Test möglich war.

## Verbindliche Abnahme anhand der Codex-Chat-Referenzen
Vor Abschluss der UI-Feinabstimmung Originalaufnahmen aus dem aktiven Codex-Chat prüfen, insbesondere Bottom-HUD, Root-Swipes, Scrollbewegungen und Header. Sie werden **nicht auf GitHub hochgeladen**. Fehlt Unterstützung für Videoanhänge, werden Frames und textuelle Ablaufbeschreibungen im Chat verwendet; die noch nicht durchgeführte 1:1-Video-Prüfung im Testbericht als offen markieren. Siehe `docs/VIDEO_REFERENCE.md`.

## Ausführbare Prüfpfade Phase 1

- `swift test --package-path Packages/PaceLifeCore`: 54 XCTest-Fälle der Domäne und Persistenz, ohne Backend.
- macOS/Xcode 16+: `scripts/test-ios.sh` wählt einen vorhandenen iPhone-Simulator und führt das Scheme `PaceLife` inklusive 15 UI-Tests aus. Der UI-Test-Store wird je Test mit einer UUID isoliert; Neustarts verwenden denselben Test-Store.
- Build ohne Geräte-Signing: `xcodebuild -project PaceLife.xcodeproj -scheme PaceLife -destination 'generic/platform=iOS Simulator' -derivedDataPath DerivedData CODE_SIGNING_ALLOWED=NO build`.
- GitHub-CI: `.github/workflows/ios.yml`; echter Laufstatus bleibt vom angelegten Workflow getrennt.
- Gerät: `PaceLife.xcodeproj` öffnen, eigenes Team und ggf. eindeutige Bundle-ID einstellen, iPhone auswählen, ⌘R. Keine App-Store-Veröffentlichung konfiguriert. Default Bundle-ID `com.boketta.pacelife`, Version 0.1.0, Build 1.
- Aktuelles Prüfprotokoll und nicht ausgeführte Prüfungen: [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md).

Die UI-Suite wartet auf einen vollständig gebooteten Simulator und läuft seriell.
Sie enthält interaktives Root-Paging/Abbruch/Dock-Geometrie, native Detail-Back-Geste,
Chapter-/Experiment-Neustarts, lokale Circle-Freigabe/Widerruf sowie echte
Light-/Dark-Screenshot-Anhänge. Ein endlicher Testkontakt bildet eine reale
Fingerberührung ab; Ergebnis-Assertions dürfen nicht durch Wiederholung oder
Auslassen umgangen werden. Commitgenaue Nachweise und offene Nachläufe stehen in
[IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md).

Dynamic Type: größte Accessibility-Schrift über native UIKit-Launch-Option.
Der Test verlangt vergrößerte Seiteninhalte, einen kompakten einzeiligen Dock,
vier erreichbare Tabs, mindestens 44 × 48 pt Touch-Flächen innerhalb des Displays,
keine Überschneidung benachbarter Targets, Scrollen bis zum Editor und bedienbare
Tastatur/Toolbar. Der frühere Test prüfte lediglich einen vergrößerten Dock; erst
die echte Sichtprüfung deckte dessen unleserliche Zeilenumbrüche auf. Die neue
Geometriebedingung ergänzt diese Prüfung. Der native Large Content Viewer braucht
zusätzlich eine manuelle Prüfung auf dem Gerät.

Native Foto-Regression: `scripts/test-ios.sh test-regressions` führt Path-Back und
PhotoPicker vor der vollständigen Suite aus. Das Skript fügt dem Simulator die
synthetische Datei unter `PaceLifeUITests/Fixtures` hinzu; keine vorhandenen Fotos
werden gelöscht. Der Test verlangt Picker-Abbruch ohne Referenz, echten Import,
sichtbares dekodiertes Bild nach Neustart sowie Entfernen und weiteren Neustart.
Mit `7ee521e` auf Apple Silicon und Intel bestanden. Core-Dateitests prüfen
zusätzlich fehlende Dateien, Referenzerhalt, Bereinigung und fehlgeschlagene Speicherung.
Dateigrößen-/Formatgrenzen sind implementiert; deren vollständige iOS-Randfallprüfung
mit weiteren Fotoformaten bleibt offen.

Die [eingecheckten Simulatoraufnahmen](screenshots/README.md) wurden tatsächlich
visuell geöffnet und geprüft. Das ersetzt keine vollständige Abnahme von
VoiceOver, sämtlichen Displaygrößen/Sprachen, Originalvideos und echten iPhones.
