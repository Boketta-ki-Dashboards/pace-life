# PACE LIFE – VOLLSTÄNDIGER FUNKTIONS- UND QUALITÄTSSPRINT

## 0. DEINE ROLLE UND DAS ENDZIEL

Du bist der verantwortliche Senior-iOS-Architekt, SwiftUI-Entwickler, UX-Engineer und Quality-Assurance-Engineer für Pace Life.

Pace Life ist eine eigenständige native iPhone-App innerhalb der Pace-Familie von Boketta International Studios.

**Dein Ziel ist eine möglichst vollständige, zusammenhängende und tatsächlich funktionsfähige Offline-Beta aller sieben Pace-Life-USPs.**

Ich bin für einen längeren Zeitraum nicht verfügbar. Arbeite deshalb innerhalb dieser Aufgabe möglichst weitgehend eigenständig, ohne mich für gewöhnliche Architektur-, Design- oder Implementierungsentscheidungen zu unterbrechen.

Wichtig: Ich möchte keine Ansammlung von sieben Design-Prototypen. Die Funktionen sollen echte Daten speichern, miteinander kommunizieren, nach einem Neustart weiter funktionieren und in realistischen Benutzerabläufen testbar sein.

**Verbindliche Entwicklungsphilosophie:**

- Funktionsfähigkeit vor bloßer Optik.
- Datenintegrität vor Geschwindigkeit.
- Durchgängige Benutzerabläufe vor isolierten Demo-Screens.
- Konsistente Architektur vor übergroßen Swift-Dateien.
- Echte Tests vor unbelegten Fertigmeldungen.
- Hochwertige Pace-Designsprache statt generischer Habit-Tracker-Oberflächen.

Ein Feature ist erst fertig, wenn seine zentralen Aktionen tatsächlich funktionieren, seine Daten korrekt gespeichert werden und die wichtigsten Fehlerfälle getestet sind.

## 1. BESTEHENDES PROJEKT UND SICHERHEIT

Repository:

`Boketta-ki-Dashboards/pace-life`

Ausgangsbranch:

`codex/pace-life-phase-one`

Bekannter Phase-1-Commit:

`c2299e5`

Verwende diesen Entwicklungsstand als Grundlage. Prüfe zunächst, ob bereits neuere Commits vorhanden sind, und überschreibe keine neueren Änderungen.

Lies vollständig:

- `AGENTS.md`
- `README.md`
- `05_CODEX_KICKOFF_PROMPT.md`
- alle vorhandenen Dokumente unter `docs/`
- vorhandene Swift-Modelle, Use Cases, Store-Implementierung und Tests

**Absolute Projektgrenze:** Das Pace-Social-Repository gehört ausschließlich Claude. Du darfst es weder öffnen noch klonen, analysieren oder verändern.

Keine produktiven Supabase-Eingriffe, keine Migrationen im bestehenden Backend und keine eigenmächtige Account-Verknüpfung.

Erstelle für die Weiterentwicklung einen eigenen Entwicklungsbranch. Bewahre die bisherigen Funktionen vollständig.

## 2. ZUERST: BUILD, DATENBESTAND UND ARCHITEKTUR ABSICHERN

### 2.1 Fehlgeschlagenen iOS-Build reparieren

Der GitHub-Actions-Lauf:

https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41043535208

ist fehlgeschlagen.

Fehler:

`could not find module 'PaceLifeCore' for target 'x86_64-apple-ios-simulator'; found: arm64-apple-ios-simulator`

Untersuche systematisch:

- Die Integration des lokalen Swift-Packages.
- Xcode-Projektgenerator und Build-Konfiguration.
- Simulatorarchitekturen und Destinationen.
- Scheme- und Target-Abhängigkeiten.
- Swift-6-Konfiguration.
- Unterschiede zwischen macOS-CI und späterem Apple-Silicon-Mac.

Behebe die wirkliche Ursache. Keine bloßen Einstellungen verwenden, die ein Problem verstecken und den Build auf anderen Geräten beschädigen.

Verifiziere danach mindestens einen erfolgreichen iOS-Simulator-Build. Führe die verfügbaren Core- und UI-Tests aus. Prüfe den Status des GitHub-Actions-Laufs.

Erst nach erfolgreicher Build-Grundlage größere neue Module integrieren.

### 2.2 Vorhandene Datenstruktur erhalten

Aktuell existieren bereits:

- `Habit`
- `HabitCompletion`
- `LifeMode`
- `ModeActivation`
- `HomeWidgetPreference`
- `AppSettings`
- `LifeState`
- `LifeStore`
- `JSONStateRepository`
- ein versionierter JSON-Datenspeicher

Das vorhandene System verwendet derzeit Schema-Version 1.

**Extrem wichtig:** Erweitere diese Architektur, ohne bestehende Daten unbrauchbar zu machen.

Implementiere eine versionierte, getestete Migration von Schema 1 auf das notwendige neue Schema.

Verbindliche Anforderungen:

1. Bestehende Habits, Erfüllungen, Life Modes, Aktivierungen, Widget-Einstellungen und Spracheinstellungen bleiben vollständig erhalten.
2. Migrationen dürfen nicht automatisch eine leere Datenbank erzeugen, wenn alte Daten nicht gelesen werden können.
3. Beschädigte oder unbekannte neuere Datenversionen dürfen niemals stillschweigend überschrieben werden.
4. Schreiboperationen müssen atomar bleiben.
5. Bei einem Schreibfehler dürfen die angezeigten Daten nicht fälschlich als gespeichert gelten.
6. Historische Zielwerte, Wochentage und Erfüllungen dürfen sich durch spätere Änderungen nicht rückwirkend verändern.
7. Neue Beziehungen benötigen stabile UUIDs und überprüfte Referenzen.
8. Vor strukturellen Umstellungen müssen Migrationstests mit echten Schema-1-Testfixtures bestehen.
9. Ein App-Update darf nicht dazu führen, dass alle bisherigen Streaks oder Tagesergebnisse verschwinden.
10. Dateien, Fotos und sonstige große Binärdaten dürfen nicht als unkontrollierte Base64-Inhalte in die zentrale JSON-Datei geschrieben werden.

Behalte das bestehende Repository-/Use-Case-Konzept nach Möglichkeit bei. Ein kompletter Wechsel der Datenbanktechnologie ist nicht erforderlich, solange die vorhandene Lösung zuverlässig erweiterbar ist.

## 3. PRODUKTSTRUKTUR UND BENUTZERFÜHRUNG

Pace Life soll vier Haupttabs haben:

**HEUTE:** Tagesübersicht, aktueller Life Mode, Tagesplan, Habits, Pace Adaptive, konfigurierbare Widgets und aktuelle Prioritäten.

**ENTWICKLUNG:** Life Paths, Meilensteine, persönliche Statistik, Life Chapters, Life Experiments und längerfristiger Fortschritt.

**KREISE:** Pace Circles, Gruppenziele, gemeinsame Challenges, Mitglieder, gemeinsame Fortschritte und lokale Testumgebung.

**PROFIL:** Persönliche Übersicht, Einstellungen, Darstellung, Sprache, Erinnerungen, Datenschutz, Backup und Pace Connect.

Alle sieben Hauptmodule müssen über eine nachvollziehbare Navigation erreichbar sein.

Wichtige Funktionen dürfen nicht hinter beliebig vielen Untermenüs versteckt werden.

Jeder Bereich benötigt:

- Eine sinnvolle Übersichtsseite.
- Eine echte Detailansicht.
- Erstellen und Bearbeiten.
- Löschen oder Archivieren, je nach Datentyp.
- Verständliche Leerzustände.
- Fehlerzustände und Validierung.
- Eine sichere Zurücknavigation.
- Speicherung und Wiederherstellung.
- Gut lesbare, konsistente Pace-Komponenten.

Benutzer müssen erkennen können, wo sie sich befinden und welche Aktion möglich ist.

## 4. MODUL 1 – LIFE MODES UND ROUTINEN

Die bestehenden Life Modes sollen zu einem echten System zur Alltagsorganisation ausgebaut werden.

### Life Modes

Ein Life Mode besitzt:

- Stabile ID.
- Namen.
- Optionales SF-Symbol und eine dezente visuelle Kennzeichnung.
- Beschreibung.
- Zugeordnete Habits.
- Zugeordnete Routinen.
- Optional wiederkehrende Wochentage.
- Optional geplante Aktivierungszeiten.
- Individuelle Tagesprioritäten.
- Aktivierungsstatus und Aktivierungshistorie.

Nutzer können Modi erstellen, ändern, duplizieren, aktivieren, deaktivieren, archivieren und löschen.

Ein manueller Wechsel muss automatisch vorgesehene Wechsel sinnvoll übersteuern können. Definiere dafür transparente Regeln und verhindere überraschendes Hin- und Herspringen.

### Routinen

Ergänze eigenständige Routinen.

Eine Routine besteht aus:

- Titel und Beschreibung.
- Optionaler geplanter Tageszeit.
- Wiederholungstagen.
- Einer sortierbaren Liste einzelner Schritte.
- Optionaler Dauer pro Schritt.
- Verknüpftem Life Mode.
- Fortschritt und Tageshistorie.

Nutzer können eine Routine starten, einzelne Schritte abschließen, unterbrechen und fortsetzen.

Eine Routine darf teilweise erledigt sein. Teilweise erledigt ist nicht vollständig erledigt.

### Verbindlicher Testablauf

Ein Nutzer erstellt den Life Mode „Arbeitstag“, legt eine Morgenroutine mit vier Schritten an und verknüpft zwei Habits.

Am Montag wird der Modus aktiv, die korrekten Aufgaben erscheinen auf dem Homescreen.

Der Nutzer erledigt zwei von vier Routinen-Schritten. Die Anzeige zeigt den echten Teilfortschritt.

Er beendet die App und öffnet sie erneut. Der Fortschritt bleibt erhalten.

Er wechselt zum Life Mode „Wochenende“. Frühere Arbeitstag-Erfüllungen bleiben unverändert.

## 5. MODUL 2 – LIFE PATHS

Life Paths verbinden langfristige Lebensziele mit täglichen Handlungen.

### Datenmodell

Ein Life Path besitzt mindestens:

- UUID.
- Titel und Beschreibung.
- Kategorie.
- Startdatum.
- Optionales Zieldatum.
- Status: aktiv, pausiert, abgeschlossen, archiviert.
- Meilensteine mit Reihenfolge.
- Verknüpfte Habits und gegebenenfalls Routinen.
- Fortschrittshistorie.
- Abschlussdatum.
- Optionales Titelbild oder Symbol.

### Funktionalität

Nutzer können mehrere Life Paths parallel verfolgen.

Jeder Path kann beliebig viele Meilensteine enthalten.

Meilensteine unterstützen beispielsweise:

- Binäre Erfüllung.
- Numerische Zielwerte.
- Dauerbasierte Ziele.
- Manuell bestätigte Etappen.

Der Path-Fortschritt muss aus nachvollziehbaren Ergebnissen berechnet werden.

Ein beliebiger Habit-Abschluss darf einen Life Path nicht automatisch als vollständig erledigt markieren.

Wenn Habits zu Life Paths beitragen, muss die konkrete Beitragsregel im Datenmodell definiert sein. Doppelzählungen müssen ausgeschlossen werden.

### Benutzerablauf

Ein Nutzer erstellt den Path „Russisch B2 erreichen“.

Meilensteine:

1. Grammatikthemen wiederholen.
2. 100 zusätzliche Lernstunden sammeln.
3. 30 Texte auf Russisch schreiben.
4. B2-Test absolvieren.

Er verknüpft seinen Habit „Russisch lernen“ mit dem Lernstunden-Meilenstein.

Er trägt 45 Minuten Lernen ein. Die verknüpfte Fortschrittsanzeige wird entsprechend aktualisiert.

Ändert er den Habit später, darf der bereits erreichte historische Fortschritt nicht verschwinden oder doppelt gezählt werden.

### Oberflächen

- Übersicht aktiver Life Paths.
- Detailansicht mit Fortschrittsring.
- Meilenstein-Timeline.
- Verknüpfte Aktivitäten.
- Bearbeitung und Statuswechsel.
- Abgeschlossene Paths.
- Passendes Homescreen-Widget.

## 6. MODUL 3 – PACE ADAPTIVE

Dies ist einer der wichtigsten USPs. Implementiere nicht einfach einen zufälligen Tippgenerator.

Pace Adaptive soll tägliche Ziele nachvollziehbar und kontrolliert anpassen.

### Benutzereingaben

- Heute verfügbare Zeit in Minuten.
- Energie als verständliche Skala.
- Selbst eingeschätzte Belastung.
- Wichtigste Tagesprioritäten.
- Optional bevorzugte Zeitfenster.

### Regel-Engine

Entwickle eine deterministische und separat testbare Entscheidungslogik.

Die Engine soll berücksichtigen:

- Welche Habits und Routinen heute geplant sind.
- Welcher Life Mode aktiv ist.
- Wie viel Zeit die geplanten Aufgaben benötigen.
- Welche Aktivitäten zu wichtigen Life Paths gehören.
- Welche Aufgaben flexibel reduziert werden dürfen.
- Welche Aufgaben unbedingt unverändert bleiben sollen.

Die Engine erstellt konkrete Empfehlungen, beispielsweise:

Original: 60 Minuten lernen.

Vorschlag: 15 Minuten lernen.

Begründung: Heute stehen nur 30 Minuten für deine geplanten Aktivitäten zur Verfügung.

Der Nutzer muss Vorschläge akzeptieren, ablehnen oder manuell verändern können.

### Ganz wichtige Fortschrittsregeln

Es müssen drei unterschiedliche Werte erhalten bleiben:

1. Ursprüngliches Ziel.
2. Angepasstes Tagesziel.
3. Tatsächlich erreichter Wert.

Beispiel:

Ursprünglich: 60 Minuten.

Adaptive-Ziel: 15 Minuten.

Erreicht: 15 Minuten.

Das bedeutet:

- Angepasstes Tagesziel erfüllt.
- Ursprüngliches Tagesziel zu 25 % erfüllt.

Es darf nicht suggeriert werden, dass 60 Minuten geleistet wurden.

Die UI muss diesen Unterschied verständlich und motivierend anzeigen.

### Weitere Regeln

- Keine rückwirkenden Änderungen abgeschlossener Tage.
- Keine automatisch bestätigten Vorschläge.
- Keine Anpassung eines langfristigen Ziels ohne Nutzerzustimmung.
- Anpassungen für einen einzelnen Tag dürfen nicht ungewollt dauerhaft werden.
- Akzeptierte Vorschläge können rückgängig gemacht werden.
- Nach App-Neustart bleiben Tagesentscheidungen erhalten.
- Keine negativen oder beschämenden Texte.
- Keine bezahlte KI-API erforderlich.

### Verbindlicher Test

Ein Nutzer hat drei Aktivitäten mit insgesamt 100 Minuten geplant, aber nur 30 Minuten verfügbar.

Pace Adaptive schlägt einen realistischen Plan vor, dessen Gesamtumfang das Zeitbudget nicht überschreitet beziehungsweise klar ausweist, wenn nicht reduzierbare Aktivitäten es überschreiten.

Der Nutzer bestätigt zwei Änderungen, lehnt eine ab und startet anschließend eine Routine.

Nach Neustart sind Originalwerte, Anpassungen und tatsächliche Fortschritte weiterhin getrennt nachvollziehbar.

## 7. MODUL 4 – LIFE CHAPTERS

Implementiere eine hochwertige, persönliche Lebenschronik.

### Daten

Ein Chapter besitzt:

- UUID.
- Titel.
- Zeitraum.
- Beschreibung.
- Kategorie.
- Bilder.
- Persönliche Erinnerungen.
- Verknüpfte Meilensteine oder Life Paths.
- Zeitstempel.
- Sichtbarkeitsstatus, standardmäßig privat.

### Aktionen

- Chapter erstellen.
- Datum und Zeitraum ändern.
- Fotos mit nativer iOS-Fotoauswahl hinzufügen.
- Fotos entfernen.
- Persönliche Einträge hinzufügen.
- Einträge bearbeiten.
- Chapter archivieren und löschen.
- Chronologisch sortieren.
- Zwischen Timeline und Detailansichten wechseln.

### Technische Vorgaben

Verwende für Fotos geeignete lokale Dateien mit stabilen Referenzen. Keine großen Bilder im zentralen JSON-Dokument speichern.

Verhindere verlorene Bildreferenzen und unbeabsichtigtes Löschen gemeinsam verwendeter Medien.

Die Fotoauswahl muss abgebrochen werden können, ohne einen fehlerhaften oder leeren Eintrag anzulegen.

### Testablauf

Ein Nutzer erstellt „Mein Ausbildungsabschluss“, fügt drei Fotos hinzu und verknüpft einen abgeschlossenen Life Path.

Er beendet die App vollständig.

Nach dem erneuten Öffnen sind Zeitraum, Text, Fotos und Verknüpfung vorhanden.

Wird ein verknüpfter Path später archiviert, darf das Chapter nicht beschädigt werden.

## 8. MODUL 5 – LIFE EXPERIMENTS

Life Experiments dienen dazu, persönliche Gewohnheiten über begrenzte Zeiträume zu untersuchen.

### Experiment erstellen

Ein Experiment enthält:

- Titel.
- Fragestellung.
- Startdatum.
- Enddatum.
- Gewünschte Dauer.
- Ausgangssituation.
- Individuelle Messgrößen.
- Optional verknüpfte Habits.
- Tägliche Check-ins.
- Reflexion.
- Status und Abschlussauswertung.

Unterstütze 7, 14, 30 Tage und eigene Zeiträume.

### Messgrößen

Mindestens:

- Ja/Nein.
- Numerischer Wert.
- Zeitdauer.
- Selbsteinschätzung auf einer definierten Skala.

### Funktionalität

- Tägliche Werte erfassen und korrigieren.
- Fehlende Tage als fehlende Daten behandeln, nicht automatisch als null.
- Experimentfortschritt anzeigen.
- Diagramme mit korrekt beschrifteten Achsen.
- Ausgangs- und Endwerte vergleichen.
- Experiment vorzeitig beenden.
- Experiment wiederholen, ohne alte Daten zu überschreiben.
- Archiv und Verlauf.

### Testablauf

Ein Nutzer erstellt ein 14-tägiges Experiment „Früher schlafen“.

Er erfasst jeden Tag seine Schlafdauer und subjektive Energie.

An einem Tag gibt es keinen Eintrag.

Die Auswertung darf diesen fehlenden Eintrag nicht als null Stunden Schlaf interpretieren.

Nach Abschluss sieht er seine Messwerte und deren Veränderung über die Zeit.

Keine unzulässigen Aussagen wie „Das Experiment beweist, dass mehr Schlaf deine Produktivität erhöht.“

Die Auswertung muss zwischen Beobachtung und Ursache unterscheiden.

## 9. MODUL 6 – PACE CIRCLES

Pace Circles sollen später gemeinsame Gruppenziele mit echten Pace-Social-Freunden unterstützen.

Bis die gemeinsame Authentifizierung freigegeben ist, entwickle eine umfangreiche, klar gekennzeichnete lokale Testumgebung.

### Funktionalität

- Gruppen beziehungsweise Circles erstellen.
- Gruppennamen und Beschreibungen.
- Demo-Mitglieder verwalten.
- Mitgliedsrollen darstellen.
- Gemeinsame Ziele erstellen.
- Zielwerte, Einheiten und Enddaten.
- Gruppen-Challenges mit Start und Ende.
- Persönliche Beiträge erfassen.
- Gruppenfortschritt berechnen.
- Ergebnisse und Zwischenstände anzeigen.
- Abgeschlossene Challenges archivieren.
- Gruppenziele bearbeiten und löschen.
- Optionale Gruppenziel-Widgets.

### Datenschutz

Persönliche Habits, Life Paths, Chapters und Experimente bleiben privat.

Ein gemeinsames Ziel darf nur ausdrücklich ausgewählte Beitragsdaten verwenden.

Ein Nutzer muss eine Freigabe nachvollziehen und widerrufen können.

### Lokaler Testmodus

Kennzeichne sämtliche Demo-Mitglieder deutlich als Demo.

Es darf weder ein echtes Pace-Social-Login noch eine bestehende Freundschaft vorgetäuscht werden.

Der Nutzer soll selbst mehrere Demo-Mitglieder und deren Beispielbeiträge anlegen oder bearbeiten können, um Gruppenberechnungen zu überprüfen.

Trenne simulierte Beiträge eindeutig von echten, selbst eingegebenen Fortschrittswerten.

### Testablauf

Der Nutzer erstellt den Circle „Lerngruppe“ mit vier Demo-Mitgliedern.

Er erstellt die Challenge „Gemeinsam 100 Lernstunden sammeln“.

Die Mitglieder tragen unterschiedliche Werte bei.

Die Gruppenanzeige summiert die zugelassenen Beiträge korrekt.

Wird ein Beitrag geändert oder gelöscht, muss der Gruppenfortschritt korrekt neu berechnet werden.

Die App wird beendet und neu geöffnet. Der Teststand bleibt erhalten.

## 10. MODUL 7 – PACE CONNECT

Implementiere die vollständige technische Vorbereitung einer späteren sicheren Pace-Family-Anbindung.

Benötigte Schnittstellen:

- Gemeinsame Nutzeridentität.
- Profildaten.
- Freundschaften.
- Gruppenmitgliedschaften.
- Gruppen-Challenges.
- Appübergreifende Fortschrittsdaten.
- Verbindungs- und Berechtigungsstatus.

### Zwingende Regeln

- Keine produktive Supabase-Integration ohne Freigabe.
- Kein Zugriff auf Pace Social.
- Keine stillschweigende Erstellung eines zweiten Accounts.
- Keine Auth-ID mit öffentlicher Profile-ID verwechseln.
- Kein Service-Role-Key in der App.
- Kein angeblich aktives Cross-App-Feature ohne reale Verbindung.

Erstelle eine nachvollziehbare Pace-Connect-Oberfläche, die verfügbare und zukünftige Integrationen korrekt unterscheidet.

Bereite Adapter und Tests vor, aber simuliere keine echte Pace-Social-Verbindung.

## 11. DIE ZUSAMMENHÄNGENDE PACE-LIFE-ERFAHRUNG

Die Module dürfen nicht isoliert bleiben.

Ein Nutzer muss folgenden durchgängigen Ablauf ausführen können:

1. Einen Life Path erstellen: „Russisch B2 erreichen“.
2. Den Habit „Täglich Russisch lernen“ anlegen.
3. Diesen Habit mit dem Life Path verknüpfen.
4. Den Life Mode „Arbeitstag“ erstellen.
5. Den Habit und eine Lernroutine diesem Modus zuordnen.
6. Heute wenig verfügbare Zeit in Pace Adaptive angeben.
7. Eine reduzierte Lernzeit vorgeschlagen bekommen.
8. Die Anpassung bestätigen.
9. 15 Minuten tatsächlich lernen.
10. Den Tagesfortschritt korrekt sehen.
11. Den echten Beitrag zum Life Path sehen.
12. Parallel ein 14-Tage-Lernexperiment durchführen.
13. Nach mehreren Tagen den Verlauf auswerten.
14. Einen wichtigen Abschluss als Life Chapter festhalten.
15. Optional ausgewählte Ergebnisse in einer lokalen Pace-Circles-Challenge verwenden.

**Das ist der wichtigste Ende-zu-Ende-Test des gesamten Projekts.**

Wenn irgendein Schritt nicht funktioniert, dokumentiere und behebe die Ursache, statt den Ablauf nur in Screenshots nachzustellen.

## 12. HOMESCREEN, KALENDER UND STATISTIKEN

### Konfigurierbarer Homescreen

Erweitere die vorhandenen Widgets um:

- Tagesfortschritt.
- Aktiven Life Mode.
- Heutige Habits.
- Heutige Routinen.
- Pace-Adaptive-Empfehlungen.
- Life Paths.
- Nächste Meilensteine.
- Aktive Experimente.
- Life Chapters.
- Circles-Challenges.
- Wochenkalender.
- Persönliche Entwicklung.

Jedes Widget muss aus echten Datenquellen gespeist werden.

Bei fehlenden Daten soll es einen sinnvollen Leerzustand besitzen.

Nutzer können Widgets ein- und ausblenden und neu sortieren. Speichere die Reihenfolge dauerhaft.

Bestehende Widget-Einstellungen müssen auch nach einer Schemaänderung erhalten bleiben.

### Kalender

Erstelle eine funktionale Wochen- und Monatsübersicht.

Sie soll geplante und abgeschlossene Aktivitäten korrekt unterscheiden.

Achte auf Zeitzonen, Sommerzeit, Monatswechsel, zurückliegende Tage und unterschiedliche Wiederholungsmuster.

### Streaks

Implementiere nachvollziehbare Streak-Regeln.

Ein nicht geplanter Tag darf nicht automatisch als versäumte Gewohnheit gelten.

Eine Änderung zukünftiger Wochentage darf abgeschlossene historische Erfüllungen nicht rückwirkend entwerten.

Bei Adaptive-Zielen müssen ursprüngliche und angepasste Erfüllung klar unterschieden werden.

### Erinnerungen

Wenn technisch sinnvoll, ergänze native lokale Benachrichtigungen über UserNotifications.

Berechtigung erst bei Bedarf anfragen.

Erinnerungen müssen bearbeitet und deaktiviert werden können.

Lösche geplante Benachrichtigungen, wenn die zugehörige Routine oder Gewohnheit entfernt wird.

## 13. DESIGN UND NAVIGATION – VERBINDLICH

Verwende das originale Pace-Designsystem aus dem Repository.

Die beiden Pace-Social-Videos werden ausschließlich im Codex-Chat bereitgestellt, sofern die Umgebung sie akzeptiert.

Nutze sie insbesondere für:

- Die untere HUD-/Tab-Bar.
- Aktive Mint-Hervorhebung.
- Horizontales Wischen zwischen Haupttabs.
- Zurückziehbare, interaktive Swipe-Gesten.
- Vertikale Scrollbereiche.
- Header und Safe Areas.
- Öffnen und Schließen von Unterseiten.
- Animationen und Übergänge.

Falls die Videos nicht verfügbar sind, verwende die ausführliche Design- und Bewegungsdokumentation aus GitHub.

### Nicht verhandelbare UI-Regeln

- Keine abgeschnittenen Inhalte.
- Keine Texte hinter der iPhone-Statusleiste.
- Keine Buttons hinter dem Home Indicator.
- Keine springenden Header.
- Keine doppelt gestapelten Navigationspfade.
- Kein versehentlicher Tab-Wechsel während Texteingaben.
- Keine Gestenkonflikte mit der Widget-Sortierung.
- Keine unpassenden zusätzlichen Markenfarben.
- Kein generisches Glas-/Neon-Design.
- Kein reines Design-Dummy ohne Funktion.

Deutsch, Englisch und Russisch vollständig berücksichtigen.

Die Sprachwahl soll innerhalb der App unmittelbar wirken.

User-generierte Texte werden selbstverständlich nicht automatisch übersetzt.

## 14. DATENQUALITÄT UND FEHLERVERHALTEN

Implementiere für alle neuen Module:

- Eingabevalidierung.
- Eindeutige Identitäten.
- Stabile Beziehungen.
- Fehlerbehandlung.
- Speicherkontrolle.
- Datenmigration.
- Verständliche Fehlermeldungen.
- Lösch- und Archivierungslogik.
- Keine doppelten Datensätze durch mehrfaches Tippen.
- Korrekte Rückgängig-Aktionen, wo fachlich sinnvoll.
- Konsistente Anzeige nach Änderungen.
- Sichere Behandlung fehlender oder archivierter verknüpfter Objekte.

Achte darauf, dass ein gelöschter oder archivierter Habit keine unbrauchbaren Referenzen in Life Paths, Routinen, Experiments oder Circles hinterlässt.

Erhalte historische Snapshots, wenn diese für die Nachvollziehbarkeit notwendig sind.

Keine automatischen Datenresets als Fehlerbehandlung.

## 15. VERBINDLICHE TESTSTRATEGIE

Jedes Modul benötigt geeignete automatisierte Tests.

### Mindestens zu prüfen

**Persistenz:** Daten bleiben nach vollständigem Neustart erhalten.

**Migration:** Ein valider Schema-1-Datenbestand wird korrekt übernommen.

**Habits:** Wochentage, Zieltypen, Teilfortschritte, Archivierung.

**Life Modes:** Aktivierung, Zeitplanung, Übersteuerung, Wechsel.

**Routinen:** Reihenfolge, Teilabschluss, Wiederaufnahme.

**Life Paths:** Meilensteine, Beitragsberechnung, Archivierung.

**Pace Adaptive:** Zeitbudget, Vorschläge, Ablehnung, Annahme, Rückgängig, ursprüngliche Zielwerte.

**Life Chapters:** Einträge, Bilder, Beziehungen und Dateiverwaltung.

**Life Experiments:** Messwerte, fehlende Tage, Zeiträume, Vergleiche.

**Pace Circles:** Gruppenberechnung, Änderungen, Berechtigungsmodell und Demo-Trennung.

**Pace Connect:** Unverbundene Zustände, Fehlerzustände und Adapter-Verträge.

**Navigation:** Tabs, Unterseiten, Zurücknavigation, Swipe-Gesten.

**Darstellung:** Hell/Dunkel, große Schrift und alle drei Sprachen.

### Testqualität

Tests dürfen nicht nur überprüfen, dass ein Objekt erstellt werden kann.

Sie müssen echte Änderungen und deren Auswirkungen auf verbundene Module prüfen.

Bevorzuge reproduzierbare, deterministische Tests mit kontrollierter Zeit und injizierten Test-Repositories.

Trenne Ergebnisse sauber in:

- Erfolgreich automatisch getestet.
- Erfolgreich im Simulator getestet.
- Nur manuell prüfbar.
- Noch ungeprüft.
- Fehlgeschlagen.

Behaupte niemals einen erfolgreichen Xcode- oder iPhone-Test, wenn dieser tatsächlich nicht durchgeführt wurde.

## 16. ARBEITSREIHENFOLGE UND PRIORISIERUNG

Arbeite in folgenden überprüfbaren Abschnitten:

### Abschnitt A – Fundament
- CI-/Xcode-Build reparieren.
- Vorhandene Tests absichern.
- Schema-Migration vorbereiten.
- Neue Domainmodelle und Beziehungen planen.

### Abschnitt B – Täglicher Alltag
- Life Modes vervollständigen.
- Eigenständige Routinen.
- Wiederholungen und Kalender.
- Verbesserte Habit-Historie.

### Abschnitt C – Wichtigste USPs
- Life Paths vollständig funktionsfähig.
- Pace Adaptive vollständig funktionsfähig.
- Beide mit Habits und Modes verbinden.
- Ende-zu-Ende-Test des täglichen Zielsystems.

### Abschnitt D – Persönliche Entwicklung
- Life Chapters.
- Fotoverwaltung.
- Life Experiments.
- Messwerte, Auswertungen und Timelines.

### Abschnitt E – Soziale Funktionen
- Pace Circles mit lokalem, klar markiertem Testmodus.
- Gruppenziele und Gruppenberechnungen.
- Freigabemodell.
- Pace Connect mit vorbereiteten Adaptern.

### Abschnitt F – Produktintegration
- Sämtliche neuen Homescreen-Widgets.
- Navigation und Kalender.
- Erinnerungen, soweit sinnvoll.
- Streaks und Statistiken.
- Konsistente UI und Sprachen.

### Abschnitt G – Qualität
- Vollständige Testdurchläufe.
- CI-Build.
- Migrationstests.
- Regressionsprüfung.
- Design-Politur.
- Dokumentation und Installationsanleitung.

### Regel bei begrenzter Ausführungszeit

Wenn nicht alles in dieser Ausführung möglich ist, priorisiere funktionierende, vollständig integrierte Module gegenüber sieben oberflächlichen Implementierungen.

Liefere nach Möglichkeit zuerst das durchgängige System aus Life Modes, Habits, Routinen, Life Paths und Pace Adaptive.

Anschließend Chapters, Experiments, Circles und Connect.

Lasse keine halbfertige Datenmigration oder einen bekannten Buildfehler unbeachtet zurück.

## 17. AUTONOMIE UND COMMITS

Arbeite ohne unnötige Rückfragen, soweit keine Sicherheitsfreigabe oder andere wesentliche Entscheidung notwendig ist.

Erstelle nach jedem abgeschlossenen Entwicklungsabschnitt einen nachvollziehbaren Git-Commit.

Nutze einen separaten Entwicklungsbranch.

Halte das Xcode-Projekt reproduzierbar und vermeide manuelle Änderungen, die beim nächsten Generatorlauf verloren gehen.

Aktualisiere fortlaufend:

- `docs/ARCHITECTURE.md`
- `docs/ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- Testdokumentation
- README mit Xcode-Anleitung

Wenn noch Ausführungskapazität verfügbar ist, arbeite nach einem erfolgreich abgeschlossenen Modul am nächsten Abschnitt weiter.

Erstelle keine scheinbar abgeschlossenen Funktionen allein, um die Roadmap vollständig aussehen zu lassen.

## 18. ABSCHLIESSENDE PRODUKTABNAHME

Am Ende möchte ich eine App, die ich in Xcode öffnen und auf meinem iPhone installieren kann, sofern die lokale Apple-Entwicklungsumgebung und das Signing dies erlauben.

Ich möchte echte, gespeicherte Daten verwenden können.

Ich möchte einen Life Path anlegen, daraus Tagesgewohnheiten ableiten, meinen Alltag über Life Modes organisieren, Ziele mit Pace Adaptive anpassen und meine Entwicklung über mehrere Tage verfolgen können.

Ich möchte Life Chapters mit Bildern anlegen, Experimente durchführen und Gruppenziele im lokalen Pace-Circles-Testmodus ausprobieren können.

Alle Module müssen eine zusammenhängende Benutzererfahrung bilden.

**Ein Feature darf nur als implementiert gelten, wenn es tatsächlich benutzbar ist. Es darf nur als verifiziert gelten, wenn die dafür vorgesehenen Tests nachweislich bestanden wurden.**

Echte gemeinsame Pace-Social-Konten und Online-Gruppen bleiben bis zur separaten technischen Freigabe ausdrücklich offen.

### Dein Abschlussbericht muss enthalten:

1. Aktueller Branch und Commit.
2. Tatsächlicher CI-/Xcode-Buildstatus.
3. Anzahl und Ergebnis der durchgeführten Tests.
4. Implementierungsstatus aller sieben USP-Module.
5. Welche Ende-zu-Ende-Benutzerabläufe tatsächlich funktionieren.
6. Noch vorhandene Bugs und technische Risiken.
7. Nicht implementierte beziehungsweise nur simulierte Funktionen.
8. Genauen Ablauf für meinen ersten iPhone-Test.
9. Die wichtigsten nächsten Schritte.

**Beginne jetzt mit dem bestehenden Phase-1-Code, behebe zunächst den nachgewiesenen CI-Buildfehler und arbeite anschließend selbstständig und in der beschriebenen Reihenfolge an einer möglichst vollständigen Pace-Life-Beta.**