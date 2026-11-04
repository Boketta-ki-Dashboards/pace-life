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

Views -> ViewModels/Use Cases -> Domain-Repository-Protokolle -> lokale / spätere Supabase-Adapter. Composition Root für Services. Test-Doubles ohne Netz. Die lokale Dateimigration ist implementiert. Backend-Schemata und Supabase-Migrationen bleiben ausschließlich Vorschläge und werden nicht produktiv ausgeführt.

## Mindest-Domainmodelle
Habit(id, title, goalType, schedule, createdAt, isArchived), HabitCompletion(id, habitID, date, actualValue, targetSnapshot), LifeMode(id, title, recurringSchedule, activeRules), ModeActivation(start, end?, modeID), HomeWidgetPreference(id, kind, position, isVisible). Datumsoperationen mit explizitem lokalem Tagesbezug, stabiler Wiederholung und Tests für Sommer-/Winterzeit.

Implementierte Erweiterungen: Routine, RoutineStep, RoutineSession, LifePath,
PathMilestone, PathEntry, DailyAdaptivePlan, AdaptiveEntry, LifeChapter,
LifeExperiment, ExperimentCheckIn, LocalCircle, CircleChallenge und
CircleContribution. Später: serverseitige Memberships, ShareGrants und ExternalPaceSource. Private Daten sind ohne Freigabe privat.

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

Ein versionierter Codable-JSON-Store ersetzt in Phase 1 SwiftData. Damit werden dieselben Domain-/Persistenzpfade unter Linux und macOS getestet, ohne Apple-Persistenztypen an die Domäne zu koppeln. Das kleine lokale MVP verwendet einen einzelnen MainActor-Writer und atomaren Dateiersatz. Ursprünglich `schemaVersion = 1`, aktuell Schema 8 mit expliziten Migrationen (siehe unten); unbekannte neuere Versionen und beschädigte Daten führen zum sichtbaren Ladefehler, niemals zum stillen Reset. Ein fehlgeschlagener Schreibvorgang verwirft den vorgeschlagenen Zustand. iOS-Dateischutz ist aktiviert. Keine Mehrfensterbearbeitung und keine mehreren Store-Instanzen auf dieselbe Datei.

Der vollständige Snapshot wird synchron gespeichert. Bei stark wachsender Historie ist ein Hintergrund-Actor/SQLite-Adapter hinter demselben Protokoll erforderlich; dies ist kein Mehrgeräte-Sync-Konzept. Archive erhalten Habit-Historie. Die App synchronisiert oder veröffentlicht keine Daten; Gerätesicherungen unterliegen den Systemeinstellungen.

### Zeit- und Zielsemantik

Erfüllungen sind pro Habit und lokalem gregorianischen Kalendertag eindeutig. Zeitzonenwechsel benennen bestehende Tage nicht um; derselbe lokale Tag wird dedupliziert. Der ursprüngliche Zielwert und Zieltyp werden beim ersten Eintrag eingefroren. Auch eine heutige Zieländerung ändert diesen Snapshot nicht. Zähler sind ganzzahlig, Dauer wird in Minuten erfasst, binär ist 0/1. Teilfortschritt ist sichtbar, aber erst Zielerreichung zählt als vollständig.

Ein aktiver Life Mode filtert seine ausgewählten Habits zusätzlich nach deren Wochentagen. Ohne aktiven Mode gelten alle fälligen Habits; ein leerer Mode enthält bewusst keine. Aktivierungswechsel werden historisiert und verändern keine Erfüllungen. Eigenständige Routinen sind implementiert (siehe unten); wiederkehrende Mode-Planung bleibt offen. Streaks verwenden den aktuellen Habit-Wochenplan; keine Rekonstruktion früherer Planänderungen.

### Navigation

Vier Root-Tabs mit festem, Safe-Area-geschütztem Dock; Editieren in nativen Sheets/Formularen. Der native SwiftUI-`TabView` mit Page-Stil übernimmt interaktives Root-Paging, Abbrechen und geschwindigkeitsabhängiges Einrasten. Die Auswahl bindet Seiten und Dock an denselben Zustand. Ein einzelner Root-NavigationStack enthält den Pager; Editor- und Detail-Sheets besitzen getrennte modale Navigation und empfangen keine Root-Gesten. Der Dock liegt außerhalb des Pagers im unteren Safe-Area-Inset. Die visuelle Abnahme aus VIDEO_REFERENCE.md bleibt erforderlich. Kein Backend-Listener und kein externes Auth-Lifecycle.

### Schema 2 und Routine-Sessions

Schema 2 führte Routinen ein. Der aktuelle Writer schreibt Schema 8.
`SchemaMigration.swift` liest Schema 1 explizit und ergänzt unter anderem leere
Routinen-/Session-Arrays sowie das zunächst verborgene Routinen-Widget.
Alle aktuellen Pflichtfelder werden streng decodiert. Laden
ändert keine Datei. Vor jedem atomaren Schreiben wird der Dateiinhalt mit dem
zuletzt geladenen/geschriebenen Stand verglichen; fremde Änderungen werden nicht
überschrieben. Das bleibt ein Single-Writer-Modell, kein Mehrprozess-Locking.

`Routines.swift` hält Vorlagen und Tages-Snapshots getrennt. Eine Session pro
Routine/lokalem Tag friert Schritte und Mode-Zuordnung ein. Pausierte Sessions
nehmen keine Schrittänderungen an. Archivierung erhält alle Sessions;
Mode-Löschung entfernt die aktuelle Zuordnung, bewahrt aber historische IDs.
SwiftUI ruft ausschließlich AppModel/Use Cases auf. Schritte sind unabhängig von
Habits; sie buchen keine erfundenen Habit-Werte.

### Schema 3: Life Paths

`Paths.swift` berechnet Meilensteine aus eindeutigen HabitCompletion-Quellen oder
manuellen PathEntry-Tageswerten, niemals aus wiederholtem Inkrementieren. Quelle,
Einheit und Path-Start sind nach Erstellung fest; Titel/Ziel und Reihenfolge sind
editierbar. Habit-Vorlagenänderungen bleiben von Completion-Snapshots getrennt.
Archivierte Quellen zählen weiter. Korrigierte Arbeit unterhalb eines abgeschlossenen
Path-Ziels öffnet den Path wieder. Archivierung erhält ein gültiges Abschlussdatum.
Wird dieser Abschluss später durch eine Korrektur ungültig, entfällt das Datum,
der Archivstatus bleibt erhalten. Manuelle und Habit-Beiträge sind pro Meilenstein
exklusiv. Es werden keine Minuten mit Zählwerten vermischt.

Schema 3 führte Paths ein; der heutige Schema-4-Writer übernimmt sie mit einem
expliziten Schema-3-DTO. Die Schema-1-/Schema-2-DTOs erhalten ebenfalls alle alten
Felder einschließlich Routine-Sessions. Aktuelle Pflichtarrays sind strikt.

### Schema 4: Pace Adaptive

`AdaptiveEngine` ist eine reine Funktion. Es reduziert ausschließlich bekannte
Minuten-Ziele. Routinezeiten und explizit geschützte Habits bilden feste Kosten;
fehlende Dauern werden separat gezählt. Niedrige Energie/hohe Belastung reduzieren
das Budget transparent; aktive Path-Verknüpfungen erhalten doppeltes Gewicht.
`DailyAdaptivePlan` friert Originale, Vorschläge und Eingaben pro zivilem Tag ein.
`AdaptiveEntry` speichert Zustimmung und akzeptiertes Ziel getrennt. Historische
Entscheidungen sind nicht veränderbar. Wiederholtes Erstellen ist idempotent.

HabitCompletion verwendet das Original des Tagesplans, falls noch kein
Completion-Snapshot vorliegt. Der Istwert fließt unverändert in Paths; weder
akzeptierte Kürzung noch Null-Ziel erzeugen eine fiktive volle Erfüllung. Der
aktuelle Plan kann nach Ablehnung über Budget bleiben und zeigt dies explizit.
Der Schema-4-Writer verlangt `adaptivePlans`; explizite DTOs für 1/2/3 ergänzen
leere Pläne und ein verborgenes Adaptive-Widget unter Erhalt aller bisherigen Daten.

### Kalenderprojektion ohne erfundene Historie

`PlanningCalendar` bildet Wochen/Monate durch zivile gregorianische Tage in der
lokalen Zeitzone ab, nicht durch Addition von 86400 Sekunden. `DayOverview`
trennt gespeicherte Fakten von Planung: vergangene Pläne sind `nil` (unbekannt),
heutige Pläne verwenden den aktuellen Mode, Zukunft ist eine gekennzeichnete
Vorschau. Routine-Sessions und Adaptive-Originale bleiben historisch nachvollziehbar.
Diese Ansicht ersetzt keine noch ausstehenden Habit-Planrevisionen.

### Schema 5: Life Chapters und private Fotodateien

`LifeChapter` enthält Zeitraum, Kategorie, Path-IDs (einschließlich archivierter
Paths), Erinnerungen/Meilensteine, Zeitstempel und Foto-UUIDs. Es gibt kein öffentliches
Sichtbarkeitsfeld. `SchemaFourState` erhält alle alten Felder und ergänzt eine leere
Chronik; aktuelle Pflichtfelder werden streng gelesen.
`ChapterPhotoRepository` trennt Medien vom JSON. Der File-Adapter akzeptiert nur
UUID-Dateinamen, begrenzt Dateigrößen, prüft reguläre Dateien und verwendet atomare
Writes mit vollständigem iOS-Dateischutz. Import speichert die Datei vor der
Referenz; Fehler entfernen nur die gerade erzeugte Datei. Nach erfolgreicher
Mutation bereinigt AppModel nicht mehr referenzierte Fotos, unter Einschluss aller
Archive. Fehlende Fotos verhindern nicht das Laden der Chronik. Der iOS-Adapter
verkleinert Bilder und entfernt Originalmetadaten durch erneutes JPEG-Encoding.

### Schema 6: Life Experiments

`LifeExperiment`, `ExperimentMetric` und `ExperimentCheckIn` bleiben getrennte
Domain-Typen. Ein Check-in pro Experiment/zivilem Tag speichert nur tatsächlich
eingegebene Werte; eine Korrektur ersetzt den Tag. Numerische Werte, Minuten,
ganzzahlige Skalen und binäre Werte werden typgerecht validiert. Messdefinitionen
bleiben nach Erstellung unverändert. `ExperimentSummary` liefert Messpunkte,
fehlende erwartete Tage, Mittelwert und optional Ausgangswert/letzten Wert/Differenz.
Es gibt keine Interpolation oder kausale Aussage. Wiederholung kopiert nur die
Definition, mit neuen IDs und ohne Werte/Baselines. Habit-Links dienen der
Navigation, buchen keine fiktiven Messungen. Schema 5 wird explizit gelesen,
inklusive Chapter-Medienreferenzen; Schema 6 verlangt `experiments` und
`experimentCheckIns`. Civil-Day-Arithmetik erfolgt gregorianisch ohne DST-Drift.

### Schema 7: lokale Circles und explizite Freigaben

`LocalCircle` enthält ausschließlich lokale Konfiguration und `CircleDemoMember`.
`CircleChallenge` definiert Zeitraum, feste Einheit und Gruppenziel. Beiträge
referenzieren entweder einen manuellen Tageswert pro Mitglied oder genau eine
gespeicherte HabitCompletion; Schlüssel verhindern doppelte Quellen pro Challenge.
`isShared` ist standardmäßig false. Der widerrufliche Grant auf eine Completion
folgt deren Korrekturen, ohne den privaten Wert zu kopieren oder zu verändern.
`CircleProgress` berechnet eigene und simulierte Summen getrennt; Simulationen
lassen sich in den Einstellungen ausschließen. Abschluss und Archiv stoppen
neue Eingaben, erlauben aber weiterhin Widerruf/Löschen.

StateRepository bleibt die Persistenzgrenze. Eine spätere Backendintegration
braucht getrennte echte Identitäten, serverseitige Autorisierung und einen
freigegebenen Vertrag; Demo-Rollen sind dafür niemals Berechtigungen. Schema 6
wird explizit übernommen, mit drei leeren Circle-Arrays und unveränderter Historie.
Schema 7 verlangt alle drei Arrays, beschädigte Daten werden nicht als leer geladen.

### Schema 8: Routine-Sessions als Path-Quelle

`PathMilestone.routineID` ist eine optionale, nach Erstellung feste Alternative
zu Habit oder manueller Quelle. Nur komplett erledigte gespeicherte Sessions ab
Path-Start zählen, jede höchstens einmal. Binär bedeutet mindestens eine Session,
Zähler eine Anzahl. Dauer ist ausgeschlossen: geplante Schrittminuten sind keine
Messwerte. Korrekturen verwenden dieselbe Ableitung und können Path-Abschlüsse
wieder öffnen; archivierte Vorlagen und historische Session-Snapshots bleiben
erhalten. Schema 7 wird explizit übernommen. Der neue Writer verhindert, dass
eine ältere App neue Quellen irrtümlich als manuelle Beiträge interpretiert.
