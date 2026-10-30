# Pace Life – verbindliches Designsystem
Referenz: Vom Nutzer bereitgestelltes Pace-Social-Design, GitHub-Stand `bc02cf3`, Oktober 2026.

## SwiftUI Semantic Colors
| Token | Light | Dark |
|---|---|---|
| brand | #072D20 | #8EF5D8 |
| accent | #16784C | #86F3D3 |
| accentStrong | #075237 | #88F7D8 |
| onAccent | #FFFFFF | #06211A |
| accentSoft | #DDF8EC | #0F2A24 |
| actionFill | #07774B | #88F7D8 |
| selectionFill | #D3F9EA | #8EF8DC |
| onSelection | #063D29 | #06211A |
| goalReachedFill | #3BBF79 | #7FEFC5 |
| onGoalReached | #07301F | #06211A |
| background | #F8F9F7 | #0B1315 |
| surface | #FFFFFF | #111A1D |
| surfaceSecondary | #FFFFFF | #152024 |
| border | #E7EAE6 | #232E32 |
| fieldBackground | #F1F2F5 | #172125 |
| track | #E1E4E2 | #343C3E |
| textPrimary | #0B120F | #F3F7F5 |
| textSecondary | #5F6684 | #A3AEB8 |
| chartLow | #A7DDBF | #4E9F86 |
| streak | #E8590C | #FF922B |
| success | #1E8A50 | #6EE7A0 |
| warning | #B86E00 | #FFB940 |
| danger | #C62828 | #FF6B66 |

Farben zentral als dynamische Assets/semantische SwiftUI-Tokens bereitstellen. Keine erfundenen Markenfarben oder auffällige Gradients.

## Layout
- 4-pt-Raster: xxs 4, xs 8, s 12, m 16, l 24, xl 32, xxl 48.
- PaceCard: surface, 16pt Padding, 20pt Radius, 1pt Border; Light-Schatten schwarz 4%, radius 10, y 3; Dark fast kein Schatten.
- PaceTile: 12pt horizontal, 8pt vertikal, 14pt Radius, surfaceSecondary, dezenter Rand; Box-in-Box vermeiden.
- Primärer/Sekundärer Button: Höhe mindestens 52pt, Radius 14pt; Primär accentStrong/onAccent, Sekundär accentSoft + accentText; kompakt Radius 12pt.
- SF Pro/Systemschrift + Dynamic Type. Seitentitel `.largeTitle.bold()`, Kartenüberschriften `.title3.semibold()`, weitere Stile `.headline`, `.body`, `.callout`, `.footnote`, `.caption2`. Zahlen `.heavy`.
- PaceProgressRing: ruhiger Track, accent, runde Kappen, 12pt Linienbreite, zentrierter Wert, sanfte Animation.
- PaceAvatar: rund, Initialen falls kein Bild, stabile Pastellfarbe aus User-ID, feiner Rand.

## Navigation/Headers
- PaceRootHeader: PaceWordmark links (28pt Standard, 33pt Haupttab), rechts optionale Aktionen; erste Headerzeile mindestens 44pt, darunter großer Seitentitel mindestens 44pt; 8pt Top-Abstand. Beim Page-Swipe kein vertikaler Titelsprung.
- PaceSubpageHeader: zurück mit Chevron/Seitenname; PaceWordmark/Aktionen; großer Titel; optional Untertitel. Native Edge-Swipe-Back-Geste.
- PaceTabBar: Symbol ca. 20pt, Text ca. 13pt, Mindest-Touch-Höhe 48pt, aktiver mintfarbener Hintergrund mit dunklem Text, Badges.
- Falls Root-Paging implementiert: Swipe links zeigt nächsten Tab rechts; Swipe rechts vorherigen; interaktives Abbrechen; kein Root-Swipe in Editier- oder Texteingabe-Modus.
- Für Pace Life: Tabs `Heute`, `Entwicklung`, `Kreise`, `Profil`; Zahl der Tabs darf sich fachlich ändern.
- Sichere Status-/Home-Indicator-Areas, tastaturfreundliche Inputs, durchgängige Scrollbarkeit.

## Branding und Sprachen
PaceWordmark ist ein **separates originales Markenasset**. Ohne ausdrücklich übergebenes Asset klar als Platzhalter kennzeichnen, nie als echtes Logo vortäuschen. Auto/Hell/Dunkel und DE/EN/RU, sofortige Lokalisierung von Zahlen und Datum, persistente Einstellungen.

## Video-Referenzen
Zwei Originalvideos (Dark und Light) werden **direkt in der aktiven Codex-Chat-Konversation als Anhänge** bereitgestellt, nicht über GitHub. Die komplette Interaktionsreferenz steht in `docs/VIDEO_REFERENCE.md`. Astra soll die Videos für Bottom-HUD/Tab-Bar, Paging-Gesten, Scrollen und Header auswerten, **sofern die Chat-Umgebung das unterstützt**. Falls nicht, soll Astra die im Chat bereitgestellten Frames und Bewegungsbeschreibungen nutzen und den ausstehenden Originalvideo-Abgleich offen dokumentieren.

## Implementierungsstand Phase 1

Alle 23 Light-/Dark-Farbpaare sind unverändert in `PaceLife/DesignSystem/PaceColors.swift` umgesetzt. `PaceCard` (20 pt), `PaceTile` (14 pt), Buttons (mindestens 52 pt), Fortschrittsring (12 pt), Header und Statuskomponente liegen in `PaceComponents.swift`. Systemschrift, Dynamic Type, Reduce Motion und semantische VoiceOver-Texte bilden die Basis. Der Text „Pace Life“ ist ausdrücklich als Logo-Platzhalter beschriftet.

Die vier Tabs erhalten einen mintfarbenen Auswahlzustand. Safe Areas werden über native SwiftUI-Container berücksichtigt. Die Originalvideos vom 30.10.2026 waren als Chat-Anhänge vorhanden, überschritten aber beide das 32-MiB-Übertragungslimit des Executors. Es wurden keine Frames oder Bewegungen daraus angesehen. **Visueller Videoabgleich ausstehend**; keine Behauptung einer exakten visuellen oder gestischen Übereinstimmung. Dafür fehlen weiterhin ein echter iOS-Lauf und das freigegebene Original-Wordmark.
