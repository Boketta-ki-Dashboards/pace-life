# Pace Life – Produktspezifikation
**Positionierung:** Persönliches Life Operating System; verbindet tägliche Entscheidungen mit langfristigen Lebenszielen und Rückblicken. Kein bloßer Checklist-Habit-Tracker.

## Pflichtfunktionen – alle sieben
1. **Life Modes:** Arbeitstag, Wochenende, Urlaub, Prüfung, Erholung und frei definierte Modi. Modi tragen eigene Gewohnheiten/Routinen/Tagesvorlagen; aktivieren, editieren, planen, manuell übersteuern; historische Erfüllungen unverändert.
2. **Life Paths:** Mehrere langfristige Ziele mit Bereichen, Etappen, Milestones, Zielterminen, Fortschritt und mit Habits verknüpften Beiträgen. Realer Fortschritt statt frei erfundener Prozente.
3. **Pace Adaptive:** Nutzer erfasst verfügbare Zeit/Energie/Belastung; System schlägt reduzierte, realistische Tagespläne vor; Zustimmung und jederzeitige Änderung. Teilziele dürfen nicht als voller Abschluss zählen; Regeln transparent und zunächst lokal ohne KI-API.
4. **Life Chapters:** Private Lebensabschnitte, Zeiträume, Meilensteine, Bilder, Freitext, persönliche Erinnerungen, Rückblick-Timeline. Export und Löschung berücksichtigen.
5. **Life Experiments:** 7/14/30 Tage oder frei definierte Experimente; Baseline, tägliche Eingaben, Zeitverläufe, Vergleiche, ehrliche Auswertung ohne Kausalitäts-/Gesundheitsversprechen.
6. **Pace Circles:** Private und teilbare Gruppenziele, gegenseitige Motivation, 30-Tage-Challenges, eigene & später vorhandene Social-Gruppen verwenden. Einladungen, Mitgliederrollen, Freigabe pro Messwert, Widerruf und serverseitige Zugriffskontrolle. Keine unnötigen Chats/Schritt-Rankings duplizieren.
7. **Pace Connect:** Gemeinsame Pace-Identität, später Integrationen zu Pace Social (Schritte), Pace Fitness (Training), Pace Learn (Lernfortschritt). Nur geprüfte, freigegebene Schnittstellen; ohne andere Apps eigenständig.

## Querschnittsfunktionen
- Individueller modularer Homescreen mit Widgets, Reihenfolge und Sichtbarkeit.
- Habits: Name, Frequenz/Wochentage, Zieltyp (ja/nein, Zähler, Dauer), Planung, Erfüllung, Verlauf, Streaks mit klarer Zeitzonen- und Tagesgrenzenlogik.
- Routinen, Tagesprioritäten, Wochen-/Monatskalender, Fortschrittsringe, Erinnerungen mit Nutzerzustimmung.
- Personalisierbare Darstellung; DE/EN/RU; Light/Dark/Auto; iPhone-optimiert, Dynamic Type und VoiceOver.
- Daten standardmäßig lokal und privat; offline nutzbar; spätere sichere Synchronisierung.

## Erstes funktionsfähiges Inkrement
App startet in Xcode; Tabs `Heute / Entwicklung / Kreise / Profil`; Designsystem; echte lokale CRUD für Life Modes und Habits; lokale tägliche Erfüllung; Home-Widgets ein-/ausblenden und sortieren (gespeichert); Settings. Für unimplementierte Bereiche ehrliche „noch nicht verfügbar“-Zustände; keine Fake-Daten als echt.

## Akzeptanzbeispiele
- Ein Habit bleibt nach App-Neustart angelegt und dessen heutige Erfüllung bleibt erhalten.
- Ein Mode-Wechsel setzt frühere Habit-Erfüllungen nicht zurück.
- Widget-Reihenfolge bleibt nach Neustart gleich.
- Zeit- oder Energie-Reduktion im Adaptive-System verändert nicht rückwirkend den ursprünglichen Zielwert.
- Private Chapters können nicht von Gruppenteilnehmern gelesen werden ohne explizite Freigabe.
- Ein Gruppenziel zeigt ausschließlich ausdrücklich geteilten Fortschritt, nicht automatisch alle Lebensdaten.
- Vor einer echten Social-Anbindung niemals Fake-Freunde oder Fake-Sessions als produktiv ausgeben.
