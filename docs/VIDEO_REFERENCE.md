# VERBINDLICHE VIDEOREFERENZEN – PACE SOCIAL ZU PACE LIFE

**Status:** Originalvideos sind **noch nicht als Anhänge hochgeladen**. GitHub-Issue [#1](https://github.com/Boketta-ki-Dashboards/pace-life/issues/1) enthält die Upload-Anleitung und soll beide Videos verlinken. Niemals behaupten, sie bereits gesehen zu haben, ohne sie tatsächlich zu öffnen.

## Originalaufnahmen
- `ScreenRecording_10-30-2026 10-00-44_1(1).mp4` (ca. 79 Sekunden, Dark Mode)
- `ScreenRecording_10-30-2026 10-04-55_1.mp4` (ca. 99 Sekunden, Light Mode)

### Visuell dokumentierte Merkmale aus extrahierten Kontaktbögen
- Light: Fast weißer Hintergrund, weiße Karten, tiefgrüne Headlines, Mint-Füllungen/Selektionsindikatoren.
- Dark: Dunkelgrüne / dunkelpetrolfarbene Fläche und Karten, leuchtende Mintakzente, gleiche Hierarchie und Navigation.
- **Bottom-HUD/Tab-Bar:** Fester Bottom-Bereich mit `Home`, `Rankings`, `Social`, `Profil` (Pace Social). Jedes Element Symbol+Label; aktiver Tab hat vollflächige mintfarbene abgerundete Pillenfläche, dunkles Icon und Text. Inaktive Elemente bleiben zurückhaltend. Pace Life darf eigene fachlich passende Tabs besitzen, nicht aber die visuelle Form- und Bewegungslogik grundlos ändern.
- Vertikales Scrollen: langer Karteninhalt scrollt innerhalb der Root-Seite; unten bleibt die Tab-Bar erhalten. Card-Abstände, Header-Safe-Area und Scroll-Enden müssen stabil sein.
- Die Aufnahmen zeigen Profile, Ranking-Listen, Home-Widgets, Statistik/Kalender, Gruppen, Einstellungen und Bottom-Bar im Kontext. Referenzwerte aus `docs/DESIGN_SYSTEM.md` haben Vorrang vor geschätzten Bildfarben.
- Eingabekontexte dürfen nicht durch Root-Tabswipes gestört werden. Unterseiten haben native Zurücknavigation einschließlich Edge-Geste.
- Horizontales Root-Paging: Inhalt und Tab-Hervorhebung folgen einer Geste synchron; abbrechbare Bewegung; links zum nächsten, rechts zum vorherigen Tab. Keine Sprünge bei Root-Header/HUD.

## Abnahmetests für Codex
1. Zeige in iPhone-Simulator/auf iPhone die Bottom-Navigation und halte diese mit Video und ggf. Frames neben die Originale.
2. Probiere schnelle und langsame horizontale Gesten sowie abbrechbare Swipes; Highlight und Inhalt müssen konsistent bleiben.
3. Scrolle die Hauptseite komplett herunter und wieder hoch: keine Statusleistenüberschneidung, untere Leiste bleibt sichtbar, Ende nicht abgeschnitten.
4. Öffne Unterseite, scroll, Edge-Swipe zurück; keine mehrfach gestapelten NavigationStacks.
5. Teste Drag-and-Drop von Home-Widgets, Textbearbeitung bei sichtbarer Tastatur sowie Dark/Light.
6. Prüfe DE/EN/RU, lange Labels, Dynamic Type, Safe Areas.

**Strikte Regel:** Niemals den Pace-Social-Code oder das Pace-Social-Repository lesen/klonen. Nur vom Nutzer freigegebene Videodateien, Beschreibungen und Design-Tokens aus diesem Repository nutzen.

**Hinweis für öffentliche Repositorys:** In den Originalvideos können personenbezogene Angaben sichtbar sein. Erstes sicheres Vorgehen ist, Repo privat zu machen, bevor die Originale als Issue-Anhänge geteilt werden.
