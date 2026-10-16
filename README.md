# UDITH FREE LIKES

English-only responsive Free Fire likes site for GitHub + Netlify.

## Provider security note
The supplied URL used HTTP. The backend uses `https://freelikes.chamaa.dev/freelike` so the API key is not sent in plain HTTP. Verify that the provider's HTTPS endpoint is supported and has a valid certificate before launch. If HTTPS is unavailable, ask the provider for secure access; do not send a real key over HTTP.

The provider's response format was not supplied. The backend only reports success when the response explicitly includes JSON `success: true` or `status: "success"`; HTTP 200 alone is not treated as proof that likes were sent. Inspect the real provider response and update the parser only if its documented format differs.

## Setup
1. Create a Supabase project at https://supabase.com/.
2. Run the complete `supabase.sql` in Supabase SQL Editor.
3. Copy the Supabase project URL and private `service_role` key.
4. Upload all files to a GitHub repository; keep folder structure. Never commit secrets.
5. In Netlify choose **Add new site → Import an existing project**, connect GitHub and select this repo. Leave build command blank. `netlify.toml` configures publish and functions folders.
6. In Netlify site environment variables add `LIKES_API_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, and `CLIENT_ID_SECRET` (a long random private secret). Redeploy.
7. Open the deployed HTTPS site on Android, submit a numeric UID, and inspect the displayed API response, Netlify function logs, and Supabase `like_requests` table.

## Rate limit notes
Daily reset is based on `Asia/Colombo`. A maximum of 15 confirmed successes are counted per day. One attempt per IP hash per day is allowed. Shared mobile carrier/public Wi-Fi IPs may affect multiple people, and VPN/network changes can bypass IP identification. This is not proof of one unique person; stronger identity protection requires verified sign-in and limiting by authenticated user ID. Failed attempts do not consume successful slots but are still blocked for that IP/day to limit abuse.

## Troubleshooting
- Availability unavailable: verify Supabase variables, SQL setup and Netlify logs.
- Daily protection not ready: run `supabase.sql` and verify all variables.
- Provider connection failed: check provider HTTPS support, domain and API key.
- HTTP 200 but UI says failure: inspect the actual response; the provider may use a different success field.
- Function not found: confirm `netlify/functions/` and `netlify.toml` are uploaded.

This project has not been tested with your provider credentials. Verify the HTTPS endpoint and actual response format before advertising the service as live.
