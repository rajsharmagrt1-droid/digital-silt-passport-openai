# Digital Silt Passport

Proposed pilot system for a QR-based, read-only public Reach Passport with controlled staff editing and Master Admin oversight.

## Current application

- `passport.html?reach=<reach UUID>` — public QR/read-only view.
- `login.html` — Supabase Auth login.
- `staff.html` — approved staff field-record entry and Before/During/After photo upload.
- `admin.html` — Master Admin: staff approval/revocation, Reach creation, audit log and automatic QR generation.
- `supabase/schema.sql` — base database schema.
- `supabase/hardening.sql` — RLS hardening, admin RPCs, audit triggers and photo storage.
- `.github/workflows/pages.yml` — GitHub Pages deployment.

## Architecture

**Public QR → Read only**  
**Approved Staff → Login → Add field record + evidence**  
**Master Admin → Staff approval + Reach management + QR + audit review**

## One-time Supabase setup

1. Create a Supabase project on the Free plan.
2. Open **SQL Editor**.
3. Run `supabase/schema.sql`.
4. Run `supabase/hardening.sql`.
5. In **Authentication → Users**, create the first administrator account.
6. Copy that user's UUID.
7. In SQL Editor run:
   ```sql
   insert into public.staff_profiles(user_id,full_name,designation,division,role,approved)
   values('YOUR-USER-UUID','Master Admin','Administrator','Meerut','admin',true);
   ```
8. Create additional staff users in Authentication → Users, then add their `staff_profiles` rows with `role='staff'` and `approved=false`. Master Admin can approve/revoke them from the dashboard.
9. Open `supabase-config.js` and replace only:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY` / publishable key
10. Never put the Supabase `service_role` key in GitHub or browser code.

## GitHub Pages

In GitHub open **Settings → Pages** and select **GitHub Actions** as the source. Pushes to `main` will deploy the site using the included workflow.

Expected public base:
`https://rajsharmagrt1-droid.github.io/digital-silt-passport-openai/`

Example QR:
`https://rajsharmagrt1-droid.github.io/digital-silt-passport-openai/passport.html?reach=<UUID>`

## Security model

- Public users can read passport data only.
- Only authenticated approved staff can insert/update field records.
- Only authenticated approved staff can upload field evidence.
- Admin operations use server-side Supabase RLS + security-definer RPCs.
- Database changes are recorded in `audit_log` with actor, action, old data, new data and timestamp.

## Important pilot note

This is a proposed technical pilot, not an existing official Uttar Pradesh Government system. Replace the sample Kithore Minor record with verified departmental field data before public use. Test RLS, authentication, audit, backups, account recovery and photo access before departmental production deployment.
