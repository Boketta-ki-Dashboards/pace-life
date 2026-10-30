# Test- und Release-Anforderungen
- Unit-Tests: Habit-Frequenzen, Tagesgrenzen, Sommer-/Winterzeit, Completion-Deduplikation, Streaks, Mode-Aktivierung, Historienunveränderlichkeit, Persistenz und Widget-Reihenfolge.
- UI-/Navigations-Tests: Swipe-Richtung, Cancel-Swipe, Back-Geste, verschachtelte Navigation vermeiden, Textfelder mit Tastatur, Safe Areas, Scroll-Enden, Drag/Scroll-Konflikte.
- Visuelle Tests in Dark & Light, Dynamic Type, DE/EN/RU, lange Texte, iPhone-Größen, VoiceOver.
- Kein verschachteltes Realtime-Abo, unkontrollierte Task-Lebensdauer oder springende Charts.
- Datenschutztests vor Social-Integration: Default Private, explizites Opt-in, Widerruf, Zugriff unberechtigter Mitglieder serverseitig blockiert.
- Xcode/Simulator-Build wirklich ausführen, wenn macOS/Xcode verfügbar. In Cloud ohne Xcode niemals Erfolg behaupten. Mac-Build-Anleitung dokumentieren.
- Dokumentation der Bundle-ID, Team-Signing, Assetfreigaben, Datenschutzerklärung, Berechtigungen, App Store Review.
- Kein Release, bevor ein echter iPhone-Test möglich war.
