# Versionierte Datenmigration und Dateninvarianten

Status: Schema 10 ist aktiviert. Explizite DTOs für Schema 1 bis 9 erhalten die bisherigen Daten; 69 Core-Tests bestanden (Swift 6.0.3/Linux, 8. November 2026). Die Simulator-Buildgrundlage ist auf Apple Silicon und Intel nachgewiesen. Die eingefrorene Datei `Packages/PaceLifeCore/Tests/PaceLifeCoreTests/Fixtures/schema-one.json` wurde mit dem originalen Schema-1-Serializer aus `c2299e5` erstellt. Ihre Originalfelder werden vor Änderungen an Domain und Repository geprüft.

## Übergang

Schema 1 explizit als altes DTO lesen und validieren, anschließend deterministisch auf das aktuelle Schema 8 abbilden. Neue Felder dürfen für Schema 1 kontrollierte Defaults bekommen, während das aktuelle Schema vollständig und streng decodiert werden muss. Beschädigte oder unbekannte neuere Versionen bleiben unverändert. Kein Fehlerpfad darf eine leere Datenbank über eine vorhandene schreiben. Der erste erfolgreiche Schreibvorgang ersetzt den vollständigen validierten Snapshot atomar; fehlgeschlagene Änderungen übernehmen keinen neuen UI-State.

Alle bisherigen UUIDs, Habits, Ziele, Erfüllungs-Snapshots, Mode-Aktivierungen, Widgets und Einstellungen werden exakt übernommen. Neue Widgets werden hinten und zunächst ausgeblendet ergänzt. Bilder liegen in separaten lokalen Dateien mit referenzgezählter Verwendung; nur Medienmetadaten und stabile IDs gehören ins JSON.

## Historische Pläne

Schema 1 speicherte keine Wochentagsrevisionen. Frühere Planänderungen sind daher nicht rekonstruierbar und dürfen durch Migration nicht erfunden werden. Die vorhandenen Erfüllungen bleiben Fakten. Für neue Tage sind versionierte Habit-Pläne und Tages-Snapshots vorgesehen; Planänderungen gelten erst ab ihrem dokumentierten Wirksamkeitsdatum. Eine künftige Migration muss den übernommenen Wochenplan ausdrücklich als Legacy-Baseline markieren; diese Revisionen sind noch nicht implementiert. Historische Auswertungen müssen bekannte Fakten von nicht mehr rekonstruierbaren Planungsdaten unterscheiden.

## Beziehungen und Beiträge

Routinen, Paths und Adaptive sind umgesetzt. Chapters, Experiments, lokale Circles und getrennte Mediendateien sind ebenfalls implementiert.

- Routine-Sessions speichern Reihenfolge, Schritttitel und Dauer als Tages-Snapshot. Spätere Bearbeitung der Vorlage verändert keine laufende/abgeschlossene Sitzung.
- Path-Meilensteine verwenden konkrete Beitragsregeln mit Einheit/Umrechnung. Beiträge werden anhand stabiler Quell-IDs upserted bzw. deterministisch berechnet, niemals bei jedem UI-Refresh inkrementiert. Ein korrigierter Habit-Wert korrigiert seinen Beitrag genau einmal.
- Adaptive speichert Originalziel, vorgeschlagenes/akzeptiertes Tagesziel und tatsächlichen Wert getrennt. Eine angenommene Kürzung verändert weder Habit-Vorlage noch langfristiges Path-Ziel. Ablehnung und Rückgängig bleiben eigene Tagesentscheidungen.
- Chapters referenzieren auch archivierte Paths. Medienlöschung muss alle noch bestehenden Referenzen berücksichtigen.
- Experiment-Check-ins verwenden eindeutige Experiment/Tag/Messgröße-Schlüssel; fehlende Daten bleiben fehlend.
- Circles übernehmen ausschließlich explizite Freigaben. Eigene und simulierte Demo-Beiträge haben getrennte Herkunft; Widerruf entfernt die Freigabe, niemals den privaten Quelldatensatz.
- Connect bleibt ohne externen Vertrag unverbunden; Auth- und öffentliche Profil-IDs sind getrennte Typen.

## Migrationsabnahme

Ein Test muss vor/nach Migration und nach erneutem Laden sämtliche bisherigen Felder vergleichen. Weitere Tests: unbekannte neuere Version, beschädigtes JSON, fehlende Pflichtfelder in Schema 2, referenzielle Inkonsistenz, doppelte IDs, fehlgeschlagener atomarer Schreibvorgang und wiederholtes Laden ohne doppelte Migration. Diese Prüfungen gelten für jeden neuen Schema-Writer.

## Umgesetzt am 3. November 2026

Schema 2 ist für Routinen aktiviert und mit dem eingefrorenen Schema-1-Fixture
geprüft. `SchemaOneState` übernimmt sämtliche Altwerte; neue Pflichtfelder sind
`routines` und `routineSessions`. Der neue Widget-Eintrag ist bei Migration
verborgen. Lesen migriert nur im Speicher, Schreiben ersetzt atomar. Ein Vergleich
mit dem zuletzt gelesenen Dateiinhalt schützt zusätzlich vor einem fremden Ersatz.
24 Core-Tests bestanden. Historische Habit-Planrevisionen und die nachfolgenden
USP-Modelle bleiben weitere Schema-Erweiterungen; sie sind nicht vorgetäuscht.

Schema 3 ergänzt `paths` und `pathEntries` sowie das bei Migration verborgene
Paths-Widget. Auch Schema 2 wird explizit gelesen, einschließlich aller
Routine-Snapshots. Ein Roundtrip-Test mit teilweise erledigter Routine und
abweichender Widget-Reihenfolge prüft den Erhalt. 28 Core-Tests bestanden.

Schema 4 ergänzt `adaptivePlans` und das verborgene Adaptive-Widget. Separate
Schema-3-DTOs erhalten Paths und manuelle Beiträge. Fehlende aktuelle Pflichtfelder
werden weiterhin abgewiesen. 33 Core-Tests einschließlich aller Migrationen bestanden.

Schema 5 ergänzt `chapters` mit Foto-UUIDs; die JPEG-Dateien liegen separat.
Schema 6 ergänzt `experiments`/`experimentCheckIns`. Schema 7 ergänzt `circles`,
`circleChallenges`/`circleContributions`. Jede vorherige Version hat ein explizites
DTO. Neue Arrays bleiben leer: weder Messungen noch Demo-Mitglieder oder Freigaben
werden bei der Migration erfunden. Lesen verändert keine Datei. Bei einem
Downgrade muss der ältere Writer die neuere Schemaversion ablehnen.

Schema 8 ergänzt die optionale Routine-Quelle eines Path-Meilensteins. Bestehende
Meilensteine behalten ihre manuelle/Habit-Quelle. Keine alten Sessions werden
verändert, keine Minuten umgedeutet. Ein Schema-7-Roundtrip prüft alle alten Felder.

## Schema 9 (8. November 2026)

Schema 8 unterschied sich von Schema 7 nur durch ein optionales Meilensteinfeld;
beide werden mit demselben expliziten DTO gelesen. Beim Übergang auf Schema 9
bleiben Reihenfolge, Sichtbarkeit und (neu optionale) Größe aller vorhandenen
Widgets erhalten. Fehlende Dashboard-Widgets werden an festen Positionen ergänzt:
Übersicht vor dem Tagesfortschritt, Serie und Woche direkt danach, Kalender am Ende
(sichtbar), Kreise/Experimente/Chapters am Ende (ausgeblendet). `dayPlans` startet
leer: es wird keine Vergangenheit erfunden. Ein Schema-9-Dokument ohne `dayPlans`
gilt als beschädigt. Ältere Apps lehnen Schema 9 bewusst mit „unsupported schema“
ab; nach dem ersten Schreiben keine ältere Beta über denselben Datencontainer
installieren.

## Schema 10 (8. November 2026)

Neu: `reminders` (Pflichtfeld ab Schema 10), optionale `LifeMode.scheduledWeekdays`
und `LifeMode.priorityHabitIDs`, optionales `ModeActivation.isAutomatic` und
`modeOverrideDay`. Schema-9-Dokumente werden über ein eigenes DTO (Schema 7/8 +
`dayPlans`) gelesen; Erinnerungen starten leer, Modes ohne Wochenplan bleiben manuell.
Ein Schema-10-Dokument ohne `reminders` gilt als beschädigt. Backup-Dateien nutzen
dieselbe Dekodierung (`JSONStateRepository.decodeDocument`) und akzeptieren damit
alle Schemata 1–10; neuere Versionen werden abgelehnt. Vor einer Wiederherstellung
wird der aktuelle Stand als `Backups/before-restore-<Zeit>.json` im App-Container
abgelegt; die Wiederherstellung selbst ist eine einzige atomare Transaktion.
