# Steffi
Meine kleine Überraschung ❤️

## Gutscheinheft und Stimmungs-Check-in

Die privaten Seiten `gutscheinheft.html` und `stimmungs-checkin.html` nutzen die bestehende Supabase-Anmeldung und die `gallery_members`-Freigabeliste.

Bevor die beiden Bereiche online verwendet werden:

1. `supabase-couple-features.sql` einmal im Supabase SQL-Editor ausführen.
2. In der Supabase-Tabelle `couple_member_roles` für jedes freigeschaltete Konto eine Zeile anlegen. Yannik-Konten erhalten `person_key = yannik`, Steffi-Konten `person_key = steffi`. Falls Steffi mehrere freigeschaltete Adressen nutzt, ordne alle `steffi` zu.

Die Adressen stehen absichtlich nicht in diesem öffentlichen Repository. Die Rollen-Tabelle ist für die Website nur lesbar; ihre Zuordnungen werden im Supabase-Dashboard gepflegt. Die Gutscheine und Check-ins sind durch Row Level Security auf freigeschaltete Konten beschränkt.
