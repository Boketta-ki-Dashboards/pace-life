# Echte Simulatoraufnahmen

Die UI-Tests erzeugen echte `XCTAttachment(screenshot: app.screenshot())`-Aufnahmen
in isolierten Test-App-Containern. Keine Mockups, keine originalen Nutzerfotos und
keine Referenzvideos. `Export actual simulator screenshots` exportiert die PNGs
und das Xcode-Manifest in das jeweilige `ios-evidence-*`-Artefakt.

Nachgewiesener Export für `9d8a140` auf Apple Silicon:
[CI 41805696013](https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41805696013),
[Artefakt ios-evidence-macos-15](https://github.com/Boketta-ki-Dashboards/pace-life/actions/runs/41805696013/artifacts/13309863817).
Enthält Home/Entwicklung/Kreise/Profil jeweils Light und Dark sowie einen
Chapter-Detail-Screenshot nach echter Eingabe und Neustart.

Die erweiterte Testsuite erfasst zusätzlich Life Modes, Life Paths, Pace Adaptive,
Life Chapters und Life Experiments in beiden Darstellungen sowie Experiment- und
Circle-Details nach gespeicherten Eingaben. Ob diese neueren Aufnahmen vorliegen,
ist anhand des commitbezogenen CI-Laufs zu prüfen.

**Noch keine PNGs hier eingecheckt und noch keine visuelle Abnahme:** Der direkte
Artefakt-Download aus dieser Cloud war durch den Proxy gesperrt (HTTP 403).
Eine automatische CI-Commit-Lösung wurde wegen zusätzlicher permanenter
Schreibrechte von der automatischen Freigabeprüfung abgelehnt. Die CI behält reine
Leserechte. Die Artefakte lassen sich auf dem Mac über den obigen Lauf herunterladen;
ausgewählte PNGs können danach hier mit ihrer Commit-/Geräteherkunft eingecheckt
werden. Ein erfolgreicher Screenshot-Test ist keine visuelle Designabnahme.

Originalvideos/Wordmark fehlen weiterhin. Visueller 1:1-Videoabgleich ausstehend.
