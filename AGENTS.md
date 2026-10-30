# Pace Life – verbindliche Codex-Regeln
- **Scope:** Ausschließlich `Boketta-ki-Dashboards/pace-life`. **Niemals** Pace-Social-Repository lesen, klonen oder ändern. Ausschließlich Claude ist dafür zuständig.
- Keine Änderungen an produktiven Supabase-Daten, Auth, RLS, Migrationen oder anderen Repositories ohne ausdrückliche Freigabe.
- Native iOS-App (SwiftUI, Swift 6 soweit möglich, iOS 17+), lokale Speicherung im ersten Inkrement, modular, testbar, kein Webview-Ersatz.
- **Alle sieben Pflichtmodule:** Life Modes, Life Paths, Pace Adaptive, Life Chapters, Life Experiments, Pace Circles, Pace Connect. Alle in Architektur/Roadmap führen und schrittweise real implementieren. Keine Attrappen als fertig deklarieren.
- Ausdrückliche Freigabe für gemeinsame Pace-Social-Profile/Freunde/Gruppen erst nach separatem, von Claude bereitgestelltem Schnittstellenvertrag.
- Private persönliche Daten standardmäßig nicht veröffentlichen. Gruppen-Freigaben nur explizit, widerruflich und später serverseitig abgesichert.
- `auth.users.id` ist nicht `profiles.public_id`. Kein zweites anonymes Konto stillschweigend als dasselbe ausgeben.
- Design-Tokens aus `docs/DESIGN_SYSTEM.md`; SF Pro/Dynamic Type, 4-pt-Raster, 20-pt-Kartenradius, Light/Dark/Auto, DE/EN/RU. Keine zufälligen Markengrüns/Neonoptik.
- SwiftUI Views ohne Datenbankzugriffe; Domain-Modelle, ViewModels/Use Cases, Service-Protokolle, Adapter und Dependency Injection trennen. Swift Concurrency/`@Observable`.
- Safe Areas, Tastatur, Swipe-Richtung, vertikale Scrolls, NavigationStack-Duplikate und Gestenkonflikte testen.
- Keine Secrets, Service-Role-Keys, echten Nutzerdaten oder Chat-Screenshots in öffentlichen Git-Repositories.
- Bestehende Pace-Life-Funktionen vor Änderung prüfen. Jede Komponente muss wirklich funktionieren; Ergebnisse und nicht ausgeführte Tests ehrlich dokumentieren.
- **Hinweis:** Das Repository ist derzeit öffentlich. Vom Nutzer gelieferte unverpixelte Screenshots und Videos dürfen nicht ohne zusätzliche Datenschutzprüfung hochgeladen werden.


## Verbindliche Originalvideo-Referenzen
Die beiden originalen Pace-Social-Videos werden **ausschließlich im aktiven Codex-Chat als Anhänge bereitgestellt** und **nicht nach GitHub hochgeladen**. Lies `docs/VIDEO_REFERENCE.md`. Nutze die Videos für Bottom-HUD, Scrollen, Paging, Animationen und Header, wenn du sie tatsächlich auswerten kannst. Bei fehlender Video-Unterstützung Standbilder und Chat-Beschreibungen verwenden; eine offene visuelle Prüfung transparent dokumentieren. Niemals die Originalvideos in GitHub oder ein anderes Repository kopieren.
