# Schema-2-Migrationsentwurf und Dateninvarianten

Status: vorbereitet, noch nicht aktiviert. Voraussetzung für größere Module ist ein nachweislich erfolgreicher iOS-Simulator-Build. Die eingefrorene Datei `Packages/PaceLifeCore/Tests/PaceLifeCoreTests/Fixtures/schema-one.json` wurde mit dem originalen Schema-1-Serializer aus `c2299e5` erstellt. Ihre Originalfelder werden vor Änderungen an Domain und Repository geprüft.

## Übergang

Schema 1 explizit als altes DTO lesen und validieren, anschließend deterministisch auf Schema 2 abbilden. Neue Felder dürfen für Schema 1 kontrollierte Defaults bekommen, während Schema 2 vollständig und streng decodiert werden muss. Beschädigte oder unbekannte neuere Versionen bleiben unverändert. Kein Fehlerpfad darf eine leere Datenbank über eine vorhandene schreiben. Der erste erfolgreiche Schreibvorgang ersetzt den vollständigen validierten Snapshot atomar; fehlgeschlagene Änderungen übernehmen keinen neuen UI-State.

Alle bisherigen UUIDs, Habits, Ziele, Erfüllungs-Snapshots, Mode-Aktivierungen, Widgets und Einstellungen werden exakt übernommen. Neue Widgets werden hinten und zunächst ausgeblendet ergänzt. Bilder liegen in separaten lokalen Dateien mit referenzgezählter Verwendung; nur Medienmetadaten und stabile IDs gehören ins JSON.

## Historische Pläne

Schema 1 speicherte keine Wochentagsrevisionen. Frühere Planänderungen sind daher nicht rekonstruierbar und dürfen durch Migration nicht erfunden werden. Die vorhandenen Erfüllungen bleiben Fakten. Für neue Tage sind versionierte Habit-Pläne und Tages-Snapshots vorgesehen; Planänderungen gelten erst ab ihrem dokumentierten Wirksamkeitsdatum. Die Migration markiert den übernommenen Wochenplan ausdrücklich als Legacy-Baseline. Historische Auswertungen müssen bekannte Fakten von nicht mehr rekonstruierbaren Planungsdaten unterscheiden.

## Beziehungen und Beiträge

- Routine-Sessions speichern Reihenfolge, Schritttitel und Dauer als Tages-Snapshot. Spätere Bearbeitung der Vorlage verändert keine laufende/abgeschlossene Sitzung.
- Path-Meilensteine verwenden konkrete Beitragsregeln mit Einheit/Umrechnung. Beiträge werden anhand stabiler Quell-IDs upserted bzw. deterministisch berechnet, niemals bei jedem UI-Refresh inkrementiert. Ein korrigierter Habit-Wert korrigiert seinen Beitrag genau einmal.
- Adaptive speichert Originalziel, vorgeschlagenes/akzeptiertes Tagesziel und tatsächlichen Wert getrennt. Eine angenommene Kürzung verändert weder Habit-Vorlage noch langfristiges Path-Ziel. Ablehnung und Rückgängig bleiben eigene Tagesentscheidungen.
- Chapters referenzieren auch archivierte Paths. Medienlöschung muss alle noch bestehenden Referenzen berücksichtigen.
- Experiment-Check-ins verwenden eindeutige Experiment/Tag/Messgröße-Schlüssel; fehlende Daten bleiben fehlend.
- Circles übernehmen ausschließlich explizite Freigaben. Eigene und simulierte Demo-Beiträge haben getrennte Herkunft; Widerruf entfernt die Freigabe, niemals den privaten Quelldatensatz.
- Connect bleibt ohne externen Vertrag unverbunden; Auth- und öffentliche Profil-IDs sind getrennte Typen.

## Migrationsabnahme

Ein Test muss vor/nach Migration und nach erneutem Laden sämtliche bisherigen Felder vergleichen. Weitere Tests: unbekannte neuere Version, beschädigtes JSON, fehlende Pflichtfelder in Schema 2, referenzielle Inkonsistenz, doppelte IDs, fehlgeschlagener atomarer Schreibvorgang und wiederholtes Laden ohne doppelte Migration. Erst danach darf Schema 2 produktiv aus der App geschrieben werden.
