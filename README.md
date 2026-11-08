# Pace Life — iOS

Native, lokale SwiftUI-App für iPhone mit iOS 17+, Swift 6 und Xcode 16 oder neuer. Der Entwicklungsbranch implementiert Life Modes mit Wochenplan, Habits, eigenständige Routinen, Life Paths mit Fortschrittsverlauf, Pace Adaptive inklusive Neuplanung, Kalender und Statistik auf eingefrorenen Tagesplänen, ein frei anpassbares Pace-Dashboard, private Life Chapters mit Fotos, Life Experiments, einen lokalen Pace-Circles-Testmodus, lokale Erinnerungen und Datenexport/Wiederherstellung. Navigation und Design folgen der ausgewerteten Pace-Social-Referenz ([Analyse](docs/DESIGN_REFERENCE_ANALYSIS.md)). Die sieben langfristigen Module bleiben in [Roadmap](docs/ROADMAP.md) und [Produktspezifikation](docs/PRODUCT_SPEC.md) verankert.

## In Xcode öffnen und auf dem iPhone testen

1. Dieses Repository klonen, den Branch `codex/pace-life-offline-beta` auswählen und `PaceLife.xcodeproj` öffnen. Das lokale Package `Packages/PaceLifeCore` wird ohne externe Abhängigkeiten eingebunden; kein Generator oder Paketmanager ist zum Öffnen nötig.
2. Scheme **PaceLife** auswählen. Unter **Signing & Capabilities** beim Target **PaceLife** dein Apple-Entwicklerteam wählen. Falls nötig `com.boketta.pacelife` in eine eigene eindeutige Bundle-ID ändern. Es ist kein fremdes Team vorkonfiguriert.
3. iPhone verbinden, dem Mac vertrauen und den Entwicklermodus am iPhone aktivieren. Gerät als Run Destination wählen und mit **⌘R** starten. Ein kostenloses Personal Team kann für lokale Gerätetests verwendet werden; dessen Apple-Limits gelten.
4. Auf **Heute** mit dem „+“ der Gewohnheitskarte eine Gewohnheit erstellen und abhaken. Oben rechts **Anpassen** öffnen: Widgets entfernen (×), Größe wählen, über das Griff-Menü oder per Halten-und-Ziehen verschieben, „Widget hinzufügen“, dann **Fertig**. App schließen und erneut öffnen: Eingaben und Layout bleiben erhalten. Unterseiten öffnen sich per Push; der Pace-Dock bleibt sichtbar, Zurück per Edge-Swipe oder „‹ Heute“.

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

Das Testskript fügt ein ausdrücklich synthetisches Testbild zur gewählten
Simulator-Fotomediathek hinzu, damit der native Foto-Picker automatisiert geprüft
werden kann. Bestehende Fotos bleiben erhalten. Für direkt in Xcode gestartete
UI-Tests zuerst die [Foto-Testdatei](PaceLifeUITests/Fixtures/README.md) im gewählten
Simulator bereitstellen. Die normale App benötigt diese Datei nicht.

Das Xcode-Projekt ist eingecheckt. Nach Hinzufügen/Entfernen von Swift-Dateien lässt es sich mit `python3 scripts/generate_project.py` reproduzierbar aktualisieren. [GitHub Actions](.github/workflows/ios.yml) enthält Core-Tests sowie einen macOS-Simulator-Build mit UI-Tests. Ein angelegter Workflow ist noch kein bestandener Lauf. Tatsächliche Ergebnisse und offene Gerätetests stehen in [IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md).

## Architektur und Datenschutz

SwiftUI → `@Observable AppModel` → `LifeStore`-Use-Cases → `StateRepository`. Der atomare, versionierte JSON-Store liegt in Application Support im privaten App-Container; unter iOS mit vollständigem Dateischutz. Lokale Gerätedatensicherungen können App-Daten enthalten. Ein Lesefehler überschreibt keine Daten; Schreibfehler übernehmen keine ungespeicherten Änderungen in den angezeigten Zustand. Keine Netzwerk-SDKs, Telemetrie oder Cloud-Synchronisierung. Details: [Architektur](docs/ARCHITECTURE.md).

Pace Social wird ausschließlich von Claude betreut. Kein Zugriff auf dessen Repository, keine produktiven Supabase-Änderungen und keine eigenmächtige Account-Verknüpfung. Circles ist ausdrücklich ein lokaler Testmodus mit Demo-Mitgliedern; Connect meldet weiterhin „noch nicht verfügbar“. Referenzvideos bleiben private Chat-Anhänge und gehören niemals ins Repository.

## Projektanforderungen

[AGENTS.md](AGENTS.md), [Kickoff](05_CODEX_KICKOFF_PROMPT.md), [Designsystem](docs/DESIGN_SYSTEM.md), [Testanforderungen](docs/TEST_AND_RELEASE.md), [Integrationsvertrag](docs/INTEGRATION_CONTRACT.md) und [Videoreferenz](docs/VIDEO_REFERENCE.md).

Routinen testen: Auf **Heute** die Routinen-Karte öffnen und eine Routine mit mehreren Schritten
anlegen, optional einem Life Mode zuordnen und diesen aktivieren. Routine starten,
einige Schritte erledigen, pausieren und die App neu starten. Teilfortschritt und
Pause bleiben erhalten. Das Routinen-Widget lässt sich über **Anpassen**
ein- und ausblenden. Bestehende Schema-1-Daten werden automatisch verlustfrei übernommen.

Life Paths testen: **Entwicklung → Life Paths**, Ziel mit mehreren Meilensteinen
anlegen. Einen Minuten-Meilenstein mit einer Dauer-Gewohnheit verknüpfen (100
Lernstunden = 6000 Minuten). Heute 45 Minuten bei dieser Gewohnheit erfassen: Der
Path zeigt 45 tatsächliche Minuten. Korrekturen ändern diesen Beitrag ohne
Doppelzählung; weitere Meilensteine bleiben unabhängig.

Pace Adaptive testen: Einen Dauer-Habit mit 60 Minuten anlegen, auf **Heute** „Tag
anpassen“ öffnen und 30 Minuten Budget wählen. Vorschlag bestätigen, 30 Minuten
erfassen: angepasstes Tagesziel erreicht, ursprüngliches Ziel erst zur Hälfte.
Der echte Wert fließt in verknüpfte Paths. Neustart erhält beide Ziele und den
Istwert. Bereits erstellte Tagespläne bleiben eingefroren; einzelne Ziele können
bearbeitet oder ihre Anpassung zurückgenommen werden.

Kalender testen: Unter **Heute** das Kalender-Symbol öffnen, zwischen Woche und
Monat wechseln und Tage auswählen. Erreichte Tage sind gefüllt, Teilfortschritt zeigt
einen Ring. Vergangene Tage nutzen ihren eingefrorenen Tagesplan (ab Schema 9); Tage
ohne gespeicherten Plan gelten nicht als verpasst. Zukunftstage sind eine Vorschau.
Das Statistik-Symbol zeigt Woche/Monat, Kennzahlen und Bestwerte.

Life Chapters testen: **Entwicklung → Life Chapters → +**. Titel, Zeitraum,
Kategorie und optional verknüpfte Paths speichern. Im Kapitel Fotos über den nativen
Picker auswählen, eine Erinnerung bzw. einen Meilenstein anlegen und die App neu
starten. Ein archivierter Path bleibt verknüpft. Kapitel lassen sich archivieren,
wiederherstellen und nach Bestätigung löschen. Fotos bleiben privat im App-Container.
Die vier Haupttabs unterstützen natives horizontales Paging und den festen Pace-Dock.

Life Experiments testen: **Entwicklung → Life Experiments → +**, Zeitraum und
mindestens eine Messgröße wählen. Optionale Ausgangswerte selbst erfassen. Im
Experiment tägliche Check-ins eingeben, leere Felder als fehlende Daten belassen.
Ein erneuter Check-in am selben Tag korrigiert die Werte. Diagramm und Vergleich
zeigen nur eingegebene Beobachtungen. Abschließen, Reflexion bearbeiten oder als
neues Experiment ohne alte Messwerte wiederholen. Neustart erhält alle Einträge.

Pace Circles testen: **Kreise → Circle erstellen**, optional ausdrücklich lokale
Demo-Mitglieder und Rollen hinzufügen. Eine Challenge mit Zeitraum und Ziel anlegen.
Eigene oder simulierte Tagesbeiträge erfassen; ohne aktive Freigabe bleibt der
Beitrag privat und fehlt in der Gruppensumme. Einen Habit-Beitrag gezielt auswählen
und freigeben; spätere Korrekturen aktualisieren dieselbe Quelle. Neustart prüfen,
Freigabe widerrufen und erneut starten. Auch archivierte Challenges erlauben den
Widerruf. Es gibt keine Online-Mitglieder, Nachrichten oder Synchronisierung.

Eine ausgewählte Galerie echter, visuell geprüfter Simulator-PNGs ist samt
Quell-Commit und Prüfsummen eingecheckt. Aufnahmen und Grenzen: [docs/screenshots](docs/screenshots/README.md).

Routine mit Path verbinden: Im neuen Meilenstein unter **Beitragsquelle** eine
Routine wählen (binär oder Anzahl). Nur vollständig erledigte gespeicherte
Sessions ab Path-Start zählen. Teilfortschritt bleibt in der Routine erhalten.
Korrekturen aktualisieren denselben Path-Beitrag; geplante Minuten werden nicht
als tatsächliche Arbeitszeit verbucht.


## Übergabe an Claude Code

Zuerst [Implementierungs- und Prüfstand](docs/IMPLEMENTATION_STATUS.md), dann
[Architektur/Migrationen](docs/ARCHITECTURE.md) und [Roadmap](docs/ROADMAP.md) lesen.
Writer ist Schema 8; ältere Versionen 1–7 werden explizit übernommen. Kein Reset
bei Lesefehlern, keine erfundene Historie. Nach Schema-8-Speicherung keine ältere
Beta über denselben Datencontainer installieren. Neue Home-Widgets können bei
Migration verborgen sein und unter „Home anpassen“ aktiviert werden.

Ausschließlich auf dem bestehenden Beta-Branch arbeiten; jeden getesteten Abschnitt
committen, pushen und Remote-HEAD prüfen. CI-/Foto-/Screenshot-Anleitungen stehen
in [TEST_AND_RELEASE.md](docs/TEST_AND_RELEASE.md). Vollständige Geräteabnahme,
automatische Modes, historische Habit-Planrevisionen, flexible Neuplanung, lokale
Erinnerungen und Export/Backup sind noch offen. Keine produktive Onlineanbindung.
