# Study Group.tn — new responsive starter

Files: `index.html`, `hero.png`, `config.js`, `database.sql`, `visual-reference.png`.

## Start
1. Create a **new** Supabase project (do not run the schema on your existing project).
2. Run `database.sql` in its SQL Editor. Review policies before admitting real students.
3. Edit `config.js`: use only the base Supabase URL and public anon/publishable key; never a service-role key.
4. In Supabase Auth configure email confirmation, Google OAuth provider, Site URL, and allowed redirect URL for the deployed website.
5. Upload `index.html`, `hero.png`, and `config.js` to GitHub Pages. Keep `database.sql` private if you prefer; it contains no secrets.
6. Test with **two separate student accounts** (different years, sections and options) to verify isolation, upload and download.

## Implemented
- French-first bilingual public landing page; centered first-visit signup modal.
- Collapsed hamburger menu, independent account and files pages.
- Signup form with collège/lycée year, conditional section/optional language, email and Google login.
- Private scoped resources via RLS + private Storage bucket, subject/category browser, upload and signed download.

## Not production ready
- Subject catalogs are illustrative, **not an official validated Tunisian curriculum**. Server-side validation of subject/year/section/optional combination is still needed.
- No admin dashboard, content moderation, virus scanning, abuse reporting, quota management, or annual promotion flow yet.
- Email verification and OAuth redirects must be configured in Supabase; test the flow before launch.
- Profiles cannot be changed by students after submission; use a privileged admin workflow for corrections.
- If signup email confirmation is enabled, the pending profile is saved locally in the browser until verification; using a different browser may require re-entering profile data.
- Free-tier storage, database and bandwidth limits apply. A custom .tn domain is generally paid.
