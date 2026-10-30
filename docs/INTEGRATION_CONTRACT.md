# Pace-Family Integration – vorläufiger Vertrag
**NICHT FREIGEGEBEN FÜR PRODUKTIVNUTZUNG.** Pace-Social-Code und Repo sind tabu.

Vom Nutzer dokumentierte bestehende Basis: Supabase `auth.users`, `public.profiles`, `public.regions`, `public.daily_activity`, geschützte Freunde-/Gruppen-/Chatstrukturen und serverseitige Funktionen. In `profiles`: `id` (Auth UUID), `public_id` (öffentliche Identität), `username`, `display_name`, `avatar_path`, `municipality_id`, Visibility. Details/Permissions nur nach einem von Claude freigegebenen API-Vertrag übernehmen.

Anonyme Pace-Social-MVP-Logins sind in iOS-Keychain gespeichert; andere Apps haben **nicht** automatisch dieselbe Sitzung. Gemeinsame Authentifizierung und mögliche Keychain Sharing Entitlements müssen separat auf Architektur/Sicherheit geprüft und ausdrücklich freigegeben werden. Keine stillschweigende zweite Identität.

Geplante Adapter-Interfaces: `PaceIdentityService`, `PaceFriendsService`, `PaceGroupsService`, `PaceActivityReadService`. Im ersten Inkrement nur eindeutige `Unavailable`-Adapter (oder bewusst lokale Demos) verwenden; keine Fake-„echten“ Kontakte.

Nach Freigabe: Auth-Flows, zugelassene Profile-Felder, Gruppenmitgliedschaft, Zugriffsregeln, Rate Limits, RLS-Tests, Datenminimierung und Trennung privater Life-Daten. `competitionSteps` in Pace Social niemals durch Pace-Life-Eingaben erhöhen.
