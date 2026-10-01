# Digital Silt Passport

Proposed pilot architecture for the Digital Silt Passport.

## Access model
- QR/Public: read-only passport.
- Approved Staff: Supabase Auth login; add/edit field records.
- Master Admin: approve/revoke staff, manage reaches, review verification and audit history.
- Audit trail: actor, action, timestamp, old data and new data.

## Stack
- Frontend: GitHub Pages.
- Backend/Auth/Database/Storage: Supabase Free for pilot.
- QR: each reach gets a public read-only URL such as `/passport.html?reach=KM-KITHORE-02400-03100`.

## Important
This repository must never contain passwords, service-role keys, or other secrets. Only the Supabase publishable/anon key may be used in browser code, and only with Row Level Security correctly configured.

## Current status
The public UI is a prototype. `supabase/schema.sql` contains the first database/RLS draft. Before departmental production use, test authorization, audit triggers, file storage, backups, account recovery, and HTTPS.
