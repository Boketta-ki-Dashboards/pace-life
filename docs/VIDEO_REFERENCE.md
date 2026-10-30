# VERBINDLICHE VIDEOREFERENZEN – PACE SOCIAL → PACE LIFE

## Übergabeweg: ausschließlich Codex-Chat
Die Originalaufnahmen werden **NICHT auf GitHub hochgeladen**, auch nicht als GitHub-Issue-Anhang. Der Nutzer stellt die Videos bzw. daraus extrahierte Frames **direkt als Anhänge in der aktiven Codex-/Astra-Konversation** bereit. Die Dateien sind nicht Bestandteil dieses Repositories. Du darfst weder Pace Social klonen noch dessen Quellcode abrufen.

- `ScreenRecording_10-30-2026 10-00-44_1(1).mp4` – ca. 1:19, überwiegend Dark Mode
- `ScreenRecording_10-30-2026 10-04-55_1.mp4` – ca. 1:39, überwiegend Light Mode

**Wichtig für Codex:** Chat-Anhänge stehen nicht zwangsläufig als Repository-Dateien oder in einer anderen Codex-Session zur Verfügung. Prüfe, ob du die Anhänge im aktiven Chat tatsächlich öffnen und die Bewegung analysieren kannst. Falls Videoeingaben nicht unterstützt werden, kann der Nutzer in demselben Chat Standbilder/Frames und kurze Beschreibungen der Bewegungsabläufe bereitstellen. Behaupte niemals, Videos gesehen oder ein 1:1-Verhalten geprüft zu haben, wenn sie nicht tatsächlich auswertbar sind. Erstelle keine GitHub-Uploadaufforderung.

## Verbindliche Design- und Interaktionsziele
Die folgenden Vorgaben stammen aus der schriftlichen technischen Pace-Übergabe sowie der bereits durchgeführten Auswertung der Referenzaufnahmen. **Die originalen Chat-Videos sind für die visuelle Feinabstimmung verbindlich**, sobald sie verfügbar und technisch lesbar sind.

### Bottom-HUD / Tab-Bar
- Der Bottom-Bereich bleibt beim vertikalen Scrollen fest sichtbar und berücksichtigt die Home-Indicator-Safe-Area.
- Pace Social zeigt `Home`, `Rankings`, `Social`, `Profil`; Pace Life bekommt funktional passende Tabs, übernimmt aber die sichtbare Form- und Interaktionssprache.
- Icon ca. 20pt und Label ca. 13pt; inaktive Elemente dezent; aktives Element als mintfarbene, abgerundete Fläche mit dunklem Icon und Text; Tab-Inhalte mindestens 48pt.
- Hervorhebung und Seiteninhalt sind bei interaktiven horizontalen Gesten synchronisiert; keine plötzlich springenden Zustände oder unlogischen Transitionen.

### Paging, Scrollen und Header
- Links wischen → nächste Seite rechts; rechts wischen → vorherige Seite links. Eine begonnene Bewegung kann abgebrochen werden, ohne unbeabsichtigten Tabwechsel.
- Unterseiten haben native iOS-Zurücknavigation inklusive Edge-Swipe; keine doppelten oder unbegrenzt wachsenden NavigationStacks.
- Horizontales Root-Paging in Editier-, Widget-Drag- und Texteingabemodi begrenzen, damit Gesten nicht kollidieren.
- Beim Scrollen dürfen Header oder Text nicht hinter die Statusleiste wandern. Der Header bleibt visuell stabil, ohne vertikale Sprünge beim horizontalen Seitenwechsel.
- Inhalt bleibt bis zum Ende scrollbar, ohne hinter der Bottom-Bar abgeschnitten zu werden; Tastatur blendet Eingaben nicht aus.

### Sichtbares Design
- Light: sehr heller Hintergrund, weiße Karten, tiefgrüne Headlines, mintgrüne Auswahlzustände.
- Dark: sehr dunkle grünliche/petrolfarbene Flächen und mintfarbene Akzente; die Informationshierarchie bleibt konsistent.
- `docs/DESIGN_SYSTEM.md` liefert die **exakten** semantischen Tokens. Aus Video oder Frames geschätzte Farben dürfen die Tokenwerte nicht ersetzen.
- Referenzthemen: Home-Widgets, Profile, Statistiken/Kalender, Gruppen, Einstellungen, Kartenabstände und Navigation.

## Pflicht: Testen und Nachweisen
1. Im iPhone-Simulator bzw. auf einem echten iPhone Bottom-HUD und Haupttabs öffnen und – soweit Chat-Video verfügbar – visuell vergleichen.
2. Langsamen, schnellen und abgebrochenen horizontalen Swipe testen: aktives Highlight und Inhalt synchron.
3. Vertikal ganz nach unten und oben scrollen: Bottom-HUD sichtbar, Header und Safe Areas korrekt, kein abgeschnittener Inhalt.
4. Unterseiten öffnen, scrollen, Edge-Swipe zurück: kein Navigationsstack-Duplikat.
5. Widget-Drag und Textbearbeitung mit offener Tastatur auf Gestenkonflikte prüfen.
6. Dark/Light, Dynamic Type und DE/EN/RU prüfen.
7. Wenn die Videoauswertung mangels Chat-Unterstützung nicht möglich ist: im Abschlussbericht ausdrücklich **„visueller Videoabgleich ausstehend“** notieren, kein fiktives 1:1-Testergebnis.

## Datenschutz und Scope
Videoaufnahmen dürfen ausschließlich zur App-Analyse verwendet werden, nicht als Produktassets. Keine Nutzerprofile, Chattexte oder personenbezogenen Details in Code, Mock-Daten, GitHub oder Screenshots veröffentlichen. **Pace Social ist ausschließlich Claude vorbehalten.**
